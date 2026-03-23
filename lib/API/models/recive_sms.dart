class ReceiveSmsResponse {
  final bool success;
  final String message;
  final int smsId;

  ReceiveSmsResponse({
    required this.success,
    required this.message,
    required this.smsId,
  });

  factory ReceiveSmsResponse.fromJson(Map<String, dynamic> json) {
    return ReceiveSmsResponse(
      success: json['success'],
      message: json['message'],
      smsId: json['sms_id'],
    );
  }
}
