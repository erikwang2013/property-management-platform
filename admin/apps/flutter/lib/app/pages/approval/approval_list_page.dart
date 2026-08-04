/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import 'approval_controller.dart';

class ApprovalListPage extends GetView<ApprovalController> {
  const ApprovalListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ApprovalController>()) Get.put(ApprovalController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('审批工作流', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:12),
      Row(children:[ChoiceChip(label:const Text('全部'),selected:c.statusFilter.value==null,onSelected:(_)=>c.filterByStatus(null)),const SizedBox(width:4),ChoiceChip(label:const Text('待审批'),selected:c.statusFilter.value==0,onSelected:(_)=>c.filterByStatus(0)),const SizedBox(width:4),ChoiceChip(label:const Text('已通过'),selected:c.statusFilter.value==1,onSelected:(_)=>c.filterByStatus(1)),const SizedBox(width:4),ChoiceChip(label:const Text('已驳回'),selected:c.statusFilter.value==2,onSelected:(_)=>c.filterByStatus(2))]),
      const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('审批类型')),DataColumn(label:Text('申请人')),DataColumn(label:Text('状态')),DataColumn(label:Text('时间'))],
          rows:c.approvals.map((a)=>DataRow(cells:[DataCell(Text(a['type_name']??'-')),DataCell(Text(a['applicant_name']??'-')),DataCell(StatusChip(status:a['status']as int?,labels:const{0:'待审批',1:'已通过',2:'已驳回'})),DataCell(Text(a['created_at']??'-'))])).toList());
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
}
