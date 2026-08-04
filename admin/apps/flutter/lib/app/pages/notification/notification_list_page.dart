/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import 'notification_controller.dart';

class NotificationListPage extends GetView<NotificationController> {
  const NotificationListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationController>()) Get.put(NotificationController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('消息通知', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)), const Spacer(),
        ElevatedButton.icon(onPressed:()=>_form(context,c), icon:const Icon(Icons.add), label:const Text('发送通知')),
      ]),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('标题')),DataColumn(label:Text('接收人')),DataColumn(label:Text('类型')),DataColumn(label:Text('状态')),DataColumn(label:Text('发送时间'))],
          rows:c.notifications.map((n)=>DataRow(cells:[DataCell(Text(n['title']??'')),DataCell(Text(n['recipient']??'-')),DataCell(Text(n['type']??'-')),DataCell(StatusChip(status:n['status']as int?,labels:const{0:'未发送',1:'已发送',2:'已读'})),DataCell(Text(n['sent_at']??n['created_at']??'-'))])).toList());
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _form(BuildContext ctx,NotificationController c) {
    final t=TextEditingController(),r=TextEditingController(),body=TextEditingController();
    showDialog(context:ctx,builder:(_)=>AlertDialog(title:const Text('发送通知'),content:SizedBox(width:400,child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:t,decoration:const InputDecoration(labelText:'标题',isDense:true)),const SizedBox(height:12),
      TextField(controller:r,decoration:const InputDecoration(labelText:'接收人',isDense:true)),const SizedBox(height:12),
      TextField(controller:body,decoration:const InputDecoration(labelText:'内容',isDense:true),maxLines:3),
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(t.text.isEmpty)return;try{await c.api.post(ApiConfig.notification,data:{'title':t.text.trim(),'recipient':r.text.trim(),'content':body.text.trim()});c.loadItems(reset:true);if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)Get.snackbar('错误','发送失败:$e');}},child:const Text('发送'))],));
  }
}
