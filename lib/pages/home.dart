import 'package:flutter/material.dart';
import '../models/tank.dart';
import '../models/calculation_history.dart';
import '../services/db.dart';
import '../utils/animations.dart';
import '../widgets/custom_widgets.dart';
import 'measure.dart';
import 'setup.dart';
import 'history.dart';
import 'calculator.dart';
import 'about.dart';
import 'tank_detail.dart';
import 'settings.dart';
import 'analytics.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Tank> tanks = [];
  int historyCount = 0;
  int totalTanks = 0;
  CalculationHistory? latestHistory;

  @override
  void initState() {
    super.initState();
    loadTanks();
    loadHistoryCount();
    loadStats();
  }

  Future<void> loadStats() async {
    final tanks = await DatabaseService.getTanks();
    final histories = await DatabaseService.getAllHistory();
    
    setState(() {
      totalTanks = tanks.length;
      if (histories.isNotEmpty) {
        latestHistory = histories.first;
      }
    });
  }

  Future<void> loadTanks() async {
    final data = await DatabaseService.getTanks();
    setState(() {
      tanks = data;
    });
  }

  Future<void> loadHistoryCount() async {
    final count = await DatabaseService.getHistoryCount();
    setState(() {
      historyCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MyTank'),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Analytics Button - BARU
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnalyticsPage()),
              );
            },
            tooltip: 'Analytics',
          ),
          
          // Settings Button - BARU
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
            tooltip: 'Pengaturan',
          ),
          // About Button
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              Navigator.push(
                context,
                AppAnimations.createFadeRoute(AboutPage()),
              );
            },
            tooltip: 'Tentang',
          ),
          // Calculator Button
          IconButton(
            icon: Icon(Icons.calculate),
            onPressed: () {
              Navigator.push(
                context,
                AppAnimations.createSlideRoute(CalculatorPage()),
              );
            },
            tooltip: 'Kalkulator Selisih',
          ),
          // History Button with Badge
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.history),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    AppAnimations.createSlideRoute(HistoryPage()),
                  );
                  // Refresh count after returning from history
                  loadHistoryCount();
                },
                tooltip: 'History Perhitungan',
              ),
              if (historyCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      historyCount > 99 ? '99+' : '$historyCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ParticleBackground(
        particleColor: Colors.blue.withOpacity(0.05),
        child: GradientBackground(
          child: Column(
            children: [
              // Dashboard Stats
              AnimatedCard(
                delay: Duration(milliseconds: 100),
                child: Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.water_drop,
                            '$totalTanks',
                            'Tangki',
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _buildStatItem(
                            Icons.history,
                            '$historyCount',
                            'History',
                          ),
                        ],
                      ),
                      if (latestHistory != null) ...[
                        SizedBox(height: 12),
                        Divider(color: Colors.white.withOpacity(0.3)),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 16, color: Colors.white70),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Terakhir: ${latestHistory!.tankName} - ${latestHistory!.getShortDate()}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Info Card
              AnimatedCard(
                delay: Duration(milliseconds: 200),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tap tangki untuk detail, tekan lama untuk pengukuran cepat',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Tank List
              Expanded(
                child: tanks.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.water_drop_outlined,
                        title: 'Belum ada tangki',
                        message: 'Tambahkan tangki pertama Anda di menu Setup',
                        actionLabel: 'Tambah Tangki',
                        onAction: () async {
                          await Navigator.push(
                            context,
                            AppAnimations.createSlideRoute(
                              SetupPage(),
                              direction: AxisDirection.up,
                            ),
                          );
                          loadTanks();
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await loadTanks();
                          await loadHistoryCount();
                        },
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          physics: BouncingScrollPhysics(),
                          itemCount: tanks.length,
                          itemBuilder: (context, index) {
                            final tank = tanks[index];
                            return AnimatedCard(
                              delay: Duration(milliseconds: 300 + (index * 100)),
                              child: Card(
                                margin: EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  // TAP - Ke Tank Detail - UPDATED
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      AppAnimations.createSlideRoute(
                                        TankDetailPage(tank: tank),
                                      ),
                                    );
                                    if (result == true) {
                                      loadTanks(); // Refresh jika ada perubahan
                                      loadHistoryCount();
                                    }
                                  },
                                  // LONG PRESS - Langsung ke Measurement - BARU
                                  onLongPress: () async {
                                    await Navigator.push(
                                      context,
                                      AppAnimations.createSlideRoute(
                                        MeasurementPage(tank: tank),
                                      ),
                                    );
                                    loadHistoryCount();
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Icon
                                        Hero(
                                          tag: 'tank_${tank.id}',
                                          child: CircleAvatar(
                                            radius: 28,
                                            backgroundColor: Colors.blue.shade100,
                                            child: Icon(
                                              Icons.water_drop,
                                              color: Colors.blue.shade700,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        // Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tank.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                tank.owner,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.straighten,
                                                    size: 14,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Kapasitas: ${tank.capacity.toStringAsFixed(0)} L',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Arrow
                                        Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey.shade400,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            AppAnimations.createSlideRoute(SetupPage(), direction: AxisDirection.up),
          );
          loadTanks();
        },
        icon: Icon(Icons.settings),
        label: Text('Setup'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}