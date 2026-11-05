class WalletModel {
  final String id;
  String name;
  String type;
  double balance;

  WalletModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
    };
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      balance: (json['balance'] as num).toDouble(),
    );
  }
}

