class CalculationHistory {
  int? id;
  int tankId;
  String tankName;
  double sounding;
  double mejaUkur;
  double tempDalam;
  double tempLuar;
  double densityObserved;
  double vt;
  double vObs;
  double vcf;
  double v15;
  double d15;
  DateTime timestamp;
  String? notes;

  CalculationHistory({
    this.id,
    required this.tankId,
    required this.tankName,
    required this.sounding,
    required this.mejaUkur,
    required this.tempDalam,
    required this.tempLuar,
    required this.densityObserved,
    required this.vt,
    required this.vObs,
    required this.vcf,
    required this.v15,
    required this.d15,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tankId': tankId,
      'tankName': tankName,
      'sounding': sounding,
      'mejaUkur': mejaUkur,
      'tempDalam': tempDalam,
      'tempLuar': tempLuar,
      'densityObserved': densityObserved,
      'vt': vt,
      'vObs': vObs,
      'vcf': vcf,
      'v15': v15,
      'd15': d15,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  factory CalculationHistory.fromMap(Map<String, dynamic> map) {
    return CalculationHistory(
      id: map['id'],
      tankId: map['tankId'],
      tankName: map['tankName'],
      sounding: map['sounding'],
      mejaUkur: map['mejaUkur'],
      tempDalam: map['tempDalam'],
      tempLuar: map['tempLuar'],
      densityObserved: map['densityObserved'],
      vt: map['vt'],
      vObs: map['vObs'],
      vcf: map['vcf'],
      v15: map['v15'],
      d15: map['d15'],
      timestamp: DateTime.parse(map['timestamp']),
      notes: map['notes'],
    );
  }

  // Helper method untuk format tanggal
  String getFormattedDate() {
    return '${timestamp.day.toString().padLeft(2, '0')}/'
        '${timestamp.month.toString().padLeft(2, '0')}/'
        '${timestamp.year} '
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Helper method untuk short date
  String getShortDate() {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  // Helper method untuk time only
  String getTimeOnly() {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';
  }
}