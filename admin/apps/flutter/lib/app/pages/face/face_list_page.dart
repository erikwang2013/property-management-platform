/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'face_controller.dart';

class FaceListPage extends GetView<FaceController> {
  const FaceListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FaceController>()) Get.put(FaceController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('人脸审核', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('姓名')),DataColumn(label:Text('手机号')),DataColumn(label:Text('状态')),DataColumn(label:Text('提交时间')),DataColumn(label:Text('操作'))],
          rows:c.faces.map((f){final id=f['id'].toString();return DataRow(cells:[DataCell(Text(f['name']??'')),DataCell(Text(f['phone']??'-')),DataCell(Chip(label:Text(f['status']==1?'已通过':f['status']==2?'已驳回':'待审核',style:const TextStyle(fontSize:12)),color:WidgetStatePropertyAll(f['status']==1?Colors.green.shade50:f['status']==2?Colors.red.shade50:Colors.orange.shade50))),DataCell(Text(f['created_at']??'-')),DataCell(f['status']==0?Row(mainAxisSize:MainAxisSize.min,children:[ElevatedButton(onPressed:()=>c.verify(id),style:ElevatedButton.styleFrom(padding:const EdgeInsets.symmetric(horizontal:8)),child:const Text('通过')),const SizedBox(width:4),ElevatedButton(onPressed:()=>c.reject(id),style:ElevatedButton.styleFrom(padding:const EdgeInsets.symmetric(horizontal:8),backgroundColor:Colors.red),child:const Text('驳回'))]):const Text('-'))]);
        }).toList());
      })),
    ]);
  }
}
