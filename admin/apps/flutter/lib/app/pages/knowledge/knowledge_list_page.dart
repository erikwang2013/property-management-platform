/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'knowledge_controller.dart';
import '../../config/api_config.dart';

class KnowledgeCategoryListPage extends GetView<KnowledgeCategoryController> {
  const KnowledgeCategoryListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<KnowledgeCategoryController>()) Get.put(KnowledgeCategoryController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('知识库分类', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)), const Spacer(),
        ElevatedButton.icon(onPressed:()=>_form(context,c), icon:const Icon(Icons.add), label:const Text('新增分类')),
      ]),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('名称')),DataColumn(label:Text('排序')),DataColumn(label:Text('状态')),DataColumn(label:Text('操作'))],
          rows:c.categories.map((x){final id=x['id'].toString();return DataRow(cells:[DataCell(Text(x['name']??'')),DataCell(Text('${x['sort']??0}')),DataCell(StatusChip(status:x['status']as int?)),DataCell(Row(mainAxisSize:MainAxisSize.min,children:[IconButton(icon:Icon(Icons.edit,size:18),onPressed:()=>_form(context,c,data:x)),IconButton(icon:Icon(Icons.delete,size:18,color:Colors.red),onPressed:()async{final p=await ConfirmDeleteDialog.show(context,itemName:x['name']??'');if(p!=null)c.deleteItem(id,p);})]))]);}).toList());
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _form(BuildContext ctx,KnowledgeCategoryController c,{Map<String,dynamic>? data}){final n=TextEditingController(text:data?['name']??'');final s=TextEditingController(text:data?['sort']?.toString()??'');final isEdit=data!=null;showDialog(context:ctx,builder:(_)=>AlertDialog(title:Text(isEdit?'编辑分类':'新增分类'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'名称',isDense:true)),const SizedBox(height:12),TextField(controller:s,decoration:const InputDecoration(labelText:'排序',isDense:true))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(n.text.isEmpty)return;try{final d={'name':n.text.trim(),'sort':int.tryParse(s.text)??0};if (isEdit) { await c.updateItem(data['id'], d); }else{await c.api.post(ApiConfig.knowledgeCategory,data:d);c.loadItems(reset:true);}if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)Get.snackbar('错误','操作失败:$e');}},child:Text(isEdit?'保存':'创建'))],));}
}
class KnowledgeArticleListPage extends GetView<KnowledgeArticleController> {
  const KnowledgeArticleListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<KnowledgeArticleController>()) Get.put(KnowledgeArticleController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('知识库文章', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)), const Spacer(),
        ElevatedButton.icon(onPressed:()=>_form(context,c), icon:const Icon(Icons.add), label:const Text('新增文章')),
      ]),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('标题')),DataColumn(label:Text('分类')),DataColumn(label:Text('状态')),DataColumn(label:Text('操作'))],
          rows:c.articles.map((a){final id=a['id'].toString();return DataRow(cells:[DataCell(Text(a['question']??a['title']??'')),DataCell(Text(a['category_name']??'-')),DataCell(StatusChip(status:a['status']as int?)),DataCell(Row(mainAxisSize:MainAxisSize.min,children:[IconButton(icon:Icon(Icons.edit,size:18),onPressed:()=>_form(context,c,data:a)),IconButton(icon:Icon(Icons.delete,size:18,color:Colors.red),onPressed:()async{final p=await ConfirmDeleteDialog.show(context,itemName:a['question']??a['title']??'');if(p!=null)c.deleteItem(id,p);})]))]);}).toList());
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _form(BuildContext ctx,KnowledgeArticleController c,{Map<String,dynamic>? data}){final q=TextEditingController(text:data?['question']??data?['title']??'');final a=TextEditingController(text:data?['answer']??data?['content']??'');final isEdit=data!=null;showDialog(context:ctx,builder:(_)=>AlertDialog(title:Text(isEdit?'编辑文章':'新增文章'),content:SizedBox(width:400,child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:q,decoration:const InputDecoration(labelText:'标题',isDense:true)),const SizedBox(height:12),TextField(controller:a,decoration:const InputDecoration(labelText:'内容',isDense:true),maxLines:5)])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(q.text.isEmpty)return;try{final d={'question':q.text.trim(),'answer':a.text.trim()};if (isEdit) { await c.updateItem(data['id'], d); }else{await c.api.post(ApiConfig.knowledge,data:d);c.loadItems(reset:true);}if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)Get.snackbar('错误','操作失败:$e');}},child:Text(isEdit?'保存':'创建'))],));}
}
class ChatRecordListPage extends GetView<ChatRecordController> {
  const ChatRecordListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ChatRecordController>()) Get.put(ChatRecordController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Text('智能问答',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold))]),
      Obx(()=>Row(children:[_statCard('总对话',c.stats['total_chats']?.toString()??'0',Colors.blue),_statCard('满意率',c.stats['satisfaction_rate']?.toString()??'0%',Colors.green)]),),
      const SizedBox(height:12),const Text('对话记录',style:TextStyle(fontSize:16,fontWeight:FontWeight.w600)),const SizedBox(height:8),
      Expanded(child:Obx((){
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return ListView(children:c.records.map((r)=>Card(child:ListTile(title:Text(r['question']??''),subtitle:Text(r['answer']??r['reply']??''),trailing:Text(r['created_at']??'',style:const TextStyle(fontSize:11,color:Colors.grey))))).toList());
      })),
    ]);
  }
  Widget _statCard(String l,String v,Color c)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[Text(l,style:const TextStyle(fontSize:12,color:Colors.grey)),Text(v,style:TextStyle(fontSize:24,fontWeight:FontWeight.bold,color:c))])));
}
