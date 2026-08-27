<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\KnowledgeController;
use PHPUnit\Framework\TestCase;
use support\Request;

class KnowledgeControllerTest extends TestCase
{
    private static function call(array $inputs = []): array
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
        $response = (new KnowledgeController())->ask($request);
        return json_decode($response->rawBody(), true);
    }

    public function test_ask_empty_question(): void
    {
        $body = self::call(['question' => '']);
        $this->assertSame(422, $body['code']);
        $this->assertSame('请输入问题', $body['message']);
    }

    public function test_ask_whitespace_question(): void
    {
        $body = self::call(['question' => "  \t  "]);
        $this->assertSame(422, $body['code']);
        $this->assertSame('请输入问题', $body['message']);
    }

    public function test_ask_missing_question(): void
    {
        $body = self::call([]);
        $this->assertSame(422, $body['code']);
        $this->assertSame('请输入问题', $body['message']);
    }
}
