class ExpenseModel {
  final String id;
  final String? fieldId;

  final String category;
  final String description;

  final double amount;
  final DateTime date;

  final String? supplier;
  final String? paymentMethod;

  final double? quantityValue;
  final String? quantityUnit;

  final int? recurringInterval;
  final String? recurringUnit;

  final String? receiptUrl;

  ExpenseModel({
    required this.id,
    this.fieldId,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    this.supplier,
    this.paymentMethod,
    this.quantityValue,
    this.quantityUnit,
    this.recurringInterval,
    this.recurringUnit,
    this.receiptUrl,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['_id'] ?? json['id'] ?? '',
      fieldId: json['field'] is Map ? json['field']['_id'] : json['field'],
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      supplier: json['supplier'],
      paymentMethod: json['paymentMethod'],
      quantityValue: json['quantity']?['value'] != null
          ? (json['quantity']['value']).toDouble()
          : null,
      quantityUnit: json['quantity']?['unit'],
      recurringInterval: json['recurring']?['interval'],
      recurringUnit: json['recurring']?['unit'],
      receiptUrl: json['receiptUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': fieldId,
      'category': category,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'supplier': supplier,
      'paymentMethod': paymentMethod,
      'quantity': quantityValue != null
          ? {
              'value': quantityValue,
              'unit': quantityUnit,
            }
          : null,
      'recurring': recurringInterval != null
          ? {
              'interval': recurringInterval,
              'unit': recurringUnit,
            }
          : null,
      'receiptUrl': receiptUrl,
    };
  }
}
