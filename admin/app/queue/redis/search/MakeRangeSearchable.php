<?php

/**
 * Copyright (c) erik <erik@erik.xyz> (https://erik.xyz). All Rights Reserved.
 */

namespace app\queue\redis\search;

use Webman\RedisQueue\Consumer;
use Erikwang2013\WebmanScout\Scout;

class MakeRangeSearchable implements Consumer
{


    // 要消费的队列名
    public $queue = 'scout_make_range';

    // 连接名，对应 plugin/webman/redis-queue/redis.php 里的连接`
    public $connection = 'default';


    /**
     * Handle the job.
     *
     * @return void
     */
    public function consume($data)
    {
        if (empty($data['model']) || !isset($data['start']) || !isset($data['end'])) {
            return;
        }
        $model = new $data['model']();

        $models = $model::makeAllSearchableQuery()
            ->whereBetween($model->getScoutKeyName(), [(int) $data['start'], (int) $data['end']])
            ->get()
            ->filter(function ($m) {
                return $m->shouldBeSearchable();
            });

        if ($models->isEmpty()) {
            return;
        }

        try {
            $models->first()->makeSearchableUsing($models)->first()->searchableUsing()->update($models);
        } catch (\Throwable $e) {
            // ES 不可用时降级：跳过本次索引写入，避免队列消费崩溃；ES 恢复后需重跑全量索引
            \support\Log::info('search_fallback', ['op' => 'make_range_searchable', 'error' => $e->getMessage()]);
        }
    }
}
