class EmergencyReport {
  final String reportId;
  final String category;
  final String severity;
  final String aiSummary;
  final String firstAidGuidance;
  final String status;
  final DateTime createdAt;

  EmergencyReport({
    required this.reportId,
    required this.category,
    required this.severity,
    required this.aiSummary,
    required this.firstAidGuidance,
    required this.status,
    required this.createdAt,
  });

  factory EmergencyReport.fromJson(Map<String, dynamic> json) {
    return EmergencyReport(
      reportId: json['reportId'] ?? '',
      category: json['category'] ?? 'other',
      severity: json['severity'] ?? 'low',
      aiSummary: json['aiSummary'] ?? '',
      firstAidGuidance: json['firstAidGuidance'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
