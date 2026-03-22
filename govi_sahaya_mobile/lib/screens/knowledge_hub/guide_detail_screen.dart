import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/guide_model.dart';

class GuideDetailScreen extends StatelessWidget {
  final GuideModel guide;

  const GuideDetailScreen({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [],
      ),
    );
  }
}
