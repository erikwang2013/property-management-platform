/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'vote_controller.dart';
import '../../config/api_config.dart';

class VoteListPage extends GetView<VoteController> {
  const VoteListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<VoteController>()) Get.put(VoteController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('业主投票', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)), const Spacer(),
        ElevatedButton.icon(onPressed:()=>_form(context,c), icon:const Icon(Icons.add), label:const Text('发起投票')),
      ]),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('投票标题')),DataColumn(label:Text('参与/总人数')),DataColumn(label:Text('状态')),DataColumn(label:Text('截止时间')),DataColumn(label:Text('操作'))],
          rows:c.votes.map((v){final id=v['id'].toString();return DataRow(cells:[DataCell(Text(v['title']??'')),DataCell(Text('${v['voted_count']??0}/${v['total_count']??0}')),DataCell(StatusChip(status:v['status']as int?,labels:const{0:'未开始',1:'进行中',2:'已结束'})),DataCell(Text(v['end_time']??'-')),DataCell(Row(mainAxisSize:MainAxisSize.min,children:[IconButton(icon:Icon(Icons.edit,size:18),onPressed:()=>_form(context,c,data:v)),IconButton(icon:Icon(Icons.delete,size:18,color:Colors.red),onPressed:()async{final p=await ConfirmDeleteDialog.show(context,itemName:v['title']??'');if(p!=null)c.deleteItem(id,p);})]))]);
        }).toList());
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _form(BuildContext ctx,VoteController c,{Map<String,dynamic>? data}) {
    final t=TextEditingController(text:data?['title']??''),end=TextEditingController(text:data?['end_time']??'');
    final isEdit=data!=null;
    showDialog(context:ctx,builder:(_)=>AlertDialog(title:Text(isEdit?'编辑投票':'发起投票'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:t,decoration:const InputDecoration(labelText:'投票标题',isDense:true)),const SizedBox(height:12),TextField(controller:end,decoration:const InputDecoration(labelText:'截止时间',isDense:true)),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(t.text.isEmpty)return;try{final d={'title':t.text.trim(),'end_time':end.text.trim()};if (isEdit) { await c.updateItem(data['id'], d); }else{await c.api.post(ApiConfig.vote,data:d);c.loadItems(reset:true);}if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)Get.snackbar('错误','操作失败:$e');}},child:Text(isEdit?'保存':'创建'))],));
  }
}
