<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

ini_set('display_errors', 'on');
require_once __DIR__ . '/vendor/autoload.php';

app\process\Http::init();
app\process\Http::run();
