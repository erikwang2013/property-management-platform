/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'security_controller.dart';
import '../../config/api_config.dart';

class SecurityPatrolListPage extends GetView<SecurityPatrolController> {
  const SecurityPatrolListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SecurityPatrolController>()) Get.put(SecurityPatrolController(), permanent: false);
    final c = controller;
    return _buildList(context, c, '安防巡逻', c.patrols, ['路线名称','负责人员','时段','状态'], (item) {
      return [Text(item['name']??''),Text(item['guard_name']??'-'),Text('${item['start_time']??''} - ${item['end_time']??''}'),StatusChip(status:item['status'] as int?)];
    });
  }
}
class PatrolRecordListPage extends GetView<PatrolRecordController> {
  const PatrolRecordListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PatrolRecordController>()) Get.put(PatrolRecordController(), permanent: false);
    final c = controller;
    return _buildRecordList(context, c, '巡逻记录', c.records, ['路线','巡逻人','开始时间','结束时间','状态']);
  }
}

Widget _buildList(BuildContext ctx, dynamic c, String title, RxList items, List<String> cols, List<Widget> Function(dynamic) cells) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const Spacer(),
      ElevatedButton.icon(onPressed: () => _patrolForm(ctx, c), icon: const Icon(Icons.add), label: Text('新增$title')),
    ]),
    const SizedBox(height:12),
    Expanded(child: Obx(() {
      if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
      if (items.isEmpty) return const Center(child: Text('暂无数据'));
      return DataTable(columns: [...cols.map((h)=>DataColumn(label:Text(h))), const DataColumn(label: Text('操作'))],
        rows: items.map((item) => DataRow(cells: [...cells(item).map((w) => DataCell(w)), DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: Icon(Icons.edit,size:18), onPressed: ()=>_patrolForm(ctx,c,data:item)),
          IconButton(icon: Icon(Icons.delete,size:18,color:Colors.red), onPressed: () async {
            final pwd = await ConfirmDeleteDialog.show(ctx, itemName: item['name']??'');
            if (pwd != null) c.deleteItem(item['id'].toString(), pwd);
          }),
        ]))])).toList());
    })),
    Obx(() => PaginationRow(page: c.page.value, total: c.total.value, pageSize: c.limit.value, onPrev: c.prevPage, onNext: c.nextPage)),
  ]);
}

Widget _buildRecordList(BuildContext ctx, dynamic c, String title, RxList items, List<String> cols) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    const SizedBox(height:12),
    Expanded(child: Obx(() {
      if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
      if (items.isEmpty) return const Center(child: Text('暂无数据'));
      return DataTable(columns: cols.map((h)=>DataColumn(label:Text(h))).toList(),
        rows: items.map((r) => DataRow(cells: [DataCell(Text(r['route_name']??'-')),DataCell(Text(r['guard_name']??'-')),DataCell(Text(r['start_time']??'-')),DataCell(Text(r['end_time']??'-')),DataCell(Text(r['status']==1?'完成':'进行中'))])).toList());
    })),
    Obx(() => PaginationRow(page: c.page.value, total: c.total.value, pageSize: 15, onPrev: c.prevPage, onNext: c.nextPage)),
  ]);
}

void _patrolForm(BuildContext ctx, dynamic c, {Map<String, dynamic>? data}) {
  final name = TextEditingController(text: data?['name']??'');
  final guard = TextEditingController(text: data?['guard_name']??'');
  final start = TextEditingController(text: data?['start_time']??'');
  final end = TextEditingController(text: data?['end_time']??'');
  final isEdit = data != null;
  showDialog(context:ctx, builder:(_)=>AlertDialog(
    title: Text(isEdit?'编辑巡逻路线':'新增巡逻路线'),
    content: Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:name,decoration:const InputDecoration(labelText:'路线名称',isDense:true)),
      const SizedBox(height:12),TextField(controller:guard,decoration:const InputDecoration(labelText:'负责人员',isDense:true)),
      const SizedBox(height:12),TextField(controller:start,decoration:const InputDecoration(labelText:'开始时间',isDense:true)),
      const SizedBox(height:12),TextField(controller:end,decoration:const InputDecoration(labelText:'结束时间',isDense:true)),
    ]),
    actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),
      ElevatedButton(onPressed:()async{
        if(name.text.trim().isEmpty)return;
        try{final d={'name':name.text.trim(),'guard_name':guard.text.trim(),'start_time':start.text.trim(),'end_time':end.text.trim()};
          if (isEdit) { await c.updateItem(data['id'], d); }
          else{await c.api.post(ApiConfig.securityPatrol,data:d);c.loadItems(reset:true);}
          if(ctx.mounted)Navigator.pop(ctx);
        }catch(e){if(ctx.mounted)Get.snackbar('错误','操作失败:$e');}
      },child:Text(isEdit?'保存':'创建')),
    ],
  ));
}
