/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'sla_controller.dart';
import '../../config/api_config.dart';

class SlaRuleListPage extends GetView<SlaRuleController> {
  const SlaRuleListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SlaRuleController>()) Get.put(SlaRuleController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('SLA规则', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)), const Spacer(),
        ElevatedButton.icon(onPressed:()=>_form(context,c), icon:const Icon(Icons.add), label:const Text('新增规则')),
      ]),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('规则名称')),DataColumn(label:Text('超时时限')),DataColumn(label:Text('升级动作')),DataColumn(label:Text('操作'))],
          rows:c.rules.map((r){final id=r['id'].toString();return DataRow(cells:[DataCell(Text(r['name']??'')),DataCell(Text(r['timeout_hours']!=null?'${r['timeout_hours']}小时':'-')),DataCell(Text(r['escalation_action']??'-')),DataCell(Row(mainAxisSize:MainAxisSize.min,children:[IconButton(icon:Icon(Icons.edit,size:18),onPressed:()=>_form(context,c,data:r)),IconButton(icon:Icon(Icons.delete,size:18,color:Colors.red),onPressed:()async{final p=await ConfirmDeleteDialog.show(context,itemName:r['name']??'');if(p!=null)c.deleteItem(id,p);})]))]);
        }).toList());
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _form(BuildContext ctx,SlaRuleController c,{Map<String,dynamic>? data}) {
    final n=TextEditingController(text:data?['name']??''),h=TextEditingController(text:data?['timeout_hours']?.toString()??''),act=TextEditingController(text:data?['escalation_action']??'');
    final isEdit=data!=null;
    showDialog(context:ctx,builder:(_)=>AlertDialog(title:Text(isEdit?'编辑规则':'新增规则'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:n,decoration:const InputDecoration(labelText:'规则名称',isDense:true)),const SizedBox(height:12),TextField(controller:h,decoration:const InputDecoration(labelText:'超时时限(小时)',isDense:true)),const SizedBox(height:12),TextField(controller:act,decoration:const InputDecoration(labelText:'升级动作',isDense:true)),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(n.text.isEmpty)return;try{final d={'name':n.text.trim(),'timeout_hours':int.tryParse(h.text),'escalation_action':act.text.trim()};if (isEdit) { await c.updateItem(data['id'], d); }else{await c.api.post(ApiConfig.slaRule,data:d);c.loadItems(reset:true);}if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)Get.snackbar('错误','操作失败:$e');}},child:Text(isEdit?'保存':'创建'))],));
  }
}
class SlaRecordListPage extends GetView<SlaRecordController> {
  const SlaRecordListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SlaRecordController>()) Get.put(SlaRecordController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('SLA升级记录', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('关联对象')),DataColumn(label:Text('规则')),DataColumn(label:Text('升级级别')),DataColumn(label:Text('时间'))],
          rows:c.records.map((r)=>DataRow(cells:[DataCell(Text(r['target_name']??'-')),DataCell(Text(r['rule_name']??'-')),DataCell(Text('${r['escalation_level']??'-'}')),DataCell(Text(r['created_at']??'-'))])).toList());
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:15,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
}
