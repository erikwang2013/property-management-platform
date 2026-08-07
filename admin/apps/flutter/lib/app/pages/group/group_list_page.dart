/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'group_controller.dart';
import '../../config/api_config.dart';

class GroupListPage extends GetView<GroupController> {
  const GroupListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<GroupController>()) Get.put(GroupController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('集团管理', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)), const Spacer(),
        ElevatedButton.icon(onPressed:()=>_form(context,c), icon:const Icon(Icons.add), label:const Text('新增集团')),
      ]),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('集团名称')),DataColumn(label:Text('小区数')),DataColumn(label:Text('操作'))],
          rows:c.groups.map((g){final id=g['id'].toString();return DataRow(cells:[DataCell(Text(g['name']??'')),DataCell(Text('${g['community_count']??0}')),DataCell(Row(mainAxisSize:MainAxisSize.min,children:[IconButton(icon:const Icon(Icons.edit,size:18),onPressed:()=>_form(context,c,data:g)),IconButton(icon:const Icon(Icons.visibility,size:18),tooltip:'查看汇总',onPressed:()async{await c.loadSummary(id);Get.defaultDialog(title:'集团汇总',content:Obx(()=>Column(mainAxisSize:MainAxisSize.min,children:[Text('小区数:${c.summary['community_count']??0}'),Text('业主数:${c.summary['owner_count']??0}'),Text('房产数:${c.summary['room_count']??0}')])));}),IconButton(icon:const Icon(Icons.delete,size:18,color:Colors.red),onPressed:()async{final p=await ConfirmDeleteDialog.show(context,itemName:g['name']??'');if(p!=null)c.deleteItem(id,p);})]))]);
        }).toList());
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _form(BuildContext ctx,GroupController c,{Map<String,dynamic>? data}) {
    final n=TextEditingController(text:data?['name']??'');final isEdit=data!=null;
    showDialog(context:ctx,builder:(_)=>AlertDialog(title:Text(isEdit?'编辑集团':'新增集团'),content:TextField(controller:n,decoration:const InputDecoration(labelText:'集团名称',isDense:true)),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(n.text.isEmpty)return;try{final d={'name':n.text.trim()};if (isEdit) { await c.updateItem(data['id'], d); }else{await c.api.post(ApiConfig.group,data:d);c.loadItems(reset:true);}if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)Get.snackbar('错误','操作失败:$e');}},child:Text(isEdit?'保存':'创建'))],));
  }
}
