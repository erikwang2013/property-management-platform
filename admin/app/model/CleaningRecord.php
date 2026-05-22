<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;

class CleaningRecord extends BaseModel
{
    protected $table = 'erik_cleaning_record';
    protected $fillable = ['area_id', 'staff_id', 'cleaned_at', 'status', 'inspector_id', 'inspection_remark', 'inspection_at', 'images'];
    protected $casts = [
        'status' => 'integer',
        'cleaned_at' => 'datetime', 'inspection_at' => 'datetime',
        'created_at' => 'datetime',
    ];
    public function area() { return $this->belongsTo(CleaningArea::class, 'area_id'); }
}
