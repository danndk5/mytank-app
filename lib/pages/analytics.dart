import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/tank.dart';
import '../models/calculation_history.dart';
import '../services/db.dart';
import '../utils/animations.dart';
import '../widgets/custom_widgets.dart';

class AnalyticsPage extends StatefulWidget {
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Tank> tanks = [];
  List<CalculationHistory> histories = [];
  bool isLoading = true;

  // Data untuk charts
  Map<String, double> volumePerTank = {};
  Map<String, int> distributionPerOwner = {};
  List<FlSpot> trendData = [];
  Map<DateTime, int> calendarData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    tanks = await DatabaseService.getTanks();
    histories = await DatabaseService.getAllHistory();

    _processData();

    setState(() {
      isLoading = false;
    });
  }

  void _processData() {
    // 1. Volume per Tangki (ambil history terakhir per tangki)
    volumePerTank.clear();
    for (var tank in tanks) {
      final tankHistories = histories.where((h) => h.tankId == tank.id).toList();
      if (tankHistories.isNotEmpty) {
        volumePerTank[tank.name] = tankHistories.first.v15;
      } else {
        volumePerTank[tank.name] = 0;
      }
    }

    // 2. Distribusi per Pemilik
    distributionPerOwner.clear();
    for (var tank in tanks) {
      distributionPerOwner[tank.owner] = (distributionPerOwner[tank.owner] ?? 0) + 1;
    }

    // 3. Trend Penggunaan (30 hari terakhir)
    trendData.clear();
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(Duration(days: 30));
    
    final recentHistories = histories.where((h) => h.timestamp.isAfter(thirtyDaysAgo)).toList();
    recentHistories.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (int i = 0; i < recentHistories.length; i++) {
      final daysSince = recentHistories[i].timestamp.difference(thirtyDaysAgo).inDays.toDouble();
      trendData.add(FlSpot(daysSince, recentHistories[i].v15));
    }

    // 4. Calendar Activity
    calendarData.clear();
    for (var history in histories) {
      final date = DateTime(history.timestamp.year, history.timestamp.month, history.timestamp.day);
      calendarData[date] = (calendarData[date] ?? 0) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics Dashboard'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.bar_chart), text: 'Volume'),
            Tab(icon: Icon(Icons.show_chart), text: 'Trend'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Distribusi'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Kalender'),
          ],
          indicatorColor: Colors.white,
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : GradientBackground(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVolumeChart(),
                  _buildTrendChart(),
                  _buildDistributionChart(),
                  _buildCalendarView(),
                ],
              ),
            ),
    );
  }

  // ============================================================================
  // TAB 1: Bar Chart - Volume per Tangki
  // ============================================================================
  Widget _buildVolumeChart() {
    if (volumePerTank.isEmpty) {
      return _buildEmptyState('Belum ada data volume');
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Volume Terakhir per Tangki',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Menampilkan volume perhitungan terakhir',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
          
          AnimatedCard(
            delay: Duration(milliseconds: 100),
            child: Container(
              height: 400,
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
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: volumePerTank.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.black,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${volumePerTank.keys.elementAt(groupIndex)}\n${rod.toY.toStringAsFixed(0)} L',
                          TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < volumePerTank.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                volumePerTank.keys.elementAt(value.toInt()),
                                style: TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}L',
                            style: TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: volumePerTank.entries.map((entry) {
                    final index = volumePerTank.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: Colors.blue.shade700,
                          width: 30,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade400, Colors.blue.shade700],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Tangki',
                  '${volumePerTank.length}',
                  Icons.water_drop,
                  Colors.black,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Avg Volume',
                  '${(volumePerTank.values.reduce((a, b) => a + b) / volumePerTank.length).toStringAsFixed(0)} L',
                  Icons.analytics,
                  Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: Line Chart - Trend Penggunaan
  // ============================================================================
  Widget _buildTrendChart() {
    if (trendData.isEmpty) {
      return _buildEmptyState('Belum ada data trend');
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Penggunaan 30 Hari',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Grafik volume perhitungan dalam 30 hari terakhir',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
          
          AnimatedCard(
            delay: Duration(milliseconds: 100),
            child: Container(
              height: 350,
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
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.green.shade700,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            'Day ${spot.x.toInt()}\n${spot.y.toStringAsFixed(0)} L',
                            TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'D${value.toInt()}',
                              style: TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}L',
                            style: TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trendData,
                      isCurved: true,
                      color: Colors.green.shade700,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.green.shade700,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade700.withOpacity(0.3),
                            Colors.green.shade700.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Perhitungan',
                  '${trendData.length}',
                  Icons.calculate,
                  Colors.black,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Periode',
                  '30 Hari',
                  Icons.date_range,
                  Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 3: Pie Chart - Distribusi per Pemilik
  // ============================================================================
  Widget _buildDistributionChart() {
    if (distributionPerOwner.isEmpty) {
      return _buildEmptyState('Belum ada data distribusi');
    }

    final total = distributionPerOwner.values.reduce((a, b) => a + b);
    final colors = [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.orange.shade700,
      Colors.purple.shade700,
      Colors.red.shade700,
      Colors.teal.shade700,
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribusi Tangki per Pemilik',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Persentase kepemilikan tangki',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
          
          AnimatedCard(
            delay: Duration(milliseconds: 100),
            child: Container(
              height: 350,
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
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: distributionPerOwner.entries.map((entry) {
                    final index = distributionPerOwner.keys.toList().indexOf(entry.key);
                    final percentage = (entry.value / total * 100);
                    
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${percentage.toStringAsFixed(1)}%',
                      radius: 100,
                      titleStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      color: colors[index % colors.length],
                    );
                  }).toList(),
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Handle touch
                    },
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Legend
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tangki',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  ...distributionPerOwner.entries.map((entry) {
                    final index = distributionPerOwner.keys.toList().indexOf(entry.key);
                    final percentage = (entry.value / total * 100);
                    
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(entry.key),
                          ),
                          Text(
                            '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: Calendar View - Aktivitas
  // ============================================================================
  Widget _buildCalendarView() {
    if (calendarData.isEmpty) {
      return _buildEmptyState('Belum ada aktivitas');
    }

    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month - 2, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktivitas Harian',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Heatmap perhitungan 90 hari terakhir',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
          
          AnimatedCard(
            delay: Duration(milliseconds: 100),
            child: Container(
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
              child: Column(
                children: _buildCalendarGrid(firstDay, lastDay),
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Kurang', style: TextStyle(fontSize: 12)),
              SizedBox(width: 8),
              _buildLegendBox(Colors.grey.shade200),
              _buildLegendBox(Colors.green.shade200),
              _buildLegendBox(Colors.green.shade400),
              _buildLegendBox(Colors.green.shade600),
              _buildLegendBox(Colors.green.shade800),
              SizedBox(width: 8),
              Text('Banyak', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCalendarGrid(DateTime firstDay, DateTime lastDay) {
    List<Widget> weeks = [];
    DateTime currentDate = firstDay;
    
    while (currentDate.isBefore(lastDay) || currentDate.isAtSameMomentAs(lastDay)) {
      List<Widget> days = [];
      
      // Build week row
      for (int i = 0; i < 7; i++) {
        if (currentDate.isAfter(lastDay)) break;
        
        final date = DateTime(currentDate.year, currentDate.month, currentDate.day);
        final count = calendarData[date] ?? 0;
        
        days.add(_buildDayBox(currentDate, count));
        currentDate = currentDate.add(Duration(days: 1));
      }
      
      weeks.add(
        Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: days,
          ),
        ),
      );
    }
    
    return weeks;
  }

  Widget _buildDayBox(DateTime date, int count) {
    Color color;
    if (count == 0) {
      color = Colors.grey.shade200;
    } else if (count <= 2) {
      color = Colors.green.shade200;
    } else if (count <= 4) {
      color = Colors.green.shade400;
    } else if (count <= 6) {
      color = Colors.green.shade600;
    } else {
      color = Colors.green.shade800;
    }
    
    return Tooltip(
      message: '${date.day}/${date.month}: $count aktivitas',
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ============================================================================
  // Helper Widgets
  // ============================================================================
  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8),
          Text(
            'Lakukan beberapa perhitungan terlebih dahulu',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}