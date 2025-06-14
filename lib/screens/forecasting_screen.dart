import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

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
  double _historySpendingLimit = 100.0;

  final List<Map<String, dynamic>> forecastHistory = [];

  final List<String> categories = ['Groceries', 'Entertainment', 'Food', 'Utilities', 'Restaurants'];
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
    if (user == null) return;

    try {
      final forecastSnapshot = await FirebaseFirestore.instance
          .collection('forecasts')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> loadedForecasts = [];

      for (var doc in forecastSnapshot.docs) {
        final String category = doc['category'];
        final String duration = doc['duration'];
        final Map<String, dynamic> data = Map<String, dynamic>.from(doc['data']);
        final DateTime forecastTimestamp = (doc['timestamp'] as Timestamp).toDate();

        // Determine start date based on duration
        DateTime startDate;
        if (duration == 'week') {
          startDate = forecastTimestamp.subtract(const Duration(days: 7));
        } else if (duration == 'month') {
          startDate = DateTime(forecastTimestamp.year, forecastTimestamp.month - 1, forecastTimestamp.day);
        } else {
          startDate = forecastTimestamp.subtract(const Duration(days: 30)); // Fallback
        }

        // Fetch matching real transactions
        final transactionSnapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('user_id', isEqualTo: user.uid) // Match reference string
            .where('category', isEqualTo: category)
            .where('isIncome', isEqualTo: false)
            .where('date', isGreaterThanOrEqualTo: startDate)
            .where('date', isLessThanOrEqualTo: forecastTimestamp)
            .get();

        double realSpending = 0;
        for (var txn in transactionSnapshot.docs) {
          realSpending += (txn['amount'] as num).toDouble();
        }

        loadedForecasts.add({
          "category": category,
          "duration": duration,
          "data": data,
          "timestamp": forecastTimestamp.toString(),
          "real_amount": realSpending,
        });
      }

      setState(() {
        forecastHistory
          ..clear()
          ..addAll(loadedForecasts);
      });
    } catch (e) {
      print("Error loading forecasts or real data: $e");
    }
  }

  Widget _buildHistoryChart() {
    if (forecastHistory.isEmpty) {
      return const Center(child: Text("No data to chart"));
    }

    List<FlSpot> forecastSpots = [];
    List<FlSpot> realSpots = [];
    Map<int, String> monthLabels = {}; // X-index -> "Jan 2025"

    for (int i = 0; i < forecastHistory.length; i++) {
      final entry = forecastHistory[i];
      final DateTime timestamp = DateTime.parse(entry["timestamp"]);
      final dynamic rawForecast = entry["data"].values.first;
      final double forecastValue = rawForecast is num
          ? rawForecast.toDouble()
          : double.tryParse(rawForecast.toString()) ?? 0.0;
      final double realValue = (entry["real_amount"] ?? 0).toDouble();

      forecastSpots.add(FlSpot(i.toDouble(), forecastValue));
      realSpots.add(FlSpot(i.toDouble(), realValue));
      monthLabels[i] = "${_monthAbbr(timestamp.month)} ${timestamp.year}";
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              minY: 0,
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (monthLabels.containsKey(index)) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            monthLabels[index]!,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: forecastSpots,
                  isCurved: true,
                  dotData: FlDotData(show: true),
                  color: Colors.deepPurple,
                  belowBarData: BarAreaData(show: false),
                  barWidth: 3,
                ),
                LineChartBarData(
                  spots: realSpots,
                  isCurved: true,
                  dotData: FlDotData(show: true),
                  color: Colors.orange,
                  belowBarData: BarAreaData(show: false),
                  barWidth: 3,
                ),
              ],
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: _historySpendingLimit,
                  color: Colors.redAccent,
                  strokeWidth: 2,
                  dashArray: [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    labelResolver: (_) => "Limit: $_historySpendingLimit",
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                )
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, color: Colors.deepPurple),
            SizedBox(width: 4),
            Text('Forecast'),
            SizedBox(width: 12),
            Icon(Icons.show_chart, color: Colors.orange),
            SizedBox(width: 4),
            Text('Actual'),
          ],
        ),
        const SizedBox(height: 12),
        Text("Adjust Spending Limit: ${_historySpendingLimit.toStringAsFixed(2)}"),
        Slider(
          min: 0,
          max: 1000,
          divisions: 100,
          value: _historySpendingLimit,
          onChanged: (value) {
            setState(() {
              _historySpendingLimit = value;
            });
          },
        ),
      ],
    );
  }

  // Helper function
  String _monthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildForecastHistoryCard(Map<String, dynamic> entry) {
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
  }

  Widget _buildHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: forecastHistory.isEmpty
          ? const Center(child: Text("No forecast history found."))
          : Column(
              children: [
                _buildHistoryChart(),
                const SizedBox(height: 20),
                const Text("Forecast History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView(
                    children: forecastHistory.map(_buildForecastHistoryCard).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Forecast Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'New Forecast'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNewForecastTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildNewForecastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
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
          if (forecastData != null) ...[
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
          ]
        ],
      ),
    );
  }
}