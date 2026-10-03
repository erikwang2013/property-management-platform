/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 项目宠物「小筑」标记（favicon.svg 副本）
class PetMark extends StatelessWidget {
  final double size;
  const PetMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/favicon.svg', width: size, height: size);
}

/// 空态占位：小筑标记 + 文案
class PetEmpty extends StatelessWidget {
  final String? message;
  final double size;
  const PetEmpty({super.key, this.message, this.size = 56});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PetMark(size: size),
            const SizedBox(height: 12),
            Text(message ?? '暂无数据',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      );
}
