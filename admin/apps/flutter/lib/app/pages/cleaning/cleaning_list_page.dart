/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'cleaning_controller.dart';

class CleaningAreaListPage extends GetView<CleaningAreaController> {
  const CleaningAreaListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CleaningAreaController>()) Get.put(CleaningAreaController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('保洁区域', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)), const Spacer(),
        ElevatedButton.icon(onPressed:()=>_form(context,c), icon:const Icon(Icons.add), label:const Text('新增区域')),
      ]),
      const SizedBox(height:12),
      Expanded(child: Obx(() {
        if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
        return DataTable(columns: const [DataColumn(label:Text('区域名称')),DataColumn(label:Text('负责人')),DataColumn(label:Text('频次')),DataColumn(label:Text('状态')),DataColumn(label:Text('操作'))],
          rows: c.areas.map((a){final id=a['id'].toString();return DataRow(cells:[
            DataCell(Text(a['name']??'')),DataCell(Text(a['cleaner_name']??'-')),DataCell(Text(a['frequency']??'-')),DataCell(StatusChip(status:a['status']as int?)),
            DataCell(Row(mainAxisSize:MainAxisSize.min,children:[IconButton(icon:Icon(Icons.edit,size:18),onPressed:()=>_form(context,c,data:a)),IconButton(icon:Icon(Icons.delete,size:18,color:Colors.red),onPressed:()async{final p=await ConfirmDeleteDialog.show(context,itemName:a['name']??'');if(p!=null)c.deleteItem(id,p);})])),
          ]));}).toList(),
        );
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _form(BuildContext ctx,CleaningAreaController c,{Map<String,dynamic>? data}) {
    final n=TextEditingController(text:data?['name']??''),cl=TextEditingController(text:data?['cleaner_name']??''),freq=TextEditingController(text:data?['frequency']??'');
    final isEdit=data!=null;
    showDialog(context:ctx,builder:(_)=>AlertDialog(title:Text(isEdit?'编辑区域':'新增区域'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:n,decoration:const InputDecoration(labelText:'区域名称',isDense:true)),const SizedBox(height:12),TextField(controller:cl,decoration:const InputDecoration(labelText:'负责人',isDense:true)),const SizedBox(height:12),TextField(controller:freq,decoration:const InputDecoration(labelText:'频次',isDense:true)),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(n.text.isEmpty)return;try{final d={'name':n.text.trim(),'cleaner_name':cl.text.trim(),'frequency':freq.text.trim()};if(isEdit)await c.updateItem(data!['id'],d);else{await c.api.post(ApiConfig.cleaningArea,data:d);c.loadItems(reset:true);}if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)Get.snackbar('错误','操作失败:$e');}},child:Text(isEdit?'保存':'创建'))],)));
  }
}

class CleaningRecordListPage extends GetView<CleaningRecordController> {
  const CleaningRecordListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CleaningRecordController>()) Get.put(CleaningRecordController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('打扫记录', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
        return DataTable(columns: const [DataColumn(label:Text('区域')),DataColumn(label:Text('打扫人')),DataColumn(label:Text('时间')),DataColumn(label:Text('状态'))],
          rows: c.records.map((r)=>DataRow(cells:[DataCell(Text(r['area_name']??'-')),DataCell(Text(r['cleaner_name']??'-')),DataCell(Text(r['cleaned_at']??'-')),DataCell(Text(r['status']==1?'已完成':'未完成'))])).toList());
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:15,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
}
