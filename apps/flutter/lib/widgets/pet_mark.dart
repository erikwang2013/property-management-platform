/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

/// 项目宠物「小筑」标记（favicon.svg 副本）
class PetMark extends StatelessWidget {
  final double size;
  const PetMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/favicon.svg', width: size, height: size);
}

/// 加载态：小筑标记呼吸动画（scale 0.90↔1.05，往返约 900ms）
class PetLoading extends StatefulWidget {
  final double size;
  const PetLoading({super.key, this.size = 48});

  @override
  State<PetLoading> createState() => _PetLoadingState();
}

class _PetLoadingState extends State<PetLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450), // 单程 450ms → 往返约 900ms
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(begin: 0.90, end: 1.05)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child:
            ScaleTransition(scale: _scale, child: PetMark(size: widget.size)),
      );
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
            Text(message ?? 'no_data'.tr,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      );
}
