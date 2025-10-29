import 'package:flutter/material.dart';

class HomeTileItem {
  final String title;
  final String imageAsset;
  final Widget? trailing;

  const HomeTileItem({
    required this.title,
    required this.imageAsset,
    this.trailing,
  });
}
