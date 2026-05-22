<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use PHPUnit\Framework\TestCase;

class DatabaseSchemaTest extends TestCase
{
    /**
     * RED: 验证所有 batch1 + batch2 表存在
     */
    public function testAllRequiredTablesExist(): void
    {
        $dsn = getenv('DB_DSN') ?: 'mysql:host=127.0.0.1;port=3306;dbname=property_management';
        $user = getenv('DB_USERNAME') ?: 'root';
        $pass = getenv('DB_PASSWORD') ?: '';

        try {
            $pdo = new \PDO($dsn, $user, $pass, [
                \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
            ]);
        } catch (\PDOException $e) {
            $this->markTestSkipped('Database not available: ' . $e->getMessage());
        }

        $expectedTables = [
            // Batch 1
            'erik_community', 'erik_building', 'erik_unit', 'erik_room_type',
            'erik_room', 'erik_owner', 'erik_room_owner', 'erik_tenant',
            'erik_fee_type', 'erik_fee_bill', 'erik_fee_payment',
            'erik_repair_order', 'erik_repair_progress', 'erik_announcement',
            // Batch 2
            'erik_parking_space', 'erik_parking_vehicle', 'erik_parking_record',
            'erik_equipment', 'erik_equipment_maintenance',
            'erik_complaint', 'erik_visitor', 'erik_contract',
            'erik_finance_income', 'erik_finance_expense',
        ];

        $stmt = $pdo->query("SHOW TABLES LIKE 'erik_%'");
        $actualTables = $stmt->fetchAll(\PDO::FETCH_COLUMN);

        foreach ($expectedTables as $table) {
            $this->assertContains(
                $table, $actualTables,
                "表 {$table} 应存在"
            );
        }
    }

    /**
     * RED: 验证所有表主键是 BIGINT UNSIGNED NOT NULL（非自增）
     */
    public function testPrimaryKeysAreBigintNotNullNonAutoIncrement(): void
    {
        $dsn = getenv('DB_DSN') ?: 'mysql:host=127.0.0.1;port=3306;dbname=property_management';
        $user = getenv('DB_USERNAME') ?: 'root';
        $pass = getenv('DB_PASSWORD') ?: '';

        try {
            $pdo = new \PDO($dsn, $user, $pass, [
                \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
            ]);
        } catch (\PDOException $e) {
            $this->markTestSkipped('Database not available: ' . $e->getMessage());
        }

        $stmt = $pdo->query("SHOW TABLES LIKE 'erik_%'");
        $tables = $stmt->fetchAll(\PDO::FETCH_COLUMN);

        foreach ($tables as $table) {
            $columns = $pdo->query("SHOW COLUMNS FROM `{$table}` WHERE `Field` = 'id'");
            $col = $columns->fetch(\PDO::FETCH_ASSOC);

            if (!$col) {
                continue; // 无id字段的表跳过（如中间表）
            }

            $this->assertStringContainsString(
                'bigint', strtolower($col['Type']),
                "{$table}.id 应为 BIGINT 类型，实际: {$col['Type']}"
            );
            $this->assertSame(
                'NO', $col['Null'],
                "{$table}.id 不允许 NULL"
            );
            $this->assertStringNotContainsString(
                'auto_increment', strtolower($col['Extra']),
                "{$table}.id 不应为自增"
            );
        }
    }

    /**
     * RED: 验证表前缀统一为 erik_
     */
    public function testTablePrefixIsErik(): void
    {
        $dsn = getenv('DB_DSN') ?: 'mysql:host=127.0.0.1;port=3306;dbname=property_management';
        $user = getenv('DB_USERNAME') ?: 'root';
        $pass = getenv('DB_PASSWORD') ?: '';

        try {
            $pdo = new \PDO($dsn, $user, $pass, [
                \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
            ]);
        } catch (\PDOException $e) {
            $this->markTestSkipped('Database not available: ' . $e->getMessage());
        }

        $stmt = $pdo->query("SHOW TABLES LIKE 'erik_%'");
        $tables = $stmt->fetchAll(\PDO::FETCH_COLUMN);

        $this->assertNotEmpty($tables, '应有erik_前缀的表存在');

        foreach ($tables as $table) {
            $this->assertStringStartsWith(
                'erik_', $table,
                "表 {$table} 应以 erik_ 开头"
            );
        }
    }
}
