<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\CaptchaController;
use app\admin\controller\FeePaymentController;
use app\admin\controller\FinanceController;
use app\admin\controller\OwnerController;
use app\admin\controller\PaymentController;
use app\admin\controller\ProfileController;
use app\admin\controller\RepairController;
use app\admin\controller\StaffController;
use app\admin\controller\UserController;
use app\common\HashidsService;
use PHPUnit\Framework\TestCase;
use ReflectionMethod;
use support\Request;

/**
 * 管理控制器的参数校验与脱敏辅助方法测试
 * 全部路径发生在 DB 查询之前，无需数据库即可验证失败分支与响应结构
 */
class ControllerValidationTest extends TestCase
{
    private static function makeRequest(array $inputs = []): Request
    {
        return new class($inputs) extends Request {
            public function __construct(private array $inputs = [])
            {
                // 提供合法 HTTP 缓冲，保证 header() 等依赖 buffer 的方法可用
                parent::__construct("POST /admin/x HTTP/1.1\r\nHost: localhost\r\n\r\n");
            }

            public function input(string $name, mixed $default = null)
            {
                return $this->inputs[$name] ?? $default;
            }

            public function all()
            {
                return $this->inputs;
            }
        };
    }

    private static function body(\support\Response $response): array
    {
        return json_decode($response->rawBody(), true);
    }

    // ── UserController ───────────────────────────────────────────

    public function test_user_store_rejects_missing_username(): void
    {
        $resp = (new UserController())->store(self::makeRequest(['password' => 'Abcdef1@', 'real_name' => '张三']));
        $body = self::body($resp);
        $this->assertSame(422, $body['code']);
        $this->assertStringContainsString('username', $body['message']);
    }

    public function test_user_store_rejects_short_username(): void
    {
        $resp = (new UserController())->store(self::makeRequest(['username' => 'ab', 'password' => 'Abcdef1@', 'real_name' => '张三']));
        $this->assertSame(422, self::body($resp)['code']);
    }

    public function test_user_store_rejects_short_password(): void
    {
        $resp = (new UserController())->store(self::makeRequest(['username' => 'zhangsan', 'password' => '123', 'real_name' => '张三']));
        $this->assertSame(422, self::body($resp)['code']);
    }

    public function test_user_store_rejects_invalid_status(): void
    {
        $resp = (new UserController())->store(self::makeRequest([
            'username' => 'zhangsan', 'password' => 'Abcdef1@', 'real_name' => '张三', 'status' => 9,
        ]));
        $this->assertSame(422, self::body($resp)['code']);
    }

    // ── StaffController ──────────────────────────────────────────

    public function test_staff_store_requires_community(): void
    {
        $resp = (new StaffController())->store(self::makeRequest(['name' => '王五']));
        $body = self::body($resp);
        $this->assertSame(422, $body['code']);
        $this->assertStringContainsString('小区', $body['message']);
    }

    public function test_staff_store_requires_name(): void
    {
        $resp = (new StaffController())->store(self::makeRequest(['community_id' => 1]));
        $body = self::body($resp);
        $this->assertSame(422, $body['code']);
        $this->assertStringContainsString('姓名', $body['message']);
    }

    // ── ProfileController ────────────────────────────────────────

    public function test_profile_logout_without_token_returns_401(): void
    {
        $resp = (new ProfileController())->logout(self::makeRequest([]));
        $body = self::body($resp);
        $this->assertSame(401, $body['code']);
        $this->assertStringContainsString('未登录', $body['message']);
    }

    // ── PaymentController ────────────────────────────────────────

    public function test_payment_create_requires_user(): void
    {
        // bill_id 必须为合法 hashid（空串/非法值会抛异常），user_id 缺失触发 422
        $resp = (new PaymentController())->create(self::makeRequest([
            'bill_id' => HashidsService::encode(123),
            'channel' => 'wechat',
            'user_id' => 0,
        ]));
        $body = self::body($resp);
        $this->assertSame(422, $body['code']);
        $this->assertStringContainsString('缺少账单或支付人', $body['message']);
    }

    public function test_payment_create_rejects_unknown_channel(): void
    {
        $resp = (new PaymentController())->create(self::makeRequest([
            'bill_id' => HashidsService::encode(123),
            'channel' => 'bitcoin',
            'user_id' => 1,
        ]));
        $body = self::body($resp);
        $this->assertSame(422, $body['code']);
        $this->assertStringContainsString('不支持的支付渠道', $body['message']);
    }

    // ── FeePaymentController ─────────────────────────────────────

    public function test_offline_pay_requires_bill(): void
    {
        $resp = (new FeePaymentController())->offlinePay(self::makeRequest(['amount' => 100]));
        $body = self::body($resp);
        $this->assertSame(422, $body['code']);
        $this->assertStringContainsString('请选择账单', $body['message']);
    }

    // ── CaptchaController ────────────────────────────────────────

    public function test_captcha_verify_requires_key_and_clicks(): void
    {
        $resp = (new CaptchaController())->verify(self::makeRequest(['key' => 'x']));
        $body = self::body($resp);
        $this->assertSame(422, $body['code']);
        $this->assertStringContainsString('缺少验证参数', $body['message']);
    }

    // ── FinanceController ────────────────────────────────────────

    public function test_finance_is_income_by_path(): void
    {
        $income = new Request("GET /admin/finance-income HTTP/1.1\r\nHost: localhost\r\n\r\n");
        $expense = new Request("GET /admin/finance-expense HTTP/1.1\r\nHost: localhost\r\n\r\n");
        $ref = new ReflectionMethod(FinanceController::class, 'isIncome');
        $ref->setAccessible(true);
        $controller = new FinanceController();
        $this->assertTrue($ref->invoke($controller, $income));
        $this->assertFalse($ref->invoke($controller, $expense));
    }

    // ── OwnerController.maskEmail ────────────────────────────────

    public function test_owner_mask_email(): void
    {
        $this->assertSame('z***@example.com', self::invokeMaskEmail('zhangsan@example.com'));
        $this->assertSame('a***@', self::invokeMaskEmail('abc'));
        $this->assertSame('', self::invokeMaskEmail(''));
    }

    private static function invokeMaskEmail(string $email): string
    {
        $ref = new ReflectionMethod(OwnerController::class, 'maskEmail');
        $ref->setAccessible(true);
        return $ref->invoke(new OwnerController(), $email);
    }

    // ── RepairController.maskPhone ───────────────────────────────

    public function test_repair_mask_phone(): void
    {
        $this->assertSame('138****5678', self::invokeMaskPhone('13812345678'));
        $this->assertSame('123', self::invokeMaskPhone('123')); // 位数不足不脱敏
        $this->assertSame('', self::invokeMaskPhone(''));
    }

    private static function invokeMaskPhone(string $phone): string
    {
        $ref = new ReflectionMethod(RepairController::class, 'maskPhone');
        $ref->setAccessible(true);
        return $ref->invoke(new RepairController(), $phone);
    }
}
