/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'activity_controller.dart';
import '../../config/api_config.dart';

class ActivityListPage extends GetView<ActivityController> {
  const ActivityListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ActivityController>()) Get.put(ActivityController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('社区活动', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)), const Spacer(),
        ElevatedButton.icon(onPressed:()=>_form(context,c), icon:const Icon(Icons.add), label:const Text('新增活动')),
      ]),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('活动名称')),DataColumn(label:Text('地点')),DataColumn(label:Text('开始时间')),DataColumn(label:Text('报名')),DataColumn(label:Text('状态')),DataColumn(label:Text('操作'))],
          rows:c.activities.map((a){final id=a['id'].toString();return DataRow(cells:[
            DataCell(Text(a['title']??'')),DataCell(Text(a['location']??'-')),DataCell(Text(a['start_time']??'-')),
            DataCell(Text('${a['signup_count']??0}/${a['max_signup']??'-'}')),
            DataCell(StatusChip(status:a['status']as int?,labels:const{0:'筹备中',1:'报名中',2:'进行中',3:'已结束'})),
            DataCell(Row(mainAxisSize:MainAxisSize.min,children:[IconButton(icon:Icon(Icons.edit,size:18),onPressed:()=>_form(context,c,data:a)),IconButton(icon:Icon(Icons.delete,size:18,color:Colors.red),onPressed:()async{final p=await ConfirmDeleteDialog.show(context,itemName:a['title']??'');if(p!=null)c.deleteItem(id,p);})])),
          ]);}).toList(),
        );
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _form(BuildContext ctx,ActivityController c,{Map<String,dynamic>? data}) {
    final t=TextEditingController(text:data?['title']??''),loc=TextEditingController(text:data?['location']??''),st=TextEditingController(text:data?['start_time']??''),et=TextEditingController(text:data?['end_time']??''),mx=TextEditingController(text:data?['max_signup']?.toString()??'');
    final isEdit=data!=null;
    showDialog(context:ctx,builder:(_)=>AlertDialog(title:Text(isEdit?'编辑活动':'新增活动'),content:SizedBox(width:400,child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:t,decoration:const InputDecoration(labelText:'活动名称',isDense:true)),const SizedBox(height:12),TextField(controller:loc,decoration:const InputDecoration(labelText:'地点',isDense:true)),const SizedBox(height:12),TextField(controller:st,decoration:const InputDecoration(labelText:'开始时间',isDense:true)),const SizedBox(height:12),TextField(controller:et,decoration:const InputDecoration(labelText:'结束时间',isDense:true)),const SizedBox(height:12),TextField(controller:mx,decoration:const InputDecoration(labelText:'最大报名人数',isDense:true)),
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(t.text.isEmpty)return;try{final d={'title':t.text.trim(),'location':loc.text.trim(),'start_time':st.text.trim(),'end_time':et.text.trim(),'max_signup':int.tryParse(mx.text)};if (isEdit) { await c.updateItem(data['id'], d); }else{await c.api.post(ApiConfig.activity,data:d);c.loadItems(reset:true);}if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)Get.snackbar('错误','操作失败:$e');}},child:Text(isEdit?'保存':'创建'))],));
  }
}
class ActivitySignupListPage extends GetView<ActivitySignupController> {
  const ActivitySignupListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ActivitySignupController>()) Get.put(ActivitySignupController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('活动报名', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('活动')),DataColumn(label:Text('报名人')),DataColumn(label:Text('手机号')),DataColumn(label:Text('状态')),DataColumn(label:Text('操作'))],
          rows:c.signups.map((s)=>DataRow(cells:[DataCell(Text(s['activity_title']??'-')),DataCell(Text(s['name']??'-')),DataCell(Text(s['phone']??'-')),DataCell(Text(s['checked_in']==1?'已签到':'未签到')),DataCell(s['checked_in']!=1?ElevatedButton(onPressed:()=>c.checkin(s['id']),style:ElevatedButton.styleFrom(padding:EdgeInsets.zero),child:const Text('签到')):const Text('-'))])).toList());
      })),
    ]);
  }
}
