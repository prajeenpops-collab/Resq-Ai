class ProtocolStep {
  final int stepNumber;
  final String title;
  final String description;
  final String actionType;
  final int etaSeconds;
  String status; // pending, in_progress, completed

  ProtocolStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.actionType,
    required this.etaSeconds,
    required this.status,
  });

  factory ProtocolStep.fromJson(Map<String, dynamic> json) {
    return ProtocolStep(
      stepNumber: json['stepNumber'] ?? 1,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      actionType: json['actionType'] ?? 'general',
      etaSeconds: json['etaSeconds'] ?? 60,
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
        'stepNumber': stepNumber,
        'title': title,
        'description': description,
        'actionType': actionType,
        'etaSeconds': etaSeconds,
        'status': status,
      };
}

class DispatchedUnit {
  final String unitId;
  final String type; // ambulance, fire, police, hospital
  final String unitClass;
  final String status;
  final int etaSeconds;
  final String driverName;
  final String contactPhone;

  DispatchedUnit({
    required this.unitId,
    required this.type,
    required this.unitClass,
    required this.status,
    required this.etaSeconds,
    required this.driverName,
    required this.contactPhone,
  });

  factory DispatchedUnit.fromJson(Map<String, dynamic> json) {
    return DispatchedUnit(
      unitId: json['unitId'] ?? 'RESQ-UNIT',
      type: json['type'] ?? 'ambulance',
      unitClass: json['unitClass'] ?? 'Emergency Unit',
      status: json['status'] ?? 'en_route',
      etaSeconds: json['etaSeconds'] ?? 300,
      driverName: json['driverName'] ?? 'Responder',
      contactPhone: json['contactPhone'] ?? '911',
    );
  }
}

class EmergencyProtocol {
  final String protocolId;
  final String title;
  final String category;
  final String severityTarget;
  final String icon;
  final String summary;
  final List<ProtocolStep> automatedSteps;
  final List<String> safetyChecklist;

  EmergencyProtocol({
    required this.protocolId,
    required this.title,
    required this.category,
    required this.severityTarget,
    required this.icon,
    required this.summary,
    required this.automatedSteps,
    required this.safetyChecklist,
  });

  factory EmergencyProtocol.fromJson(Map<String, dynamic> json) {
    var stepsRaw = json['automatedSteps'] as List? ?? [];
    List<ProtocolStep> steps = stepsRaw.map((s) => ProtocolStep.fromJson(s)).toList();

    var checklistRaw = json['safetyChecklist'] as List? ?? [];
    List<String> checklist = checklistRaw.map((c) => c.toString()).toList();

    return EmergencyProtocol(
      protocolId: json['protocolId'] ?? '',
      title: json['title'] ?? 'Emergency Protocol',
      category: json['category'] ?? 'medical',
      severityTarget: json['severityTarget'] ?? 'high',
      icon: json['icon'] ?? 'warning',
      summary: json['summary'] ?? '',
      automatedSteps: steps,
      safetyChecklist: checklist,
    );
  }
}

class ActiveProtocolExecution {
  final String reportId;
  final String protocolId;
  final String title;
  final String category;
  final String severity;
  final String status;
  int currentStepIndex;
  final int totalSteps;
  final List<ProtocolStep> automatedSteps;
  final List<DispatchedUnit> dispatchedUnits;
  final List<String> safetyChecklist;
  final bool contactsNotified;
  final bool emergencyBroadcastSent;
  final DateTime startedAt;

  ActiveProtocolExecution({
    required this.reportId,
    required this.protocolId,
    required this.title,
    required this.category,
    required this.severity,
    required this.status,
    required this.currentStepIndex,
    required this.totalSteps,
    required this.automatedSteps,
    required this.dispatchedUnits,
    required this.safetyChecklist,
    required this.contactsNotified,
    required this.emergencyBroadcastSent,
    required this.startedAt,
  });

  factory ActiveProtocolExecution.fromJson(Map<String, dynamic> json) {
    var stepsRaw = json['automatedSteps'] as List? ?? [];
    List<ProtocolStep> steps = stepsRaw.map((s) => ProtocolStep.fromJson(s)).toList();

    var unitsRaw = json['dispatchedUnits'] as List? ?? [];
    List<DispatchedUnit> units = unitsRaw.map((u) => DispatchedUnit.fromJson(u)).toList();

    var checklistRaw = json['safetyChecklist'] as List? ?? [];
    List<String> checklist = checklistRaw.map((c) => c.toString()).toList();

    return ActiveProtocolExecution(
      reportId: json['reportId'] ?? '',
      protocolId: json['protocolId'] ?? '',
      title: json['title'] ?? 'Active Protocol Execution',
      category: json['category'] ?? 'medical',
      severity: json['severity'] ?? 'high',
      status: json['status'] ?? 'executing',
      currentStepIndex: json['currentStepIndex'] ?? 1,
      totalSteps: json['totalSteps'] ?? steps.length,
      automatedSteps: steps,
      dispatchedUnits: units,
      safetyChecklist: checklist,
      contactsNotified: json['contactsNotified'] ?? true,
      emergencyBroadcastSent: json['emergencyBroadcastSent'] ?? true,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
