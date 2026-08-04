/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import 'payment_controller.dart';

class PaymentListPage extends GetView<PaymentController> {
  const PaymentListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PaymentController>()) Get.put(PaymentController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('支付订单', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('订单号')),DataColumn(label:Text('金额')),DataColumn(label:Text('支付方式')),DataColumn(label:Text('状态')),DataColumn(label:Text('时间'))],
          rows:c.payments.map((p)=>DataRow(cells:[DataCell(Text(p['order_no']??'-')),DataCell(Text('${p['amount']??'-'}')),DataCell(Text(p['pay_method']??'-')),DataCell(Chip(label:Text(p['status']==1?'已支付':'待支付',style:const TextStyle(fontSize:12)),color:WidgetStatePropertyAll(p['status']==1?Colors.green.shade50:Colors.orange.shade50))),DataCell(Text(p['created_at']??'-'))])).toList());
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
}
