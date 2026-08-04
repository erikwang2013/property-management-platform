/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'collection_controller.dart';

class CollectionStrategyListPage extends GetView<CollectionStrategyController> {
  const CollectionStrategyListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CollectionStrategyController>()) Get.put(CollectionStrategyController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('催缴策略', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)), const Spacer(),
        ElevatedButton.icon(onPressed:()=>_form(context,c), icon:const Icon(Icons.add), label:const Text('新增策略')),
      ]),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('策略名称')),DataColumn(label:Text('逾期天数')),DataColumn(label:Text('通知方式')),DataColumn(label:Text('操作'))],
          rows:c.strategies.map((s){final id=s['id'].toString();return DataRow(cells:[DataCell(Text(s['name']??'')),DataCell(Text('${s['overdue_days']??'-'}天')),DataCell(Text(s['notify_method']??'-')),DataCell(Row(mainAxisSize:MainAxisSize.min,children:[IconButton(icon:Icon(Icons.edit,size:18),onPressed:()=>_form(context,c,data:s)),IconButton(icon:Icon(Icons.delete,size:18,color:Colors.red),onPressed:()async{final p=await ConfirmDeleteDialog.show(context,itemName:s['name']??'');if(p!=null)c.deleteItem(id,p);})]))]);
        }).toList());
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _form(BuildContext ctx,CollectionStrategyController c,{Map<String,dynamic>? data}) {
    final n=TextEditingController(text:data?['name']??''),d=TextEditingController(text:data?['overdue_days']?.toString()??''),m=TextEditingController(text:data?['notify_method']??'');
    final isEdit=data!=null;
    showDialog(context:ctx,builder:(_)=>AlertDialog(title:Text(isEdit?'编辑策略':'新增策略'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:n,decoration:const InputDecoration(labelText:'策略名称',isDense:true)),const SizedBox(height:12),TextField(controller:d,decoration:const InputDecoration(labelText:'逾期天数',isDense:true)),const SizedBox(height:12),TextField(controller:m,decoration:const InputDecoration(labelText:'通知方式',isDense:true)),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(n.text.isEmpty)return;try{final dd={'name':n.text.trim(),'overdue_days':int.tryParse(d.text),'notify_method':m.text.trim()};if(isEdit)await c.updateItem(data!['id'],dd);else{await c.api.post(ApiConfig.collectionStrategy,data:dd);c.loadItems(reset:true);}if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)Get.snackbar('错误','操作失败:$e');}},child:Text(isEdit?'保存':'创建'))],));
  }
}
class CollectionRecordListPage extends GetView<CollectionRecordController> {
  const CollectionRecordListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CollectionRecordController>()) Get.put(CollectionRecordController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Text('催缴记录',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const Spacer(),
        ElevatedButton.icon(onPressed:()=>c.run(),icon:const Icon(Icons.play_arrow),label:const Text('执行催缴')),
      ]),const SizedBox(height:12),
      Expanded(child:Obx((){
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('业主')),DataColumn(label:Text('账单')),DataColumn(label:Text('策略')),DataColumn(label:Text('结果')),DataColumn(label:Text('时间'))],
          rows:c.records.map((r)=>DataRow(cells:[DataCell(Text(r['owner_name']??'-')),DataCell(Text(r['bill_info']??'-')),DataCell(Text(r['strategy_name']??'-')),DataCell(Text(r['result']??'-')),DataCell(Text(r['created_at']??'-'))])).toList());
      })),
    ]);
  }
}
