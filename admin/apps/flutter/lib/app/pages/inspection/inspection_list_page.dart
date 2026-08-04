/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/base_crud_controller.dart';

class InspectionTaskController extends BaseCrudController {
  final tasks = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.inspectionTask;
  @override List<dynamic> get items => tasks;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    tasks.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
  Future<void> startTask(String hid) async {
    await api.put(ApiConfig.inspectionStart(hid)); await loadItems(); Get.snackbar('成功','任务已开始');
  }
  Future<void> completeTask(String hid) async {
    await api.put(ApiConfig.inspectionComplete(hid)); await loadItems(); Get.snackbar('成功','任务已完成');
  }
}

class InspectionListPage extends GetView<InspectionTaskController> {
  const InspectionListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<InspectionTaskController>()) Get.put(InspectionTaskController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('巡检管理', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)), const Spacer(),
        ElevatedButton.icon(onPressed:()=>_form(context,c), icon:const Icon(Icons.add), label:const Text('新增任务')),
      ]),const SizedBox(height:12),
      Row(children:[ChoiceChip(label:const Text('全部'),selected:c.statusFilter.value==null,onSelected:(_)=>c.filterByStatus(null)),const SizedBox(width:4),ChoiceChip(label:const Text('待执行'),selected:c.statusFilter.value==0,onSelected:(_)=>c.filterByStatus(0)),const SizedBox(width:4),ChoiceChip(label:const Text('进行中'),selected:c.statusFilter.value==1,onSelected:(_)=>c.filterByStatus(1)),const SizedBox(width:4),ChoiceChip(label:const Text('已完成'),selected:c.statusFilter.value==2,onSelected:(_)=>c.filterByStatus(2))]),
      const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('任务名称')),DataColumn(label:Text('巡检人')),DataColumn(label:Text('计划日期')),DataColumn(label:Text('状态')),DataColumn(label:Text('操作'))],
          rows:c.tasks.map((t){final id=t['id'].toString();return DataRow(cells:[DataCell(Text(t['name']??'')),DataCell(Text(t['inspector_name']??'-')),DataCell(Text(t['scheduled_date']??'-')),DataCell(StatusChip(status:t['status']as int?,labels:const{0:'待执行',1:'进行中',2:'已完成'})),DataCell(Row(mainAxisSize:MainAxisSize.min,children:[
            if((t['status']as int? ?? 0)==0)IconButton(icon:const Icon(Icons.play_arrow,size:18,color:Colors.green),tooltip:'开始',onPressed:()=>c.startTask(id)),
            if((t['status']as int? ?? 0)==1)IconButton(icon:const Icon(Icons.check,size:18,color:Colors.blue),tooltip:'完成',onPressed:()=>c.completeTask(id)),
            IconButton(icon:const Icon(Icons.edit,size:18),onPressed:()=>_form(context,c,data:t)),
            IconButton(icon:const Icon(Icons.delete,size:18,color:Colors.red),onPressed:()async{final p=await ConfirmDeleteDialog.show(context,itemName:t['name']??'');if(p!=null)c.deleteItem(id,p);}),
          ]))])]);
        }).toList());
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _form(BuildContext ctx,InspectionTaskController c,{Map<String,dynamic>? data}) {
    final n=TextEditingController(text:data?['name']??''),ins=TextEditingController(text:data?['inspector_name']??''),dt=TextEditingController(text:data?['scheduled_date']??'');
    final isEdit=data!=null;
    showDialog(context:ctx,builder:(_)=>AlertDialog(title:Text(isEdit?'编辑任务':'新增任务'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:n,decoration:const InputDecoration(labelText:'任务名称',isDense:true)),const SizedBox(height:12),TextField(controller:ins,decoration:const InputDecoration(labelText:'巡检人',isDense:true)),const SizedBox(height:12),TextField(controller:dt,decoration:const InputDecoration(labelText:'计划日期',isDense:true)),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(n.text.isEmpty)return;try{final d={'name':n.text.trim(),'inspector_name':ins.text.trim(),'scheduled_date':dt.text.trim()};if(isEdit)await c.updateItem(data!['id'],d);else{await c.api.post(ApiConfig.inspectionTask,data:d);c.loadItems(reset:true);}if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)Get.snackbar('错误','操作失败:$e');}},child:Text(isEdit?'保存':'创建'))],));
  }
}
