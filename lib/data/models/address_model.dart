class AddressModel {
  final String id;
  final String name;
  final String fullAddress;
  final String phone;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.phone,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json, String id) {
    return AddressModel(
      id: id,
      name: json['name'] ?? '',
      fullAddress: json['fullAddress'] ?? '',
      phone: json['phone'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'fullAddress': fullAddress,
      'phone': phone,
      'isDefault': isDefault,
    };
  }
}
