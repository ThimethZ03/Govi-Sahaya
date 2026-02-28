import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class ToolsGrid extends StatelessWidget {
  final List<ToolItem> tools;

  const ToolsGrid({super.key, required this.tools});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 20,
      crossAxisSpacing: 8,
      children: tools.map((tool) => _buildToolItem(context, tool)).toList(),
    );
  }

  Widget _buildToolItem(BuildContext context, ToolItem tool) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, tool.route),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tool.color ?? AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (tool.color ?? AppTheme.primaryGreen)
                          .withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(tool.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 7),
              Text(
                tool.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ToolItem {
  final IconData icon;
  final String label;
  final String route;
  final Color? color;

  ToolItem({
    required this.icon,
    required this.label,
    required this.route,
    this.color,
  });
}
