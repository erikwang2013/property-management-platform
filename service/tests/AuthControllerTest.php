<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\AuthController;
use PHPUnit\Framework\TestCase;
use ReflectionMethod;

class AuthControllerTest extends TestCase
{
    private static function normalizeClicks(mixed $clicks): array
    {
        $method = new ReflectionMethod(AuthController::class, 'normalizeClicks');
        $method->setAccessible(true);
        return $method->invoke(new AuthController(), $clicks);
    }

    public function test_normalize_numeric_pairs_unchanged(): void
    {
        $this->assertSame([[1, 2], [3, 4]], self::normalizeClicks([[1, 2], [3, 4]]));
    }

    public function test_normalize_assoc_to_numeric(): void
    {
        $this->assertSame([[10, 20]], self::normalizeClicks([['x' => 10, 'y' => 20]]));
    }

    public function test_normalize_non_array_returns_empty(): void
    {
        $this->assertSame([], self::normalizeClicks('not-an-array'));
        $this->assertSame([], self::normalizeClicks(123));
        $this->assertSame([], self::normalizeClicks(null));
    }

    public function test_normalize_malformed_entry_falls_back_to_zero(): void
    {
        $this->assertSame([[0, 0]], self::normalizeClicks([['a' => 1]]));
    }

    public function test_normalize_mixed_formats(): void
    {
        $this->assertSame(
            [[1, 2], [5, 6], [7, 8]],
            self::normalizeClicks([[1, 2], ['x' => 5, 'y' => 6], [7, 8]])
        );
    }

    public function test_normalize_truncates_float_to_int(): void
    {
        $this->assertSame([[1, 2]], self::normalizeClicks([[1.9, 2.9]]));
    }
}
