import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ForecastingScreen extends StatefulWidget {
  const ForecastingScreen({Key? key}) : super(key: key);

  @override
  _ForecastingScreenState createState() => _ForecastingScreenState();
}

class _ForecastingScreenState extends State<ForecastingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _selectedCategory;
  String? _selectedDuration;
  Map<String, dynamic>? forecastData;
  double? spendingLimit;

  final List<Map<String, dynamic>> forecastHistory = [];

  final List<String> categories = ['Groceries', 'Entertainment', 'Food', 'Utilities', 'Dining'];
  final List<String> durations = ['week', 'month'];

  @override
  void initState() {
    super.initState();
    _loadForecastsFromFirestore();
  }

  Future<void> _fetchForecastData(String category, String duration) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final String apiUrl = 'http://10.0.2.2:5000/forecast';

      final Map<String, dynamic> payload = {
        "user_id": user.uid,
        "category": category,
        "duration": duration,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          forecastData = result;
          forecastHistory.add({
            "category": category,
            "duration": duration,
            "data": result,
            "timestamp": DateTime.now().toString(),
          });
        });

        await FirebaseFirestore.instance.collection('forecasts').add({
          "user_id": user.uid,
          "category": category,
          "duration": duration,
          "data": result,
          "timestamp": FieldValue.serverTimestamp(),
        });
      } else {
        throw Exception('Failed to fetch forecast data: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching forecast data: ${e.toString()}")),
      );
    }
  }

  Future<void> _loadForecastsFromFirestore() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      print("No user logged in.");
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('forecasts')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      print("Fetched ${snapshot.docs.length} documents");

      setState(() {
        forecastHistory.clear();
        for (var doc in snapshot.docs) {
          print("Loaded forecast: ${doc.data()}");
          forecastHistory.add({
            "category": doc['category'],
            "duration": doc['duration'],
            "data": doc['data'],
            "timestamp": (doc['timestamp'] as Timestamp).toDate().toString(),
          });
        }
      });
    } catch (e) {
      print("Error loading forecasts: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forecast Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Category Dropdown
            DropdownButton<String>(
              value: _selectedCategory,
              hint: const Text('Select Category'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              items: categories.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Duration Dropdown
            DropdownButton<String>(
              value: _selectedDuration,
              hint: const Text('Select Duration'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDuration = newValue;
                });
              },
              items: durations.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Spending Limit Input
            TextField(
              decoration: const InputDecoration(
                labelText: 'Set Spending Limit',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  spendingLimit = double.tryParse(value);
                });
              },
            ),

            const SizedBox(height: 16),

            // Fetch Button
            ElevatedButton(
              onPressed: () {
                if (_selectedCategory != null && _selectedDuration != null) {
                  _fetchForecastData(_selectedCategory!, _selectedDuration!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select both category and duration')),
                  );
                }
              },
              child: const Text('Fetch Forecast'),
            ),

            const SizedBox(height: 20),

            // Forecast Display
            if (forecastData != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Forecast Results:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...forecastData!.entries.map((entry) {
                    final value = entry.value;
                    final isNumeric = value is num;
                    final bool overLimit = isNumeric && spendingLimit != null && value > spendingLimit!;

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(Icons.bar_chart, color: overLimit ? Colors.red : Colors.green),
                        title: Text(entry.key),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Value: $value'),
                            if (isNumeric && spendingLimit != null)
                              Text(
                                'Difference: ${(value - spendingLimit!).toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: (value - spendingLimit!) > 0 ? Colors.red : Colors.green,
                                ),
                              ),
                          ],
                        ),
                        trailing: spendingLimit != null
                            ? isNumeric
                                ? Text(
                                    overLimit ? 'Over Limit' : 'Within Limit',
                                    style: TextStyle(color: overLimit ? Colors.red : Colors.green),
                                  )
                                : const Text('N/A')
                            : null,
                      ),
                    );
                  }).toList(),
                ],
              ),

            const SizedBox(height: 24),

            // Forecast History
            if (forecastHistory.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Forecast History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...forecastHistory.reversed.map((entry) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text('${entry["category"]} - ${entry["duration"]}'),
                        subtitle: Text('Forecast: ${entry["data"].toString()}'),
                        trailing: Text(
                          entry["timestamp"].toString().split('.')[0],
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
