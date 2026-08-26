<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\model\BaseModel;
use PHPUnit\Framework\TestCase;

class BaseModelTest extends TestCase
{
    public function test_incrementing_disabled_for_snowflake_pk(): void
    {
        $model = new BaseModel();
        $this->assertFalse($model->getIncrementing(), '雪花 ID 主键不允许自增');
        $this->assertSame('int', $model->getKeyType());
    }

    public function test_extends_eloquent_model(): void
    {
        $this->assertTrue(is_subclass_of(BaseModel::class, \Illuminate\Database\Eloquent\Model::class));
    }
}
