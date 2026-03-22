import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class ToolsGrid extends StatelessWidget {
  final List<ToolItem> tools;

  const ToolsGrid({
    super.key,
    required this.tools,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceEvenly,
      children: tools.map((tool) => _buildToolItem(context, tool)).toList(),
    );
  }

  Widget _buildToolItem(BuildContext context, ToolItem tool) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, tool.route),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: tool.color ?? AppTheme.primaryGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (tool.color ?? AppTheme.primaryGreen).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              tool.icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              tool.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                height: 1.2,
                color: AppTheme.textDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
