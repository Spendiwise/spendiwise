import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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
          
          // Add to history with enhanced data structure
          Map<String, dynamic> historyEntry = {
            "category": category,
            "duration": duration,
            "data": result,
            "timestamp": DateTime.now().toString(),
            "forecast_generated_at": result['forecast_generated_at'] ?? DateTime.now().toString(),
            "forecast_period": result['forecast_period'] ?? {},
            "data_period": result['data_period'] ?? {},
          };
          
          forecastHistory.insert(0, historyEntry); // Insert at beginning for latest first
        });

        // Save to Firestore with enhanced structure
        await FirebaseFirestore.instance.collection('forecasts').add({
          "user_id": user.uid,
          "category": category,
          "duration": duration,
          "data": result,
          "timestamp": FieldValue.serverTimestamp(),
          "forecast_generated_at": result['forecast_generated_at'],
          "forecast_period": result['forecast_period'],
          "data_period": result['data_period'],
        });
        
        // Reload from Firestore to get real spending data
        await _loadForecastsFromFirestore();
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
          .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final List<Map<String, dynamic>> loadedForecasts = [];

      for (var doc in forecastSnapshot.docs) {
        final String category = doc['category'];
        final String duration = doc['duration'];
        final Map<String, dynamic> data = Map<String, dynamic>.from(doc['data']);
        final DateTime forecastTimestamp = (doc['timestamp'] as Timestamp).toDate();
        
        // Get forecast period from the stored data
        final Map<String, dynamic>? forecastPeriod = doc.data().containsKey('forecast_period') 
            ? Map<String, dynamic>.from(doc['forecast_period']) 
            : null;

        DateTime startDate;
        DateTime endDate;
        
        if (forecastPeriod != null && forecastPeriod.containsKey('start_date') && forecastPeriod.containsKey('end_date')) {
          startDate = DateTime.parse(forecastPeriod['start_date']);
          endDate = DateTime.parse(forecastPeriod['end_date']);
        } else {
          if (duration == 'week') {
            startDate = forecastTimestamp;
            endDate = forecastTimestamp.add(const Duration(days: 7));
          } else if (duration == 'month') {
            startDate = forecastTimestamp;
            endDate = DateTime(forecastTimestamp.year, forecastTimestamp.month + 1, forecastTimestamp.day);
          } else {
            startDate = forecastTimestamp;
            endDate = forecastTimestamp.add(const Duration(days: 30));
          }
        }

        // FIXED: Correct Firestore query for transactions
        double realSpending = 0;
        try {
          // Method 1: Query with string user_id (if stored as string)
          var transactionSnapshot = await FirebaseFirestore.instance
              .collection('transactions')
              .where('user_id', isEqualTo: FirebaseFirestore.instance.collection('users').doc(user.uid)) // Direct string comparison
              .where('category', isEqualTo: category)
              .where('isIncome', isEqualTo: false)
              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
              .get();

          print("Found ${transactionSnapshot.docs.length} transactions for $category between $startDate and $endDate");

          if (transactionSnapshot.docs.isEmpty) {
            // Method 2: Try with DocumentReference if user_id is stored as reference
            try {
              transactionSnapshot = await FirebaseFirestore.instance
                  .collection('transactions')
                  .where('user_id', isEqualTo: FirebaseFirestore.instance.collection('users').doc(user.uid))
                  .where('category', isEqualTo: category)
                  .where('isIncome', isEqualTo: false)
                  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
                  .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
                  .get();
              
              print("Found ${transactionSnapshot.docs.length} transactions with DocumentReference query");
            } catch (e) {
              print("DocumentReference query failed: $e");
            }
          }
          print("📦 Transactions fetched: ${transactionSnapshot.docs.length}");
          print("User ref being queried: ${FirebaseFirestore.instance.collection('users').doc(user.uid)}"); // should be "users/wR3LbXKhmJYPseZYToGkmhcYz373"
          // Calculate real spending
          for (var txn in transactionSnapshot.docs) {
            final data = txn.data();
            print("Transaction data: $data"); // Debug print
            print("✅ txn amount: ${data['amount']} | isIncome: ${data['isIncome']} | date: ${data['date']}");
            
            // Handle different number types
            final dynamic amount = data['amount'];
            if (amount != null) {
              if (amount is num) {
                realSpending += amount.toDouble();
              } else if (amount is String) {
                realSpending += double.tryParse(amount) ?? 0.0;
              }
            }
          }
          
          print("Total real spending for $category: $realSpending");
          
        } catch (e) {
          print("Error fetching transactions: $e");
          
          // Method 3: Fallback - get all user transactions and filter in memory
          try {
            final allTransactions = await FirebaseFirestore.instance
                .collection('transactions')
                .where('user_id', isEqualTo: FirebaseFirestore.instance.collection('users').doc(user.uid))
                .get();
            
            print("Fallback: Found ${allTransactions.docs.length} total transactions");
            
            for (var txn in allTransactions.docs) {
              final data = txn.data();
              
              // Check if this transaction matches our criteria
              if (data['category'] == category && 
                  data['isIncome'] == false &&
                  data['date'] != null) {
                
                DateTime txnDate;
                if (data['date'] is Timestamp) {
                  txnDate = (data['date'] as Timestamp).toDate();
                } else if (data['date'] is String) {
                  txnDate = DateTime.parse(data['date']);
                } else {
                  continue; // Skip if date format is unknown
                }
                
                // Check if date is within range
                if (txnDate.isAfter(startDate.subtract(const Duration(days: 1))) && 
                    txnDate.isBefore(endDate.add(const Duration(days: 1)))) {
                  
                  final dynamic amount = data['amount'];
                  if (amount != null) {
                    if (amount is num) {
                      realSpending += amount.toDouble();
                    } else if (amount is String) {
                      realSpending += double.tryParse(amount) ?? 0.0;
                    }
                  }
                }
              }
            }
            
            print("Fallback real spending for $category: $realSpending");
            
          } catch (fallbackError) {
            print("Fallback query also failed: $fallbackError");
          }
        }

        loadedForecasts.add({
          "category": category,
          "duration": duration,
          "data": data,
          "timestamp": forecastTimestamp.toString(),
          "forecast_generated_at": doc.data().containsKey('forecast_generated_at') 
              ? doc['forecast_generated_at'] 
              : forecastTimestamp.toString(),
          "forecast_period": forecastPeriod ?? {},
          "data_period": doc.data().containsKey('data_period') 
              ? Map<String, dynamic>.from(doc['data_period']) 
              : {},
          "real_amount": realSpending,
          "forecast_start_date": startDate,
          "forecast_end_date": endDate,
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

  // Additional helper method to debug transaction structure
  Future<void> _debugTransactionStructure() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get a few sample transactions to understand the structure
      final sampleTransactions = await FirebaseFirestore.instance
          .collection('transactions')
          .limit(5)
          .get();
      
      print("=== SAMPLE TRANSACTION STRUCTURE ===");
      for (var doc in sampleTransactions.docs) {
        print("Transaction ID: ${doc.id}");
        print("Data: ${doc.data()}");
        print("---");
      }
      
      // Check if any transactions exist for current user
      final userTransactions = await FirebaseFirestore.instance
          .collection('transactions')
          .where('user_id', isEqualTo: FirebaseFirestore.instance.collection('users').doc(user.uid))
          .limit(3)
          .get();
      
      print("=== USER TRANSACTIONS (String user_id) ===");
      print("Found ${userTransactions.docs.length} transactions");
      for (var doc in userTransactions.docs) {
        print("Transaction: ${doc.data()}");
      }
      
      // Try with DocumentReference
      try {
        final userRefTransactions = await FirebaseFirestore.instance
            .collection('transactions')
            .where('user_id', isEqualTo: FirebaseFirestore.instance.collection('users').doc(user.uid))
            .limit(3)
            .get();
        
        print("=== USER TRANSACTIONS (DocumentReference user_id) ===");
        print("Found ${userRefTransactions.docs.length} transactions");
        for (var doc in userRefTransactions.docs) {
          print("Transaction: ${doc.data()}");
        }
      } catch (e) {
        print("DocumentReference query failed: $e");
      }
      
    } catch (e) {
      print("Debug failed: $e");
    }
  }

  Widget _buildHistoryChart() {
    if (forecastHistory.isEmpty) {
      return const Center(child: Text("No data to chart"));
    }

    // Sort by forecast generation date for proper chronological order
    List<Map<String, dynamic>> sortedHistory = List.from(forecastHistory);
    sortedHistory.sort((a, b) {
      DateTime dateA = DateTime.parse(a["forecast_generated_at"]);
      DateTime dateB = DateTime.parse(b["forecast_generated_at"]);
      return dateA.compareTo(dateB);
    });

    List<FlSpot> forecastSpots = [];
    List<FlSpot> realSpots = [];
    Map<int, String> monthLabels = {};

    for (int i = 0; i < sortedHistory.length; i++) {
      final entry = sortedHistory[i];
      final DateTime forecastDate = DateTime.parse(entry["forecast_generated_at"]);
      
      // Extract forecast value
      final dynamic rawForecast = entry["data"]["forecast"];
      final double forecastValue = rawForecast is num
          ? rawForecast.toDouble()
          : double.tryParse(rawForecast.toString()) ?? 0.0;
      
      final double realValue = (entry["real_amount"] ?? 0).toDouble();
      print("🔍 Real spending for ${entry["category"]} = $realValue");

      forecastSpots.add(FlSpot(i.toDouble(), forecastValue));
      realSpots.add(FlSpot(i.toDouble(), realValue));
      
      // Create better labels showing forecast period
      String label = "${_monthAbbr(forecastDate.month)} ${forecastDate.year}";
      if (entry["forecast_period"] != null && entry["forecast_period"].isNotEmpty) {
        try {
          DateTime startDate = DateTime.parse(entry["forecast_period"]["start_date"]);
          label = "${_monthAbbr(startDate.month)} ${startDate.year}";
        } catch (e) {
          // Use fallback label
        }
      }
      monthLabels[i] = label;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Forecast vs Actual Spending",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Shows forecast predictions vs actual spending over time",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.5)),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '\$${value.toInt()}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (monthLabels.containsKey(index)) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                monthLabels[index]!,
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: forecastSpots,
                    isCurved: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.deepPurple,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    color: Colors.deepPurple,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.deepPurple.withOpacity(0.1),
                    ),
                    barWidth: 3,
                  ),
                  LineChartBarData(
                    spots: realSpots,
                    isCurved: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.orange,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    color: Colors.orange,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withOpacity(0.1),
                    ),
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
                      labelResolver: (_) => "Limit: \$${_historySpendingLimit.toInt()}",
                      style: const TextStyle(
                        color: Colors.red, 
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 3,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 8),
                  const Text('Forecast', style: TextStyle(fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 3,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  const Text('Actual', style: TextStyle(fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Limit', style: TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(
                "Adjust Spending Limit: \$${_historySpendingLimit.toStringAsFixed(0)}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Slider(
                min: 0,
                max: 1000,
                divisions: 100,
                value: _historySpendingLimit,
                activeColor: Colors.deepPurple,
                onChanged: (value) {
                  setState(() {
                    _historySpendingLimit = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _monthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildForecastHistoryCard(Map<String, dynamic> entry) {
    DateTime generatedAt = DateTime.parse(entry["forecast_generated_at"]);
    String formattedDate = DateFormat('MMM dd, yyyy HH:mm').format(generatedAt);
    
    // Extract forecast value
    final dynamic rawForecast = entry["data"]["forecast"];
    final double forecastValue = rawForecast is num
        ? rawForecast.toDouble()
        : double.tryParse(rawForecast.toString()) ?? 0.0;
    
    final double realValue = (entry["real_amount"] ?? 0).toDouble();
    final double accuracy = forecastValue > 0 ? (1 - (forecastValue - realValue).abs() / forecastValue) * 100 : 0;
    
    // Get forecast period info
    String forecastPeriodText = "";
    if (entry["forecast_period"] != null && entry["forecast_period"].isNotEmpty) {
      try {
        DateTime startDate = DateTime.parse(entry["forecast_period"]["start_date"]);
        DateTime endDate = DateTime.parse(entry["forecast_period"]["end_date"]);
        forecastPeriodText = "Forecast Period: ${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}";
      } catch (e) {
        forecastPeriodText = "Duration: ${entry["duration"]}";
      }
    } else {
      forecastPeriodText = "Duration: ${entry["duration"]}";
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${entry["category"]}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accuracy > 80 ? Colors.green : accuracy > 60 ? Colors.orange : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${accuracy.toStringAsFixed(1)}% accurate',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              forecastPeriodText,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Forecast', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      '\$${forecastValue.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Actual', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      '\$${realValue.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Difference', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      '\$${(forecastValue - realValue).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: (forecastValue - realValue) > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Generated: $formattedDate',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: forecastHistory.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No forecast history found.",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Create your first forecast to see the analysis here.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildHistoryChart(),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    const Text(
                      "Forecast History", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: forecastHistory.length,
                    itemBuilder: (context, index) {
                      return _buildForecastHistoryCard(forecastHistory[index]);
                    },
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
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add_chart), text: 'New Forecast'),
              Tab(icon: Icon(Icons.history), text: 'History'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Forecast',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Select Category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
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
                  DropdownButtonFormField<String>(
                    value: _selectedDuration,
                    decoration: const InputDecoration(
                      labelText: 'Select Duration',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDuration = newValue;
                      });
                    },
                    items: durations.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.toUpperCase()),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Set Spending Limit (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      hintText: 'Enter amount',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        spendingLimit = double.tryParse(value);
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_selectedCategory != null && _selectedDuration != null) {
                          _fetchForecastData(_selectedCategory!, _selectedDuration!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select both category and duration')),
                          );
                        }
                      },
                      icon: const Icon(Icons.psychology),
                      label: const Text('Generate Forecast'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (forecastData != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.insights, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        const Text(
                          'Forecast Results',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Main forecast value
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Predicted Spending',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\${(forecastData!["forecast"] as num).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          if (spendingLimit != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'vs Limit: \${spendingLimit!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: (forecastData!["forecast"] as num) > spendingLimit!
                                    ? Colors.red
                                    : Colors.green,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                (forecastData!["forecast"] as num) > spendingLimit!
                                    ? 'Over Budget by \${((forecastData!["forecast"] as num) - spendingLimit!).toStringAsFixed(2)}'
                                    : 'Within Budget',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Forecast details
                    if (forecastData!.containsKey('forecast_period')) ...[
                      const Text(
                        'Forecast Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Category', _selectedCategory ?? 'N/A'),
                      _buildDetailRow('Duration', '${forecastData!["forecast_period"]["duration_days"]} days'),
                      if (forecastData!["forecast_period"]["start_date"] != null)
                        _buildDetailRow(
                          'Forecast Period',
                          '${DateFormat('MMM dd').format(DateTime.parse(forecastData!["forecast_period"]["start_date"]))} - ${DateFormat('MMM dd, yyyy').format(DateTime.parse(forecastData!["forecast_period"]["end_date"]))}',
                        ),
                      if (forecastData!["forecast_generated_at"] != null)
                        _buildDetailRow(
                          'Generated At',
                          DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(forecastData!["forecast_generated_at"])),
                        ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Data source info
                    if (forecastData!.containsKey('data_period')) ...[
                      const Text(
                        'Data Source',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Total Days of Data', '${forecastData!["data_period"]["total_days"]}'),
                      if (forecastData!["data_period"]["first_transaction"] != null)
                        _buildDetailRow(
                          'Data Range',
                          '${DateFormat('MMM dd').format(DateTime.parse(forecastData!["data_period"]["first_transaction"]))} - ${DateFormat('MMM dd, yyyy').format(DateTime.parse(forecastData!["data_period"]["last_transaction"]))}',
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}