/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'energy_controller.dart';
import '../../config/api_config.dart';

class EnergyMeterListPage extends GetView<EnergyMeterController> {
  const EnergyMeterListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<EnergyMeterController>()) Get.put(EnergyMeterController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('能耗仪表', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)), const Spacer(),
        ElevatedButton.icon(onPressed:()=>_form(context,c), icon:const Icon(Icons.add), label:const Text('新增仪表')),
      ]),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('仪表编号')),DataColumn(label:Text('类型')),DataColumn(label:Text('位置')),DataColumn(label:Text('状态')),DataColumn(label:Text('操作'))],
          rows:c.meters.map((m){final id=m['id'].toString();return DataRow(cells:[
            DataCell(Text(m['meter_no']??'')),DataCell(Text(m['type']??'-')),DataCell(Text(m['location']??'-')),DataCell(StatusChip(status:m['status']as int?)),
            DataCell(Row(mainAxisSize:MainAxisSize.min,children:[IconButton(icon:Icon(Icons.edit,size:18),onPressed:()=>_form(context,c,data:m)),IconButton(icon:Icon(Icons.delete,size:18,color:Colors.red),onPressed:()async{final p=await ConfirmDeleteDialog.show(context,itemName:m['meter_no']??'');if(p!=null)c.deleteItem(id,p);})])),
          ]);}).toList(),
        );
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _form(BuildContext ctx,EnergyMeterController c,{Map<String,dynamic>? data}) {
    final no=TextEditingController(text:data?['meter_no']??'');String type=data?['type']??'electric';final loc=TextEditingController(text:data?['location']??'');
    final isEdit=data!=null;
    showDialog(context:ctx,builder:(_)=>StatefulBuilder(builder:(_,st)=>AlertDialog(title:Text(isEdit?'编辑仪表':'新增仪表'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:no,decoration:const InputDecoration(labelText:'仪表编号',isDense:true)),const SizedBox(height:12),
      DropdownButtonFormField<String>(initialValue:type,decoration:const InputDecoration(labelText:'类型',isDense:true),items:const[DropdownMenuItem(value:'electric',child:Text('电')),DropdownMenuItem(value:'water',child:Text('水')),DropdownMenuItem(value:'gas',child:Text('气'))],onChanged:(v)=>st(()=>type=v??'electric')),
      const SizedBox(height:12),TextField(controller:loc,decoration:const InputDecoration(labelText:'位置',isDense:true)),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(no.text.isEmpty)return;try{final d={'meter_no':no.text.trim(),'type':type,'location':loc.text.trim()};if (isEdit) { await c.updateItem(data['id'], d); }else{await c.api.post(ApiConfig.energyMeter,data:d);c.loadItems(reset:true);}if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)Get.snackbar('错误','操作失败:$e');}},child:Text(isEdit?'保存':'创建'))],)));
  }
}
class EnergyRecordListPage extends GetView<EnergyRecordController> {
  const EnergyRecordListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<EnergyRecordController>()) Get.put(EnergyRecordController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('抄表记录', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)), const Spacer(),
        ElevatedButton.icon(onPressed:()=>_readingForm(context,c), icon:const Icon(Icons.add), label:const Text('录入抄表')),
      ]),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('仪表')),DataColumn(label:Text('读数')),DataColumn(label:Text('用量')),DataColumn(label:Text('日期'))],
          rows:c.records.map((r)=>DataRow(cells:[DataCell(Text(r['meter_no']??'-')),DataCell(Text('${r['reading']??'-'}')),DataCell(Text('${r['usage_amount']??'-'}')),DataCell(Text(r['record_date']??'-'))])).toList());
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:15,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _readingForm(BuildContext ctx,EnergyRecordController c) {
    final meter=TextEditingController(),reading=TextEditingController();
    showDialog(context:ctx,builder:(_)=>AlertDialog(title:const Text('录入抄表'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:meter,decoration:const InputDecoration(labelText:'仪表ID',isDense:true)),const SizedBox(height:12),TextField(controller:reading,decoration:const InputDecoration(labelText:'读数',isDense:true)),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(meter.text.isEmpty||reading.text.isEmpty)return;await c.record(meter.text.trim(),double.parse(reading.text));if(ctx.mounted)Navigator.pop(ctx);},child:const Text('保存'))],));
  }
}
