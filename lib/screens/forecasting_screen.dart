import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:http/http.dart' as http; // For making HTTP requests
import 'package:firebase_auth/firebase_auth.dart';

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

  final List<String> categories = ['Groceries', 'Entertainment','Food', 'Utilities', 'Dining'];  // Example categories
  final List<String> durations = ['week', 'month'];  // Example durations

  Future<void> _fetchForecastData(String category, String duration) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Example API URL (replace with your actual API endpoint)
      final String apiUrl = 'http://192.168.89.220:5000/forecast';

      // JSON payload
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
        setState(() {
          forecastData = jsonDecode(response.body); // Decode and store forecast data
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forecasting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedCategory,
              hint: Text('Select Category'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              items: categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            DropdownButton<String>(
              value: _selectedDuration,
              hint: Text('Select Duration'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDuration = newValue;
                });
              },
              items: durations.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_selectedCategory != null && _selectedDuration != null) {
                  _fetchForecastData(_selectedCategory!, _selectedDuration!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select both category and duration')),
                  );
                }
              },
              child: Text('Fetch Forecast'),
            ),
            SizedBox(height: 16),
            if (forecastData != null)
              Expanded(
                child: ListView.builder(
                  itemCount: forecastData!.length,
                  itemBuilder: (context, index) {
                    var entry = forecastData!.entries.elementAt(index);
                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(Icons.bar_chart, color: Colors.blue),
                        title: Text(entry.key),
                        subtitle: Text('Value: ${entry.value}'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
