import 'package:flutter/material.dart';
import '../models/tank.dart';
import '../models/calculation_history.dart';
import '../services/db.dart';
import '../utils/animations.dart';
import '../widgets/custom_widgets.dart';
import 'measure.dart';
import 'setup.dart';

class TankDetailPage extends StatefulWidget {
  final Tank tank;

  TankDetailPage({required this.tank});

  @override
  _TankDetailPageState createState() => _TankDetailPageState();
}

class _TankDetailPageState extends State<TankDetailPage> {
  List<CalculationHistory> recentHistory = [];
  int calibrationCount = 0;
  int fractionCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final histories = await DatabaseService.getHistoryByTank(widget.tank.id!);
    final calibrations = await DatabaseService.getCalibration(widget.tank.id!);
    final fractions = await DatabaseService.getFraction(widget.tank.id!);

    setState(() {
      recentHistory = histories.take(3).toList();
      calibrationCount = calibrations.length;
      fractionCount = fractions.length;
    });
  }

  Future<void> _deleteTank() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Tangki?'),
        content: Text('Semua data kalibrasi dan history untuk tangki ini akan terhapus. Tindakan ini tidak dapat dibatalkan.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deleteTank(widget.tank.id!);
      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh home page
        CustomSnackBar.show(
          context,
          message: 'Tangki berhasil dihapus',
          type: SnackBarType.success,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          // App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.blue.shade700,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.tank.name),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade700,
                      Colors.blue.shade500,
                    ],
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'tank_${widget.tank.id}',
                    child: Icon(
                      Icons.water_drop,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SetupPage(),
                    ),
                  );
                  if (result == true) {
                    _loadData(); // Refresh data
                  }
                },
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: _deleteTank,
                tooltip: 'Hapus',
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Info Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Tangki',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildInfoRow(Icons.business, 'Pemilik', widget.tank.owner),
                        _buildInfoRow(Icons.location_on, 'Lokasi', widget.tank.location),
                        _buildInfoRow(Icons.water, 'Kapasitas', '${widget.tank.capacity.toStringAsFixed(0)} L'),
                        _buildInfoRow(Icons.straighten, 'Diameter', '${widget.tank.diameter.toStringAsFixed(2)} m'),
                        _buildInfoRow(Icons.thermostat, 'Temp. Referensi', '${widget.tank.tempRef}°C'),
                        _buildInfoRow(Icons.science, 'Koef. Ekspansi', widget.tank.koefEkspansi.toStringAsExponential(6)),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Calibration Stats
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Kalibrasi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Tabel Volume',
                                '$calibrationCount',
                                Icons.table_chart,
                                Colors.blue,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Tabel Fraksi',
                                '$fractionCount',
                                Icons.grid_on,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Recent History
                if (recentHistory.isNotEmpty) ...[
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perhitungan Terakhir',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          ...recentHistory.map((history) => _buildHistoryItem(history)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        AppAnimations.createSlideRoute(
                          MeasurementPage(tank: widget.tank),
                        ),
                      );
                    },
                    icon: Icon(Icons.calculate, size: 24),
                    label: Text('Mulai Pengukuran'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.all(18),
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(CalculationHistory history) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: Colors.blue.shade700, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.getShortDate(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '${history.v15.toStringAsFixed(0)} L',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}