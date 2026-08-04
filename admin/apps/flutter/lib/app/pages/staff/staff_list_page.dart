/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'staff_controller.dart';

class StaffListPage extends GetView<StaffController> {
  const StaffListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<StaffController>()) Get.put(StaffController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('员工管理', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)), const Spacer(),
        ElevatedButton.icon(onPressed:()=>_form(context,c), icon:const Icon(Icons.add), label:const Text('新增员工')),
        if(c.selectedIds.isNotEmpty)...[const SizedBox(width:8),
          ElevatedButton.icon(onPressed:()async{final pwd=await ConfirmDeleteDialog.show(context,itemName:'员工',count:c.selectedIds.length);if(pwd!=null)c.batchDelete(pwd);},icon:const Icon(Icons.delete,color:Colors.red),label:Text('删除(${c.selectedIds.length})'),style:ElevatedButton.styleFrom(foregroundColor:Colors.red)),
          const SizedBox(width:8),PopupMenuButton<String>(onSelected:(v){if(v=='enable')c.batchToggleStatus(1);if(v=='disable')c.batchToggleStatus(0);},itemBuilder:(_)=>const[PopupMenuItem(value:'enable',child:Text('批量启用')),PopupMenuItem(value:'disable',child:Text('批量禁用'))]),
        ],
      ]),const SizedBox(height:12),
      Row(children:[
        SizedBox(width:250,child:TextField(decoration:const InputDecoration(hintText:'搜索姓名/工号',prefixIcon:Icon(Icons.search),isDense:true),onSubmitted:(v)=>c.search(v))),
        const SizedBox(width:12),ChoiceChip(label:Text('全部'),selected:c.statusFilter.value==null,onSelected:(_)=>c.filterByStatus(null)),const SizedBox(width:4),ChoiceChip(label:Text('在职'),selected:c.statusFilter.value==1,onSelected:(_)=>c.filterByStatus(1)),const SizedBox(width:4),ChoiceChip(label:Text('离职'),selected:c.statusFilter.value==0,onSelected:(_)=>c.filterByStatus(0)),
      ]),const SizedBox(height:12),
      Expanded(child: Obx(() {
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:[DataColumn(label:Checkbox(value:c.selectedIds.length==c.staff.length&&c.staff.isNotEmpty,onChanged:(_)=>c.toggleSelectAll())),const DataColumn(label:Text('姓名')),const DataColumn(label:Text('工号')),const DataColumn(label:Text('部门')),const DataColumn(label:Text('手机号')),const DataColumn(label:Text('状态')),const DataColumn(label:Text('操作'))],
          rows:c.staff.map((s){final id=s['id'].toString();return DataRow(selected:c.selectedIds.contains(id),onSelectChanged:(_)=>c.toggleSelect(id),cells:[
            DataCell(Checkbox(value:c.selectedIds.contains(id),onChanged:(_)=>c.toggleSelect(id))),
            DataCell(Text(s['name']??'')),DataCell(Text(s['employee_no']??'-')),DataCell(Text(s['department']??'-')),DataCell(Text(s['phone']??'-')),
            DataCell(StatusChip(status:s['status']as int?,labels:const{0:'离职',1:'在职'})),
            DataCell(Row(mainAxisSize:MainAxisSize.min,children:[IconButton(icon:Icon(Icons.edit,size:18),onPressed:()=>_form(context,c,data:s)),IconButton(icon:Icon(Icons.delete,size:18,color:Colors.red),onPressed:()async{final p=await ConfirmDeleteDialog.show(context,itemName:s['name']??'');if(p!=null)c.deleteItem(id,p);})])),
          ]));}).toList());
      })),
      Obx(() => PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _form(BuildContext ctx,StaffController c,{Map<String,dynamic>? data}) {
    final name=TextEditingController(text:data?['name']??''),no=TextEditingController(text:data?['employee_no']??''),dept=TextEditingController(text:data?['department']??''),phone=TextEditingController(text:data?['phone']??'');
    int st=data?['status']as int? ?? 1;final isEdit=data!=null;
    showDialog(context:ctx,builder:(_)=>StatefulBuilder(builder:(_,sb)=>AlertDialog(title:Text(isEdit?'编辑员工':'新增员工'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:name,decoration:const InputDecoration(labelText:'姓名',isDense:true)),const SizedBox(height:12),TextField(controller:no,decoration:const InputDecoration(labelText:'工号',isDense:true)),const SizedBox(height:12),TextField(controller:dept,decoration:const InputDecoration(labelText:'部门',isDense:true)),const SizedBox(height:12),TextField(controller:phone,decoration:const InputDecoration(labelText:'手机号',isDense:true)),const SizedBox(height:12),
      DropdownButtonFormField<int>(value:st,decoration:const InputDecoration(labelText:'状态',isDense:true),items:const[DropdownMenuItem(value:1,child:Text('在职')),DropdownMenuItem(value:0,child:Text('离职'))],onChanged:(v)=>sb(()=>st=v??1)),
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(name.text.isEmpty)return;try{final d={'name':name.text.trim(),'employee_no':no.text.trim(),'department':dept.text.trim(),'phone':phone.text.trim(),'status':st};if(isEdit)await c.updateItem(data!['id'],d);else{await c.api.post(ApiConfig.staff,data:d);c.loadItems(reset:true);}if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)Get.snackbar('错误','操作失败:$e');}},child:Text(isEdit?'保存':'创建'))],)));
  }
}
