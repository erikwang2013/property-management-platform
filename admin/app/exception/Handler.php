<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\exception;

use Illuminate\Database\RecordsNotFoundException;
use support\exception\Handler as BaseHandler;
use Throwable;
use Webman\Http\Request;
use Webman\Http\Response;

/**
 * 全局异常处理器：仅把「记录不存在」一族统一映射为 404，其余行为原样交回框架默认处理器。
 *
 * 一处映射覆盖全部 findOrFail() 调用点（Vote 9 / Notification 2 / Payment 1，service 端零处）；
 * ModelNotFoundException 继承 RecordsNotFoundException，故按父类判定，
 * 顺带覆盖查询构造器的 firstOrFail()/sole() 同族异常。
 * 响应形状与仓库既有 404 站点（find() + 判空 → fail('xxx不存在', 404)）一致：HTTP 200 + body code。
 */
class Handler extends BaseHandler
{
    public function render(Request $request, Throwable $exception): Response
    {
        if ($exception instanceof RecordsNotFoundException) {
            return json(['code' => 404, 'message' => '资源不存在', 'data' => []]);
        }

        return parent::render($request, $exception);
    }
}
