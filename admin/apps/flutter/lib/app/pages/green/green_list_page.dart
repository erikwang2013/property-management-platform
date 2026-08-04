/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'green_controller.dart';

class GreenAreaListPage extends GetView<GreenAreaController> {
  const GreenAreaListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<GreenAreaController>()) Get.put(GreenAreaController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('绿化区域', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)), const Spacer(),
        ElevatedButton.icon(onPressed:()=>_form(context,c), icon:const Icon(Icons.add), label:const Text('新增区域')),
      ]),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('区域名称')),DataColumn(label:Text('植物种类')),DataColumn(label:Text('面积')),DataColumn(label:Text('状态')),DataColumn(label:Text('操作'))],
          rows:c.areas.map((a){final id=a['id'].toString();return DataRow(cells:[
            DataCell(Text(a['name']??'')),DataCell(Text(a['plant_type']??'-')),DataCell(Text('${a['area']??'-'}')),DataCell(StatusChip(status:a['status']as int?)),
            DataCell(Row(mainAxisSize:MainAxisSize.min,children:[IconButton(icon:Icon(Icons.edit,size:18),onPressed:()=>_form(context,c,data:a)),IconButton(icon:Icon(Icons.delete,size:18,color:Colors.red),onPressed:()async{final p=await ConfirmDeleteDialog.show(context,itemName:a['name']??'');if(p!=null)c.deleteItem(id,p);})])),
          ]));}).toList(),
        );
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _form(BuildContext ctx,GreenAreaController c,{Map<String,dynamic>? data}) {
    final n=TextEditingController(text:data?['name']??''),pt=TextEditingController(text:data?['plant_type']??''),ar=TextEditingController(text:data?['area']?.toString()??'');
    final isEdit=data!=null;
    showDialog(context:ctx,builder:(_)=>AlertDialog(title:Text(isEdit?'编辑区域':'新增区域'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:n,decoration:const InputDecoration(labelText:'区域名称',isDense:true)),const SizedBox(height:12),TextField(controller:pt,decoration:const InputDecoration(labelText:'植物种类',isDense:true)),const SizedBox(height:12),TextField(controller:ar,decoration:const InputDecoration(labelText:'面积',isDense:true)),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(n.text.isEmpty)return;try{final d={'name':n.text.trim(),'plant_type':pt.text.trim(),'area':double.tryParse(ar.text)};if(isEdit)await c.updateItem(data!['id'],d);else{await c.api.post(ApiConfig.greenArea,data:d);c.loadItems(reset:true);}if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)Get.snackbar('错误','操作失败:$e');}},child:Text(isEdit?'保存':'创建'))],)));
  }
}
class GreenMaintenanceListPage extends GetView<GreenMaintenanceController> {
  const GreenMaintenanceListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<GreenMaintenanceController>()) Get.put(GreenMaintenanceController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('养护记录', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('区域')),DataColumn(label:Text('养护内容')),DataColumn(label:Text('养护人')),DataColumn(label:Text('时间'))],
          rows:c.records.map((r)=>DataRow(cells:[DataCell(Text(r['area_name']??'-')),DataCell(Text(r['content']??'-')),DataCell(Text(r['maintainer']??'-')),DataCell(Text(r['maintained_at']??'-'))])).toList());
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:15,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
}
