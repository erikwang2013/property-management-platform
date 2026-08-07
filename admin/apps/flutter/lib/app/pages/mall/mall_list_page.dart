/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/base_crud_controller.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class MallCategoryController extends BaseCrudController {
  final categories = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.mallCategory;
  @override bool get hasStatus => false;
  @override List<dynamic> get items => categories;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    categories.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}
class MallProductController extends BaseCrudController {
  final products = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.mallProduct;
  @override bool get hasStatus => false;
  @override List<dynamic> get items => products;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    products.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}
class MallOrderController extends GetxController {
  final api = ApiService();final orders=<Map<String,dynamic>>[].obs;final isLoading=false.obs;final total=0.obs;final page=1.obs;
  @override void onInit(){super.onInit();loadItems();}
  Future<void> loadItems({bool reset=false})async{if(reset)page.value=1;isLoading.value=true;try{final r=await api.get(ApiConfig.mallOrder,params:{'page':page.value,'limit':15});final d=r['data']as Map<String,dynamic>;orders.value=List<Map<String,dynamic>>.from(d['data']??[]);total.value=d['total']as int? ??0;}catch(_){}finally{isLoading.value=false;}}
  Future<void> ship(String hid,String company,String no)async{await api.put(ApiConfig.mallOrderShip(hid),data:{'express_company':company,'express_no':no});await loadItems();Get.snackbar('成功','已发货');}
  Future<void> refund(String hid,String reason)async{await api.post(ApiConfig.mallOrderRefund(hid),data:{'reason':reason});await loadItems();Get.snackbar('成功','已退款');}
  void nextPage(){if(page.value*15<total.value){page.value++;loadItems();}}
  void prevPage(){if(page.value>1){page.value--;loadItems();}}
}

class MallCategoryListPage extends GetView<MallCategoryController> {
  const MallCategoryListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if(!Get.isRegistered<MallCategoryController>())Get.put(MallCategoryController(),permanent:false);final c=controller;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Text('商品分类',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const Spacer(),ElevatedButton.icon(onPressed:()=>_catForm(context,c),icon:const Icon(Icons.add),label:const Text('新增分类'))]),const SizedBox(height:12),
      Expanded(child:Obx((){
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('名称')),DataColumn(label:Text('排序')),DataColumn(label:Text('状态')),DataColumn(label:Text('操作'))],rows:c.categories.map((x){final id=x['id'].toString();return DataRow(cells:[DataCell(Text(x['name']??'')),DataCell(Text('${x['sort']??0}')),DataCell(StatusChip(status:x['status']as int?)),DataCell(Row(mainAxisSize:MainAxisSize.min,children:[IconButton(icon:Icon(Icons.edit,size:18),onPressed:()=>_catForm(context,c,data:x)),IconButton(icon:Icon(Icons.delete,size:18,color:Colors.red),onPressed:()async{final p=await ConfirmDeleteDialog.show(context,itemName:x['name']??'');if(p!=null)c.deleteItem(id,p);})]))]);}).toList());
      })),
      Obx(()=>PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _catForm(BuildContext ctx,MallCategoryController c,{Map<String,dynamic>? data}){final n=TextEditingController(text:data?['name']??'');final s=TextEditingController(text:data?['sort']?.toString()??'');final isEdit=data!=null;showDialog(context:ctx,builder:(_)=>AlertDialog(title:Text(isEdit?'编辑分类':'新增分类'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'名称',isDense:true)),const SizedBox(height:12),TextField(controller:s,decoration:const InputDecoration(labelText:'排序',isDense:true))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(n.text.isEmpty)return;try{final d={'name':n.text.trim(),'sort':int.tryParse(s.text)??0};if (isEdit) { await c.updateItem(data['id'], d); }else{await c.api.post(ApiConfig.mallCategory,data:d);c.loadItems(reset:true);}if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)Get.snackbar('错误','操作失败:$e');}},child:Text(isEdit?'保存':'创建'))],));}
}

class MallProductListPage extends GetView<MallProductController> {
  const MallProductListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if(!Get.isRegistered<MallProductController>())Get.put(MallProductController(),permanent:false);final c=controller;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Text('商品管理',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const Spacer(),ElevatedButton.icon(onPressed:()=>_prodForm(context,c),icon:const Icon(Icons.add),label:const Text('新增商品'))]),const SizedBox(height:12),
      Expanded(child:Obx((){
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('商品名称')),DataColumn(label:Text('价格')),DataColumn(label:Text('库存')),DataColumn(label:Text('状态')),DataColumn(label:Text('操作'))],rows:c.products.map((p){final id=p['id'].toString();return DataRow(cells:[DataCell(Text(p['name']??'')),DataCell(Text('${p['price']??'-'}')),DataCell(Text('${p['stock']??0}')),DataCell(StatusChip(status:p['status']as int?)),DataCell(Row(mainAxisSize:MainAxisSize.min,children:[IconButton(icon:Icon(Icons.edit,size:18),onPressed:()=>_prodForm(context,c,data:p)),IconButton(icon:Icon(Icons.delete,size:18,color:Colors.red),onPressed:()async{final pwd=await ConfirmDeleteDialog.show(context,itemName:p['name']??'');if(pwd!=null)c.deleteItem(id,pwd);})]))]);}).toList());
      })),
      Obx(()=>PaginationRow(page:c.page.value,total:c.total.value,pageSize:c.limit.value,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _prodForm(BuildContext ctx,MallProductController c,{Map<String,dynamic>? data}){final n=TextEditingController(text:data?['name']??'');final pr=TextEditingController(text:data?['price']?.toString()??'');final stk=TextEditingController(text:data?['stock']?.toString()??'');final isEdit=data!=null;showDialog(context:ctx,builder:(_)=>AlertDialog(title:Text(isEdit?'编辑商品':'新增商品'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'商品名称',isDense:true)),const SizedBox(height:12),TextField(controller:pr,decoration:const InputDecoration(labelText:'价格',isDense:true)),const SizedBox(height:12),TextField(controller:stk,decoration:const InputDecoration(labelText:'库存',isDense:true))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(n.text.isEmpty)return;try{final d={'name':n.text.trim(),'price':double.tryParse(pr.text),'stock':int.tryParse(stk.text)};if (isEdit) { await c.updateItem(data['id'], d); }else{await c.api.post(ApiConfig.mallProduct,data:d);c.loadItems(reset:true);}if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)Get.snackbar('错误','操作失败:$e');}},child:Text(isEdit?'保存':'创建'))],));}
}

class MallOrderListPage extends GetView<MallOrderController> {
  const MallOrderListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if(!Get.isRegistered<MallOrderController>())Get.put(MallOrderController(),permanent:false);final c=controller;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('订单管理',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:12),
      Expanded(child:Obx((){
        if(c.isLoading.value)return const Center(child:CircularProgressIndicator());
        return DataTable(columns:const[DataColumn(label:Text('订单号')),DataColumn(label:Text('商品')),DataColumn(label:Text('金额')),DataColumn(label:Text('状态')),DataColumn(label:Text('时间')),DataColumn(label:Text('操作'))],rows:c.orders.map((o){final hid=o['id'].toString();return DataRow(cells:[DataCell(Text(o['order_no']??'-')),DataCell(Text(o['product_name']??'-')),DataCell(Text('${o['amount']??'-'}')),DataCell(StatusChip(status:o['status']as int?,labels:const{0:'待支付',1:'已支付',2:'已发货',3:'已完成',4:'已退款'})),DataCell(Text(o['created_at']??'-')),DataCell(Row(mainAxisSize:MainAxisSize.min,children:[
          if((o['status']as int? ??0)==1)IconButton(icon:const Icon(Icons.local_shipping,size:18,color:Colors.blue),tooltip:'发货',onPressed:()=>_shipDialog(context,c,hid)),
          if((o['status']as int? ??0)==1)IconButton(icon:const Icon(Icons.undo,size:18,color:Colors.orange),tooltip:'退款',onPressed:()=>_refundDialog(context,c,hid)),
        ]))]);}).toList());
      })),
      Obx(()=>PaginationRow(page:c.page.value,total:c.total.value,pageSize:15,onPrev:c.prevPage,onNext:c.nextPage)),
    ]);
  }
  void _shipDialog(BuildContext ctx,MallOrderController c,String hid){final cp=TextEditingController();final no=TextEditingController();showDialog(context:ctx,builder:(_)=>AlertDialog(title:const Text('发货'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:cp,decoration:const InputDecoration(labelText:'快递公司',isDense:true)),const SizedBox(height:12),TextField(controller:no,decoration:const InputDecoration(labelText:'快递单号',isDense:true))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(cp.text.isEmpty||no.text.isEmpty)return;await c.ship(hid,cp.text.trim(),no.text.trim());if(ctx.mounted)Navigator.pop(ctx);},child:const Text('确认发货'))],));}
  void _refundDialog(BuildContext ctx,MallOrderController c,String hid){final reason=TextEditingController();showDialog(context:ctx,builder:(_)=>AlertDialog(title:const Text('退款'),content:TextField(controller:reason,decoration:const InputDecoration(labelText:'退款原因',isDense:true)),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),ElevatedButton(onPressed:()async{if(reason.text.isEmpty)return;await c.refund(hid,reason.text.trim());if(ctx.mounted)Navigator.pop(ctx);},style:ElevatedButton.styleFrom(backgroundColor:Colors.orange),child:const Text('确认退款'))],));}
}
