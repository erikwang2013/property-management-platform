<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

namespace app\common;

use support\Redis;
use Webman\Log;

/**
 * Redis 分布式熔断器：closed → open → half_open → closed
 *
 * - closed: 正常放行，失败计数在窗口内累计
 * - open:   快速失败（不调用下游），等待 timeout 秒后进入 half_open
 * - half_open: 只放行 1 个探测请求（SETNX 抢占），成功转 closed，失败重新 open
 * - Redis 不可用时 fail-open（宁可慢不可挂）
 */
final class CircuitBreaker
{
    private const LUA_CAN_PROCEED = <<<'LUA'
local state_key, probe_key = KEYS[1], KEYS[2]
local state_json = redis.call('GET', state_key)
if state_json then
    local state = cjson.decode(state_json)
    if state.state == 'open' then
        if tonumber(ARGV[1]) - state.opened_at >= tonumber(ARGV[2]) then
            -- 冷却结束，抢占探测权
            if redis.call('SETNX', probe_key, ARGV[3]) == 1 then
                redis.call('EXPIRE', probe_key, ARGV[2])
                return 2 -- half_open 探测放行
            end
            return 0
        end
        return 0
    end
end
return 1
LUA;

    private const LUA_RECORD_FAILURE = <<<'LUA'
local state_key, fail_key, probe_key = KEYS[1], KEYS[2], KEYS[3]
local threshold, window = tonumber(ARGV[1]), tonumber(ARGV[2])
local now = tonumber(ARGV[3])
local fails = redis.call('INCR', fail_key)
if fails == 1 then
    redis.call('EXPIRE', fail_key, window)
end
redis.call('DEL', probe_key)
local state_json = redis.call('GET', state_key)
local state = state_json and cjson.decode(state_json) or { state = 'closed' }
if state.state == 'half_open' or fails >= threshold then
    state.state = 'open'
    state.opened_at = now
    redis.call('SET', state_key, cjson.encode(state))
    return 0
end
return 1
LUA;

    private const LUA_RECORD_SUCCESS = <<<'LUA'
local state_key, fail_key, probe_key = KEYS[1], KEYS[2], KEYS[3]
redis.call('DEL', fail_key)
redis.call('DEL', probe_key)
local state_json = redis.call('GET', state_key)
if state_json then
    local state = cjson.decode(state_json)
    if state.state ~= 'closed' then
        state.state = 'closed'
        state.opened_at = 0
        redis.call('SET', state_key, cjson.encode(state))
    end
end
return 1
LUA;

    private string $name;
    private array $opts;

    public function __construct(string $name, array $opts = [])
    {
        $this->name = $name;
        $this->opts = array_merge([
            'failure_threshold' => 5,   // 窗口内失败多少次触发 open
            'window'            => 60,  // 失败计数窗口（秒）
            'timeout'           => 30,  // open 保持多久后尝试半开探测（秒）
        ], $opts);
    }

    public function canProceed(): bool
    {
        try {
            $res = Redis::eval(
                self::LUA_CAN_PROCEED,
                [$this->key('state'), $this->key('probe'), time(), $this->opts['timeout'], $this->unique()],
                2
            );
            return (int) $res > 0;
        } catch (\Throwable $e) {
            Log::error("circuit_breaker_fail_open: {$this->name} " . $e->getMessage());
            return true; // Redis 挂了放行，由下游超时兜底
        }
    }

    public function recordFailure(): void
    {
        try {
            Redis::eval(
                self::LUA_RECORD_FAILURE,
                [$this->key('state'), $this->key('fail'), $this->key('probe'),
                 $this->opts['failure_threshold'], $this->opts['window'], time()],
                3
            );
        } catch (\Throwable $e) {
            Log::error("circuit_breaker_record_failure_error: {$this->name} " . $e->getMessage());
        }
    }

    public function recordSuccess(): void
    {
        try {
            Redis::eval(
                self::LUA_RECORD_SUCCESS,
                [$this->key('state'), $this->key('fail'), $this->key('probe')],
                3
            );
        } catch (\Throwable $e) {
            Log::error("circuit_breaker_record_success_error: {$this->name} " . $e->getMessage());
        }
    }

    public function reset(): void
    {
        try {
            Redis::del($this->key('state'), $this->key('fail'), $this->key('probe'));
        } catch (\Throwable $e) {
            Log::error("circuit_breaker_reset_error: {$this->name} " . $e->getMessage());
        }
    }

    private function key(string $suffix): string
    {
        return "cb:{$this->name}:{$suffix}";
    }

    private function unique(): string
    {
        return (string) microtime(true) . '.' . mt_rand();
    }
}
