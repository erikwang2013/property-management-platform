/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../widgets/base_crud_controller.dart';

class VoteController extends BaseCrudController {
  final votes = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.vote;
  @override List<dynamic> get items => votes;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    votes.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}
