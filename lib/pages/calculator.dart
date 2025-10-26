import 'package:flutter/material.dart';
import '../models/calculation_history.dart';
import '../models/tank.dart';
import '../services/db.dart';
import '../utils/animations.dart';

class CalculatorPage extends StatefulWidget {
  @override
  _CalculatorPageState createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  List<Tank> tanks = [];
  List<CalculationHistory> histories = [];
  
  Tank? selectedTank;
  CalculationHistory? history1;
  CalculationHistory? history2;
  
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    
    final tankData = await DatabaseService.getTanks();
    
    setState(() {
      tanks = tankData;
      isLoading = false;
    });
  }

  Future<void> loadHistoriesForTank(int tankId) async {
    final data = await DatabaseService.getHistoryByTank(tankId);
    setState(() {
      histories = data;
      history1 = null;
      history2 = null;
    });
  }

  Map<String, dynamic>? calculateDifference() {
    if (history1 == null || history2 == null) return null;

    final diffV15 = history2!.v15 - history1!.v15;
    final diffVObs = history2!.vObs - history1!.vObs;
    final percentageChange = (diffV15 / history1!.v15) * 100;

    return {
      'diffV15': diffV15,
      'diffVObs': diffVObs,
      'percentageChange': percentageChange,
      'isIncrease': diffV15 > 0,
    };
  }

  Widget _buildHistorySelector(
    String label,
    CalculationHistory? selected,
    Function(CalculationHistory?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<CalculationHistory>(
            value: selected,
            isExpanded: true,
            underline: SizedBox(),
            hint: Text('Pilih perhitungan'),
            items: histories.map((history) {
              return DropdownMenuItem(
                value: history,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      history.getFormattedDate(),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'V15: ${history.v15.toStringAsFixed(2)} L',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonCard(CalculationHistory history, String title, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildDetailRow('Tanggal', history.getFormattedDate()),
            _buildDetailRow('Sounding', '${history.sounding.toStringAsFixed(1)} mm'),
            _buildDetailRow('Temp Dalam', '${history.tempDalam.toStringAsFixed(1)} °C'),
            _buildDetailRow('Density Obs', history.densityObserved.toStringAsFixed(4)),
            Divider(height: 20),
            _buildDetailRow(
              'V15',
              '${history.v15.toStringAsFixed(2)} L',
              highlight: true,
            ),
            _buildDetailRow('V.Obs', '${history.vObs.toStringAsFixed(2)} L'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              color: highlight ? Colors.blue.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final isIncrease = result['isIncrease'] as bool;
    final color = isIncrease ? Colors.green : Colors.red;
    final icon = isIncrease ? Icons.trending_up : Icons.trending_down;
    final label = isIncrease ? 'Bertambah' : 'Berkurang';

    return Card(
      elevation: 4,
      color: color.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 32),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Selisih V15
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Selisih Volume (V15)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${isIncrease ? '+' : ''}${result['diffV15'].toStringAsFixed(2)} L',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            // Persentase
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Persentase Perubahan',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '${isIncrease ? '+' : ''}${result['percentageChange'].toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            // Selisih V.Obs
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selisih V.Obs',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '${isIncrease ? '+' : ''}${result['diffVObs'].toStringAsFixed(2)} L',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final difference = calculateDifference();

    return Scaffold(
      appBar: AppBar(
        title: Text('Kalkulator Selisih'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info Card
                  Card(
                    color: Colors.purple.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.purple.shade700),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Bandingkan 2 perhitungan untuk melihat selisih volume',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Tank Selector
                  Text(
                    'Pilih Tangki',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButton<Tank>(
                      value: selectedTank,
                      isExpanded: true,
                      underline: SizedBox(),
                      hint: Text('Pilih tangki'),
                      items: tanks.map((tank) {
                        return DropdownMenuItem(
                          value: tank,
                          child: Text(tank.name),
                        );
                      }).toList(),
                      onChanged: (tank) {
                        setState(() => selectedTank = tank);
                        if (tank != null) {
                          loadHistoriesForTank(tank.id!);
                        }
                      },
                    ),
                  ),

                  if (selectedTank != null) ...[
                    SizedBox(height: 24),

                    if (histories.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada history untuk tangki ini',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (histories.length < 2)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 64,
                                color: Colors.orange.shade400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Minimal 2 perhitungan untuk membandingkan',
                                style: TextStyle(color: Colors.grey.shade600),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // History 1 Selector
                      AnimatedCard(
                        delay: Duration(milliseconds: 300),
                        child: _buildHistorySelector(
                          'Perhitungan Pertama (Awal)',
                          history1,
                          (val) => setState(() => history1 = val),
                        ),
                      ),

                      SizedBox(height: 20),

                      // History 2 Selector
                      AnimatedCard(
                        delay: Duration(milliseconds: 400),
                        child: _buildHistorySelector(
                          'Perhitungan Kedua (Akhir)',
                          history2,
                          (val) => setState(() => history2 = val),
                        ),
                      ),

                      if (history1 != null && history2 != null) ...[
                        SizedBox(height: 24),
                        
                        // Result Card
                        AnimatedCard(
                          delay: Duration(milliseconds: 500),
                          child: _buildResultCard(difference!),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Comparison Cards
                        AnimatedCard(
                          delay: Duration(milliseconds: 600),
                          child: _buildComparisonCard(
                            history1!,
                            'AWAL',
                            Colors.blue,
                          ),
                        ),
                        
                        SizedBox(height: 12),
                        
                        AnimatedCard(
                          delay: Duration(milliseconds: 700),
                          child: _buildComparisonCard(
                            history2!,
                            'AKHIR',
                            Colors.orange,
                          ),
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}