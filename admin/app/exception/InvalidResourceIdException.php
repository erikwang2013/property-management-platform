<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\exception;

use InvalidArgumentException;
use support\Request;
use support\Response;

/**
 * 无效/失效的资源 ID（hashid 解不出：乱串、旧盐串等）。
 *
 * 继承 InvalidArgumentException：既有 catch (InvalidArgumentException) 的控制器语义不变；
 * 未被捕获时由自带 render() 出干净 422 —— webman 异常处理器优先采用异常自带的 render()，
 * 不再走 500 分支（500 响应体会带异常类名与首个栈帧的绝对路径）。
 */
class InvalidResourceIdException extends InvalidArgumentException
{
    public function render(Request $request): Response
    {
        // 与 BaseController::fail('无效的资源 ID', 422) 同形（本仓约定：HTTP 200 + body code）
        return json(['code' => 422, 'message' => '无效的资源 ID', 'data' => []]);
    }
}
