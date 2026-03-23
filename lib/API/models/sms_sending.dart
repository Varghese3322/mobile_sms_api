class PendingSms {
  final int id;
  final int deviceId;
  final int sim;
  final String phone;
  final String message;
  final String status;
  final String createdAt;

  PendingSms({
    required this.id,
    required this.deviceId,
    required this.sim,
    required this.phone,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory PendingSms.fromJson(Map<String, dynamic> json) {
    return PendingSms(
      id: json['id'],
      deviceId: json['device_id'],
      sim: json['sim'],
      phone: json['phone'],
      message: json['message'],
      status: json['status'],
      createdAt: json['created_at'],
    );
  }
}
