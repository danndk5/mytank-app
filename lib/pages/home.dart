import 'package:flutter/material.dart';
import '../models/tank.dart';
import '../services/db.dart';
import 'measure.dart';
import 'setup.dart';

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
        title: Text('MyTank'),
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