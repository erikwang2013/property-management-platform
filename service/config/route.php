<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

use Webman\Route;

Route::get('/health', function () {
    return json(['code' => 0, 'message' => 'ok', 'data' => ['service' => 'property-service']]);
});

Route::disableDefaultRoute();
