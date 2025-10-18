import 'package:flutter/material.dart';
import '../services/auth.dart';
import 'home.dart';

class ActivationPage extends StatefulWidget {
  @override
  _ActivationPageState createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final _formKey = GlobalKey<FormState>();
  final keyController = TextEditingController();
  bool isLoading = false;

  Future<void> activate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final result = await AuthService.validateKey(keyController.text.trim().toUpperCase());

    setState(() => isLoading = false);

    if (result['success']) {
      // Aktivasi berhasil
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );

      // Tunggu 1 detik, lalu ke Home
      await Future.delayed(Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      // Aktivasi gagal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade700, Colors.blue.shade400],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.water_drop,
                      size: 80,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(height: 30),

                  // Title
                  Text(
                    'MyTank',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Aktivasi Aplikasi',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 50),

                  // Card Form
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Masukkan Activation Key',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20),

                            // Key Input
                            TextFormField(
                              controller: keyController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: 'Activation Key',
                                hintText: 'MYTANK-XXXX-XXXX-XXXX',
                                prefixIcon: Icon(Icons.vpn_key),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Key harus diisi';
                                }
                                if (!value.toUpperCase().startsWith('MYTANK-')) {
                                  return 'Key harus diawali dengan MYTANK-';
                                }
                                if (value.length != 23) {
                                  return 'Format key tidak valid';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 24),

                            // Activate Button
                            ElevatedButton(
                              onPressed: isLoading ? null : activate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'AKTIVASI',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            SizedBox(height: 16),

                            // Info
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Butuh koneksi internet untuk aktivasi',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    keyController.dispose();
    super.dispose();
  }
}