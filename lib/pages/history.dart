import 'package:flutter/material.dart';
import '../models/calculation_history.dart';
import '../services/db.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<CalculationHistory> histories = [];
  bool isLoading = true;
  String filterTank = 'Semua';
  List<String> tankNames = ['Semua'];

  @override
  void initState() {
    super.initState();
    loadHistory();
    loadTankNames();
  }

  Future<void> loadHistory() async {
    setState(() => isLoading = true);
    
    final data = await DatabaseService.getAllHistory();
    
    setState(() {
      histories = data;
      isLoading = false;
    });
  }

  Future<void> loadTankNames() async {
    final tanks = await DatabaseService.getTanks();
    setState(() {
      tankNames = ['Semua', ...tanks.map((t) => t.name)];
    });
  }

  List<CalculationHistory> getFilteredHistory() {
    if (filterTank == 'Semua') {
      return histories;
    }
    return histories.where((h) => h.tankName == filterTank).toList();
  }

  Future<void> deleteHistory(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus History'),
        content: Text('Yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deleteHistory(id);
      loadHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('History berhasil dihapus')),
      );
    }
  }

  Future<void> clearAllHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Semua History'),
        content: Text('Yakin ingin menghapus SEMUA history? Aksi ini tidak dapat dibatalkan!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.clearAllHistory();
      loadHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua history berhasil dihapus')),
      );
    }
  }

  void showHistoryDetail(CalculationHistory history) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Detail Perhitungan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                history.getFormattedDate(),
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              Divider(height: 32),
              
              _buildDetailSection('Tangki', [
                _buildDetailRow('Nama', history.tankName),
              ]),
              
              _buildDetailSection('Input Data', [
                _buildDetailRow('Sounding', '${history.sounding.toStringAsFixed(1)} mm'),
                _buildDetailRow('Meja Ukur', '${history.mejaUkur.toStringAsFixed(1)} mm'),
                _buildDetailRow('Temp Dalam', '${history.tempDalam.toStringAsFixed(1)} °C'),
                _buildDetailRow('Temp Luar', '${history.tempLuar.toStringAsFixed(1)} °C'),
                _buildDetailRow('Density Obs', history.densityObserved.toStringAsFixed(4)),
              ]),
              
              _buildDetailSection('Hasil Perhitungan', [
                _buildDetailRow('Volume Tabel (Vt)', '${history.vt.toStringAsFixed(2)} L', highlight: true),
                _buildDetailRow('Volume Observasi (Vobs)', '${history.vObs.toStringAsFixed(2)} L'),
                _buildDetailRow('VCF', history.vcf.toStringAsFixed(6)),
                _buildDetailRow('Volume 15°C (V15)', '${history.v15.toStringAsFixed(2)} L', highlight: true),
                _buildDetailRow('Density 15°C (D15)', history.d15.toStringAsFixed(4)),
              ]),
              
              if (history.notes != null && history.notes!.isNotEmpty)
                _buildDetailSection('Catatan', [
                  Text(history.notes!, style: TextStyle(fontSize: 14)),
                ]),
              
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        deleteHistory(history.id!);
                      },
                      icon: Icon(Icons.delete, color: Colors.red),
                      label: Text('Hapus', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.all(12),
                        side: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                      label: Text('Tutup'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: children),
        ),
        SizedBox(height: 16),
      ],
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
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? Colors.blue[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = getFilteredHistory();

    return Scaffold(
      appBar: AppBar(
        title: Text('History Perhitungan'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (histories.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep),
              onPressed: clearAllHistory,
              tooltip: 'Hapus Semua',
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.filter_list, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text('Filter: ', style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: filterTank,
                    isExpanded: true,
                    items: tankNames.map((name) {
                      return DropdownMenuItem(value: name, child: Text(name));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => filterTank = value!);
                    },
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          
          // List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada history',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Lakukan perhitungan untuk menyimpan history',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadHistory,
                        child: ListView.builder(
                          padding: EdgeInsets.all(8),
                          itemCount: filteredHistory.length,
                          itemBuilder: (context, index) {
                            final history = filteredHistory[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Icon(Icons.water_drop, color: Colors.blue.shade700),
                                ),
                                title: Text(
                                  history.tankName,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    Text('V15: ${history.v15.toStringAsFixed(2)} L'),
                                    Text(
                                      history.getFormattedDate(),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                trailing: Icon(Icons.chevron_right),
                                onTap: () => showHistoryDetail(history),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}