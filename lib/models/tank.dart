class Tank {
  int? id;
  String name;
  String owner;
  String location;
  double capacity;
  double diameter;
  double tempRef;
  double koefEkspansi;

  Tank({
    this.id,
    required this.name,
    required this.owner,
    required this.location,
    required this.capacity,
    required this.diameter,
    this.tempRef = 32.0,
    this.koefEkspansi = 0.0000348,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'owner': owner,
    'location': location,
    'capacity': capacity,
    'diameter': diameter,
    'tempRef': tempRef,
    'koefEkspansi': koefEkspansi,
  };

  factory Tank.fromJson(Map<String, dynamic> json) => Tank(
    id: json['id'],
    name: json['name'],
    owner: json['owner'],
    location: json['location'],
    capacity: json['capacity'],
    diameter: json['diameter'],
    tempRef: json['tempRef'] ?? 32.0,
    koefEkspansi: json['koefEkspansi'] ?? 0.0000348,
  );
}

class CalibrationEntry {
  int meter;
  int cm;
  double volume;

  CalibrationEntry({required this.meter, required this.cm, required this.volume});

  Map<String, dynamic> toJson() => {'meter': meter, 'cm': cm, 'volume': volume};
  
  factory CalibrationEntry.fromJson(Map<String, dynamic> json) =>
      CalibrationEntry(meter: json['meter'], cm: json['cm'], volume: json['volume']);
}

class FractionEntry {
  String cincin;
  double heightFrom;
  double heightTo;
  int mm;
  double volume;

  FractionEntry({
    required this.cincin,
    required this.heightFrom,
    required this.heightTo,
    required this.mm,
    required this.volume,
  });

  Map<String, dynamic> toJson() => {
    'cincin': cincin,
    'heightFrom': heightFrom,
    'heightTo': heightTo,
    'mm': mm,
    'volume': volume,
  };
  
  factory FractionEntry.fromJson(Map<String, dynamic> json) => FractionEntry(
    cincin: json['cincin'],
    heightFrom: json['heightFrom'],
    heightTo: json['heightTo'],
    mm: json['mm'],
    volume: json['volume'],
  );
}