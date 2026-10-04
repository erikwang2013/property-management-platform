<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

/**
 * This file is part of webman.
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the MIT-LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @author    walkor<walkor@workerman.net>
 * @copyright walkor<walkor@workerman.net>
 * @link      http://www.workerman.net/
 * @license   http://www.opensource.org/licenses/mit-license.php MIT License
 */

return [
    // 自定义全局处理器：仅追加「记录不存在 → 404」一处映射（见 app\exception\Handler），
    // 其余异常（含调试态 JSON/traces 渲染）行为与默认 support\exception\Handler 完全一致。
    '' => app\exception\Handler::class,
];