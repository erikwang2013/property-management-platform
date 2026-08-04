<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\common;

class Validator
{
    private array $data;
    private array $errors = [];

    public function __construct(array $data)
    {
        $this->data = $data;
    }

    public function required(string $field, string $label = ''): self
    {
        $label = $label ?: $field;
        $value = $this->data[$field] ?? null;
        if ($value === null || $value === '' || (is_array($value) && empty($value))) {
            $this->errors[$field] = "{$label}不能为空";
        }
        return $this;
    }

    public function max(string $field, int $max, string $label = ''): self
    {
        $label = $label ?: $field;
        $value = $this->data[$field] ?? '';
        if ($value !== '' && $value !== null && mb_strlen((string) $value) > $max) {
            $this->errors[$field] = "{$label}不能超过{$max}个字符";
        }
        return $this;
    }

    public function min(string $field, int $min, string $label = ''): self
    {
        $label = $label ?: $field;
        $value = $this->data[$field] ?? '';
        if ($value !== '' && $value !== null && mb_strlen((string) $value) < $min) {
            $this->errors[$field] = "{$label}不能少于{$min}个字符";
        }
        return $this;
    }

    public function numeric(string $field, string $label = ''): self
    {
        $label = $label ?: $field;
        $value = $this->data[$field] ?? null;
        if ($value !== null && $value !== '' && !is_numeric($value)) {
            $this->errors[$field] = "{$label}必须为数字";
        }
        return $this;
    }

    public function integer(string $field, string $label = ''): self
    {
        $label = $label ?: $field;
        $value = $this->data[$field] ?? null;
        if ($value !== null && $value !== '' && !is_int($value) && !ctype_digit((string) $value)) {
            $this->errors[$field] = "{$label}必须为整数";
        }
        return $this;
    }

    public function email(string $field, string $label = ''): self
    {
        $label = $label ?: $field;
        $value = $this->data[$field] ?? '';
        if ($value !== '' && !filter_var($value, FILTER_VALIDATE_EMAIL)) {
            $this->errors[$field] = "{$label}格式不正确";
        }
        return $this;
    }

    public function mobile(string $field, string $label = ''): self
    {
        $label = $label ?: $field;
        $value = $this->data[$field] ?? '';
        if ($value !== '' && !preg_match('/^1[3-9]\d{9}$/', (string) $value)) {
            $this->errors[$field] = "{$label}格式不正确";
        }
        return $this;
    }

    public function date(string $field, string $format = 'Y-m-d', string $label = ''): self
    {
        $label = $label ?: $field;
        $value = $this->data[$field] ?? '';
        if ($value !== '' && \DateTime::createFromFormat($format, (string) $value) === false) {
            $this->errors[$field] = "{$label}格式不正确(需为{$format})";
        }
        return $this;
    }

    public function in(string $field, array $allowed, string $label = ''): self
    {
        $label = $label ?: $field;
        $value = $this->data[$field] ?? null;
        if ($value !== null && $value !== '' && !in_array($value, $allowed, true)) {
            $this->errors[$field] = "{$label}值无效";
        }
        return $this;
    }

    public function minValue(string $field, int|float $min, string $label = ''): self
    {
        $label = $label ?: $field;
        $value = $this->data[$field] ?? null;
        if ($value !== null && $value !== '' && (float) $value < $min) {
            $this->errors[$field] = "{$label}不能小于{$min}";
        }
        return $this;
    }

    public function maxValue(string $field, int|float $max, string $label = ''): self
    {
        $label = $label ?: $field;
        $value = $this->data[$field] ?? null;
        if ($value !== null && $value !== '' && (float) $value > $max) {
            $this->errors[$field] = "{$label}不能大于{$max}";
        }
        return $this;
    }

    public function firstError(): ?string
    {
        return !empty($this->errors) ? reset($this->errors) : null;
    }

    public function errors(): array
    {
        return $this->errors;
    }

    public function passes(): bool
    {
        return empty($this->errors);
    }

    public function fails(): bool
    {
        return !empty($this->errors);
    }
}
