// main.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pengukuran Volume Tangki',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ===================== MODELS =====================
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

// ===================== DATABASE SERVICE =====================
class DatabaseService {
  static Future<List<Tank>> getTanks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('tanks');
    if (data == null) return [];
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((e) => Tank.fromJson(e)).toList();
  }

  static Future<void> saveTank(Tank tank) async {
    final tanks = await getTanks();
    if (tank.id == null) {
      tank.id = DateTime.now().millisecondsSinceEpoch;
      tanks.add(tank);
    } else {
      final index = tanks.indexWhere((t) => t.id == tank.id);
      if (index >= 0) tanks[index] = tank;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tanks', json.encode(tanks.map((e) => e.toJson()).toList()));
  }

  static Future<void> deleteTank(int id) async {
    final tanks = await getTanks();
    tanks.removeWhere((t) => t.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tanks', json.encode(tanks.map((e) => e.toJson()).toList()));
  }

  static Future<List<CalibrationEntry>> getCalibration(int tankId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('calibration_$tankId');
    if (data == null) return [];
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((e) => CalibrationEntry.fromJson(e)).toList();
  }

  static Future<void> saveCalibration(int tankId, List<CalibrationEntry> calibration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calibration_$tankId', json.encode(calibration.map((e) => e.toJson()).toList()));
  }

  static Future<List<FractionEntry>> getFraction(int tankId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('fraction_$tankId');
    if (data == null) return [];
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((e) => FractionEntry.fromJson(e)).toList();
  }

  static Future<void> saveFraction(int tankId, List<FractionEntry> fraction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fraction_$tankId', json.encode(fraction.map((e) => e.toJson()).toList()));
  }
}

// ===================== CALCULATOR SERVICE =====================
class CalculatorService {
  static Map<String, dynamic> calculateVolume(
    double sounding,
    double mejaUkur,
    List<CalibrationEntry> calibration,
    List<FractionEntry> fraction,
  ) {
    final tinggiCairan = (sounding - mejaUkur).toInt();
    final meter = tinggiCairan ~/ 1000;
    final cm = (tinggiCairan % 1000) ~/ 10;
    final mm = tinggiCairan % 10;

    final calEntry = calibration.firstWhere(
      (c) => c.meter == meter && c.cm == cm,
      orElse: () => CalibrationEntry(meter: 0, cm: 0, volume: 0),
    );
    final volumeCm = calEntry.volume;

    final tinggiCairanMeter = tinggiCairan / 1000.0;
    
    final fracEntry = fraction.firstWhere(
      (f) => f.mm == mm && 
             tinggiCairanMeter >= f.heightFrom && 
             tinggiCairanMeter <= f.heightTo,
      orElse: () => FractionEntry(
        cincin: '',
        heightFrom: 0,
        heightTo: 0,
        mm: 0,
        volume: 0,
      ),
    );
    final volumeMm = fracEntry.volume;

    final vt = volumeCm + volumeMm;

    return {
      'tinggiCairan': tinggiCairan,
      'meter': meter,
      'cm': cm,
      'mm': mm,
      'volumeCm': volumeCm,
      'volumeMm': volumeMm,
      'vt': vt,
    };
  }

  static double applyTempCorrection(double vt, double tempDalam, double tempRef, double koef) {
    final deltaT = tempDalam - tempRef;
    final correctionFactor = 1 + (deltaT * koef);
    return vt * correctionFactor;
  }

  static double calculateVCF(double temp, double density) {
    final baseVCF = 1.0;
    final tempCorrection = (15 - temp) * 0.0007;
    final densityCorrection = (density - 0.85) * 0.5;
    return baseVCF + tempCorrection + densityCorrection;
  }
}

// ===================== HOME PAGE =====================
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Tank> tanks = [];

  @override
  void initState() {
    super.initState();
    loadTanks();
  }

  Future<void> loadTanks() async {
    final data = await DatabaseService.getTanks();
    setState(() {
      tanks = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengukuran Volume Tangki'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Pilih tangki untuk memulai pengukuran',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            Expanded(
              child: tanks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.water_drop_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Belum ada tangki', style: TextStyle(color: Colors.grey)),
                          SizedBox(height: 8),
                          Text('Tambahkan tangki di menu Setup', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tanks.length,
                      itemBuilder: (context, index) {
                        final tank = tanks[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(Icons.water_drop, color: Colors.blue),
                            ),
                            title: Text(tank.name, style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tank.owner),
                                Text('Kapasitas: ${tank.capacity.toStringAsFixed(0)} L',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            trailing: Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MeasurementPage(tank: tank),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SetupPage()),
          );
          loadTanks();
        },
        icon: Icon(Icons.settings),
        label: Text('Setup'),
      ),
    );
  }
}

// ===================== MEASUREMENT PAGE =====================
class MeasurementPage extends StatefulWidget {
  final Tank tank;
  MeasurementPage({required this.tank});

  @override
  _MeasurementPageState createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> {
  final _formKey = GlobalKey<FormState>();
  final soundingController = TextEditingController();
  final mejaUkurController = TextEditingController();
  final tempDalamController = TextEditingController();
  final tempLuarController = TextEditingController();
  final densityController = TextEditingController();

  Future<void> calculate() async {
    if (!_formKey.currentState!.validate()) return;

    final calibration = await DatabaseService.getCalibration(widget.tank.id!);
    final fraction = await DatabaseService.getFraction(widget.tank.id!);

    if (calibration.isEmpty || fraction.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tabel kalibrasi atau fraksi belum diisi!')),
      );
      return;
    }

    final volResult = CalculatorService.calculateVolume(
      double.parse(soundingController.text),
      double.parse(mejaUkurController.text),
      calibration,
      fraction,
    );

    final vObs = CalculatorService.applyTempCorrection(
      volResult['vt'],
      double.parse(tempDalamController.text),
      widget.tank.tempRef,
      widget.tank.koefEkspansi,
    );

    final vcf = CalculatorService.calculateVCF(
      double.parse(tempDalamController.text),
      double.parse(densityController.text),
    );

    final v15 = vObs * vcf;
    final d15 = double.parse(densityController.text) / vcf;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          result: {
            ...volResult,
            'vObs': vObs,
            'vcf': vcf,
            'v15': v15,
            'd15': d15,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tank.name),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: soundingController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Sounding (mm)',
                        border: OutlineInputBorder(),
                        hintText: '0',
                      ),
                      validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: mejaUkurController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Meja Ukur (mm)',
                        border: OutlineInputBorder(),
                        hintText: '0',
                      ),
                      validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: tempDalamController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Temperatur Dalam (°C)',
                        border: OutlineInputBorder(),
                        hintText: '0',
                      ),
                      validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: tempLuarController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Temperatur Luar (°C)',
                        border: OutlineInputBorder(),
                        hintText: '0',
                      ),
                      validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: densityController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Density Observed',
                        border: OutlineInputBorder(),
                        hintText: '0.000',
                      ),
                      validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: calculate,
                      icon: Icon(Icons.calculate),
                      label: Text('Hitung Volume'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(16),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== RESULT PAGE =====================
class ResultPage extends StatelessWidget {
  final Map<String, dynamic> result;
  ResultPage({required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hasil Perhitungan'),
        backgroundColor: Colors.green,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.green.shade100],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tinggi Cairan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 8),
                      Text('${result['tinggiCairan']} mm', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                      Text('(${result['meter']}m ${result['cm']}cm ${result['mm']}mm)', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Volume', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 8),
                      _buildRow('Volume ${result['cm']}cm:', '${result['volumeCm'].toStringAsFixed(3)} L'),
                      _buildRow('Volume ${result['mm']}mm:', '${result['volumeMm'].toStringAsFixed(3)} L'),
                      Divider(),
                      _buildRow('VT:', '${result['vt'].toStringAsFixed(3)} L', bold: true),
                      _buildRow('V.OBS:', '${result['vObs'].toStringAsFixed(3)} L', bold: true),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Koreksi Standar (15°C)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 8),
                      _buildRow('VCF:', '${result['vcf'].toStringAsFixed(6)}'),
                      _buildRow('V.15:', '${result['v15'].toStringAsFixed(3)} L', bold: true, color: Colors.green),
                      _buildRow('D.15:', '${result['d15'].toStringAsFixed(4)}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}

// ===================== SETUP PAGE =====================
class SetupPage extends StatefulWidget {
  @override
  _SetupPageState createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Tank> tanks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadTanks();
  }

  Future<void> loadTanks() async {
    final data = await DatabaseService.getTanks();
    setState(() {
      tanks = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Tangki'),
            Tab(text: 'Tabel Kalibrasi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TankSetupTab(onChanged: loadTanks),
          CalibrationSetupTab(tanks: tanks),
        ],
      ),
    );
  }
}

// ===================== TANK SETUP TAB =====================
class TankSetupTab extends StatefulWidget {
  final VoidCallback onChanged;
  TankSetupTab({required this.onChanged});

  @override
  _TankSetupTabState createState() => _TankSetupTabState();
}

class _TankSetupTabState extends State<TankSetupTab> {
  List<Tank> tanks = [];
  final nameController = TextEditingController();
  final ownerController = TextEditingController();
  final locationController = TextEditingController();
  final capacityController = TextEditingController();
  final diameterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadTanks();
  }

  Future<void> loadTanks() async {
    final data = await DatabaseService.getTanks();
    setState(() {
      tanks = data;
    });
  }

  Future<void> saveTank() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nama tangki harus diisi!')),
      );
      return;
    }

    await DatabaseService.saveTank(Tank(
      name: nameController.text,
      owner: ownerController.text,
      location: locationController.text,
      capacity: double.tryParse(capacityController.text) ?? 0,
      diameter: double.tryParse(diameterController.text) ?? 0,
    ));

    nameController.clear();
    ownerController.clear();
    locationController.clear();
    capacityController.clear();
    diameterController.clear();

    loadTanks();
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tangki berhasil disimpan!')),
    );
  }

  Future<void> deleteTank(int id) async {
    await DatabaseService.deleteTank(id);
    loadTanks();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tambah Tangki Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Nama (e.g., Tangki II)', border: OutlineInputBorder()),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: ownerController,
                  decoration: InputDecoration(labelText: 'Pemilik', border: OutlineInputBorder()),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(labelText: 'Lokasi', border: OutlineInputBorder()),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Kapasitas (L)', border: OutlineInputBorder()),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: diameterController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Diameter (m)', border: OutlineInputBorder()),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: saveTank,
                  icon: Icon(Icons.save),
                  label: Text('Simpan Tangki'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Text('Daftar Tangki', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 8),
        ...tanks.map((tank) => Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(tank.name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(tank.owner),
          ),
        )).toList(),
      ],
    );
  }
}

// ===================== CALIBRATION SETUP TAB =====================
class CalibrationSetupTab extends StatefulWidget {
  final List<Tank> tanks;
  CalibrationSetupTab({required this.tanks});

  @override
  _CalibrationSetupTabState createState() => _CalibrationSetupTabState();
}

class _CalibrationSetupTabState extends State<CalibrationSetupTab> {
  Tank? selectedTank;
  List<CalibrationEntry> calibration = [];
  List<FractionEntry> fraction = [];
  final meterController = TextEditingController();
  final cmController = TextEditingController();
  final volController = TextEditingController();
  final cincinController = TextEditingController();
  final heightFromController = TextEditingController();
  final heightToController = TextEditingController();
  final mmController = TextEditingController();
  final fracVolController = TextEditingController();

  Future<void> loadData() async {
    if (selectedTank == null) return;
    final cal = await DatabaseService.getCalibration(selectedTank!.id!);
    final frac = await DatabaseService.getFraction(selectedTank!.id!);
    setState(() {
      calibration = cal;
      fraction = frac;
    });
  }

  Future<void> addCalibration() async {
    if (meterController.text.isEmpty || cmController.text.isEmpty || volController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua field harus diisi!')),
      );
      return;
    }

    calibration.add(CalibrationEntry(
      meter: int.parse(meterController.text),
      cm: int.parse(cmController.text),
      volume: double.parse(volController.text),
    ));

    await DatabaseService.saveCalibration(selectedTank!.id!, calibration);
    
    meterController.clear();
    cmController.clear();
    volController.clear();
    
    loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data kalibrasi ditambahkan!')),
    );
  }

  Future<void> addFraction() async {
    if (cincinController.text.isEmpty || 
        heightFromController.text.isEmpty || 
        heightToController.text.isEmpty ||
        mmController.text.isEmpty || 
        fracVolController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua field harus diisi!')),
      );
      return;
    }

    fraction.add(FractionEntry(
      cincin: cincinController.text,
      heightFrom: double.parse(heightFromController.text),
      heightTo: double.parse(heightToController.text),
      mm: int.parse(mmController.text),
      volume: double.parse(fracVolController.text),
    ));

    await DatabaseService.saveFraction(selectedTank!.id!, fraction);
    
    cincinController.clear();
    heightFromController.clear();
    heightToController.clear();
    mmController.clear();
    fracVolController.clear();
    
    loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data fraksi ditambahkan!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<Tank>(
          decoration: InputDecoration(
            labelText: 'Pilih Tangki',
            border: OutlineInputBorder(),
          ),
          value: selectedTank,
          items: widget.tanks.map((tank) => DropdownMenuItem(
            value: tank,
            child: Text(tank.name),
          )).toList(),
          onChanged: (tank) {
            setState(() {
              selectedTank = tank;
            });
            loadData();
          },
        ),
        if (selectedTank != null) ...[
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tabel Volume (per cm)', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: meterController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Meter', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: cmController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'CM', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: volController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Volume (L)', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: addCalibration,
                    icon: Icon(Icons.add, size: 18),
                    label: Text('Tambah'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 40),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: calibration.isEmpty
                        ? Center(child: Text('Belum ada data', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: calibration.length,
                            itemBuilder: (context, index) {
                              final cal = calibration[index];
                              return ListTile(
                                dense: true,
                                title: Text('${cal.meter}m ${cal.cm}cm'),
                                trailing: Text('${cal.volume} L'),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tabel Fraksi (1-10mm)', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  TextField(
                    controller: cincinController,
                    decoration: InputDecoration(
                      labelText: 'Cincin (I, II, III)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: heightFromController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Dari (m)',
                            border: OutlineInputBorder(),
                            isDense: true,
                            hintText: '0.050',
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: heightToController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Ke (m)',
                            border: OutlineInputBorder(),
                            isDense: true,
                            hintText: '0.400',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: mmController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'MM (1-10)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: fracVolController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Volume (L)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: addFraction,
                    icon: Icon(Icons.add, size: 18),
                    label: Text('Tambah'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 40),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: fraction.isEmpty
                        ? Center(child: Text('Belum ada data', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: fraction.length,
                            itemBuilder: (context, index) {
                              final frac = fraction[index];
                              return ListTile(
                                dense: true,
                                title: Text('${frac.cincin}: ${frac.heightFrom}m - ${frac.heightTo}m'),
                                subtitle: Text('${frac.mm}mm = ${frac.volume}L'),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
