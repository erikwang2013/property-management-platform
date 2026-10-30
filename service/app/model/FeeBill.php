<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

/**
 * @property int $id
 * @property string $bill_number
 * @property string $amount
 * @property string $paid_amount
 * @property string $late_fee
 * @property int $status
 * @property \Illuminate\Support\Carbon|null $start_date
 * @property \Illuminate\Support\Carbon|null $end_date
 * @property \Illuminate\Support\Carbon|null $due_date
 * @property \Illuminate\Support\Carbon|null $paid_at
 */
class FeeBill extends BaseModel
{
    /** 账单状态（与 management_fee_bill.status 列注释一致） */
    public const STATUS_UNPAID  = 0; // 未缴
    public const STATUS_PARTIAL = 1; // 部分缴
    public const STATUS_PAID    = 2; // 已缴
    public const STATUS_OVERDUE = 3; // 逾期
    public const STATUS_WAIVED  = 4; // 豁免

    protected $table = 'management_fee_bill';

    protected $fillable = [
        'room_id', 'owner_id', 'fee_type_id', 'bill_number',
        'amount', 'paid_amount', 'late_fee',
        'start_date', 'end_date', 'due_date',
        'status', 'paid_at', 'remark',
    ];

    protected $casts = [
        'room_id'     => 'integer',
        'owner_id'    => 'integer',
        'fee_type_id' => 'integer',
        'amount'      => 'decimal:2',
        'paid_amount' => 'decimal:2',
        'late_fee'    => 'decimal:2',
        'status'      => 'integer',
        'start_date'  => 'date',
        'end_date'    => 'date',
        'due_date'    => 'date',
        'paid_at'     => 'datetime',
        'created_at'  => 'datetime',
        'updated_at'  => 'datetime',
    ];

    /** 待缴金额 = 账单金额 + 滞纳金 - 已缴金额，下限 0（字符串，两位小数） */
    public function unpaidAmount(): string
    {
        if ((int) $this->status === self::STATUS_WAIVED) {
            return '0.00';
        }
        $unpaid = bcsub(bcadd((string) $this->amount, (string) $this->late_fee, 2), (string) $this->paid_amount, 2);
        return bccomp($unpaid, '0.00', 2) > 0 ? $unpaid : '0.00';
    }

    /** 缴费后的账单状态：缴足（含滞纳金）为已缴，否则为部分缴 */
    public static function statusAfterPayment(string $paidAmount, string $amount, string $lateFee): int
    {
        return bccomp($paidAmount, bcadd($amount, $lateFee, 2), 2) >= 0
            ? self::STATUS_PAID
            : self::STATUS_PARTIAL;
    }

    public function feeType()
    {
        return $this->belongsTo(FeeType::class);
    }

    public function room()
    {
        return $this->belongsTo(Room::class);
    }

    public function payments()
    {
        return $this->hasMany(FeePayment::class, 'bill_id');
    }
}
