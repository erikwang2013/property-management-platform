<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\common;

/**
 * Apidoc 通用定义
 * 用于 @Apidoc\Method 中的 @ref 引用
 */
class Definitions
{
    /**
     * 分页参数
     * @Apidoc\Param("page", type="int", require=false, default=1, desc="页码")
     * @Apidoc\Param("page_size", type="int", require=false, default=20, desc="每页条数")
     */
    public function pagination() {}

    /**
     * 通用搜索参数
     * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词")
     * @Apidoc\Param("status", type="int", require=false, desc="状态筛选")
     */
    public function searchParams() {}

    /**
     * 日期范围参数
     * @Apidoc\Param("start_date", type="string", require=false, desc="开始日期 Y-m-d")
     * @Apidoc\Param("end_date", type="string", require=false, desc="结束日期 Y-m-d")
     */
    public function dateRange() {}

    /**
     * 密码确认
     * @Apidoc\Param("password", type="string", require=true, desc="当前密码确认")
     */
    public function passwordConfirm() {}

    /**
     * 软删除响应
     * @Apidoc\Returned("id", type="string", desc="已删除资源的hashid")
     */
    public function deletedResponse() {}
}
