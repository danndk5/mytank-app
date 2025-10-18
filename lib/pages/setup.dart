import 'package:flutter/material.dart';
import '../models/tank.dart';
import '../services/db.dart';

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
                  decoration: InputDecoration(labelText: 'Nama', border: OutlineInputBorder()),
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
                  style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Semua field harus diisi!')));
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data kalibrasi ditambahkan!')));
  }

  Future<void> addFraction() async {
    if (cincinController.text.isEmpty || heightFromController.text.isEmpty || 
        heightToController.text.isEmpty || mmController.text.isEmpty || fracVolController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Semua field harus diisi!')));
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data fraksi ditambahkan!')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<Tank>(
          decoration: InputDecoration(labelText: 'Pilih Tangki', border: OutlineInputBorder()),
          value: selectedTank,
          items: widget.tanks.map((tank) => DropdownMenuItem(value: tank, child: Text(tank.name))).toList(),
          onChanged: (tank) {
            setState(() => selectedTank = tank);
            loadData();
          },
        ),
        if (selectedTank != null) ...[
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Tabel Volume (per cm)', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: meterController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'M', border: OutlineInputBorder(), isDense: true))),
                      SizedBox(width: 8),
                      Expanded(child: TextField(controller: cmController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'CM', border: OutlineInputBorder(), isDense: true))),
                      SizedBox(width: 8),
                      Expanded(flex: 2, child: TextField(controller: volController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Vol', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(onPressed: addCalibration, child: Text('Tambah'), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 40))),
                  SizedBox(height: 12),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: calibration.isEmpty
                        ? Center(child: Text('Belum ada data', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: calibration.length,
                            itemBuilder: (context, index) {
                              final cal = calibration[index];
                              return ListTile(dense: true, title: Text('${cal.meter}m ${cal.cm}cm'), trailing: Text('${cal.volume} L'));
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
                children: [
                  Text('Tabel Fraksi (1-10mm)', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  TextField(controller: cincinController, decoration: InputDecoration(labelText: 'Cincin', border: OutlineInputBorder(), isDense: true)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: heightFromController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Dari (m)', border: OutlineInputBorder(), isDense: true))),
                      SizedBox(width: 8),
                      Expanded(child: TextField(controller: heightToController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Ke (m)', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: mmController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'MM', border: OutlineInputBorder(), isDense: true))),
                      SizedBox(width: 8),
                      Expanded(flex: 2, child: TextField(controller: fracVolController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Vol', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(onPressed: addFraction, child: Text('Tambah'), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 40))),
                  SizedBox(height: 12),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: fraction.isEmpty
                        ? Center(child: Text('Belum ada data', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: fraction.length,
                            itemBuilder: (context, index) {
                              final frac = fraction[index];
                              return ListTile(dense: true, title: Text('${frac.cincin}: ${frac.heightFrom}m - ${frac.heightTo}m'), subtitle: Text('${frac.mm}mm = ${frac.volume}L'));
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
