<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\FaceController;
use PHPUnit\Framework\TestCase;
use support\Request;

class FaceControllerTest extends TestCase
{
    private static function call(string $method, array $inputs = []): array
    {
        $request = new class($inputs) extends Request {
            public $ownerId = 1;

            public function __construct(private array $inputs = [])
            {
            }

            public function input(string $name, mixed $default = null)
            {
                return $this->inputs[$name] ?? $default;
            }
        };
        $response = (new FaceController())->{$method}($request);
        return json_decode($response->rawBody(), true);
    }

    public function test_register_missing_image(): void
    {
        $body = self::call('register');
        $this->assertSame(422, $body['code']);
        $this->assertSame('请上传人脸照片', $body['message']);
    }

    public function test_register_empty_image(): void
    {
        $body = self::call('register', ['face_image' => '']);
        $this->assertSame(422, $body['code']);
        $this->assertSame('请上传人脸照片', $body['message']);
    }
}
