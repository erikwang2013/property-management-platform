<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\common;

class Definitions
{
    /** @Apidoc\Param("page",type="int",require=false,default=1,desc="页码") */
    /** @Apidoc\Param("page_size",type="int",require=false,default=20,desc="每页条数") */
    public function pagination() {}

    /** @Apidoc\Param("keyword",type="string",require=false,desc="搜索关键词") */
    /** @Apidoc\Param("status",type="int",require=false,desc="状态筛选") */
    public function searchParams() {}

    /** @Apidoc\Param("start_date",type="string",require=false,desc="开始日期 Y-m-d") */
    /** @Apidoc\Param("end_date",type="string",require=false,desc="结束日期 Y-m-d") */
    public function dateRange() {}

    /** @Apidoc\Param("password",type="string",require=true,desc="当前密码确认") */
    public function passwordConfirm() {}
}
