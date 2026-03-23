class DeviceDetails {
  final String androidId;
  final String deviceName;
  final String brand;
  final String model;
  final int userId;

  final String networkName0;
  final String simMobile0;
  final String dailyLimit0;
  final String remainingSms0;

  final String networkName1;
  final String simMobile1;
  final String dailyLimit1;
  final String remainingSms1;

  DeviceDetails({
    required this.androidId,
    required this.deviceName,
    required this.brand,
    required this.model,
    required this.userId,
    required this.networkName0,
    required this.simMobile0,
    required this.dailyLimit0,
    required this.remainingSms0,
    required this.networkName1,
    required this.simMobile1,
    required this.dailyLimit1,
    required this.remainingSms1,
  });

  factory DeviceDetails.fromJson(Map<String, dynamic> json) {
    return DeviceDetails(

      androidId: json['android_id'] ?? "",
      deviceName: json['device_name'] ?? "",
      brand: json['brand'] ?? "",
      model: json['model'] ?? "",
      userId: json['user_id'] ?? 0,

      networkName0: json['network_name0'] ?? "",
      simMobile0: json['sim_mobile0'] ?? "",
      dailyLimit0: json['daily_limit0']?.toString() ?? "0",
      remainingSms0: json['remaining_sms0']?.toString() ?? "0",

      networkName1: json['network_name1'] ?? "",
      simMobile1: json['sim_mobile1'] ?? "",
      dailyLimit1: json['daily_limit1']?.toString() ?? "0",
      remainingSms1: json['remaining_sms1']?.toString() ?? "0",
    );
  }
}
