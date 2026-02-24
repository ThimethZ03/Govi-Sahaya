class ExpenseModel {
  final String id;
  final String fieldId;
  final String category;
  final String description;
  final double estimatedCost;
  final double spentAmount;
  final DateTime date;

  ExpenseModel({
    required this.id,
    required this.fieldId,
    required this.category,
    required this.description,
    required this.estimatedCost,
    required this.spentAmount,
    required this.date,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? '',
      fieldId: json['field_id'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      estimatedCost: (json['estimated_cost'] ?? 0.0).toDouble(),
      spentAmount: (json['spent_amount'] ?? 0.0).toDouble(),
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field_id': fieldId,
      'category': category,
      'description': description,
      'estimated_cost': estimatedCost,
      'spent_amount': spentAmount,
      'date': date.toIso8601String(),
    };
  }
}

class FieldBudget {
  final String id;
  final String name;
  final double totalEstimated;
  final double totalSpent;
  final List<ExpenseModel> expenses;

  FieldBudget({
    required this.id,
    required this.name,
    required this.totalEstimated,
    required this.totalSpent,
    required this.expenses,
  });

  double get balance => totalEstimated - totalSpent;

  double get percentageUsed =>
      totalEstimated > 0 ? (totalSpent / totalEstimated) * 100 : 0;
}
