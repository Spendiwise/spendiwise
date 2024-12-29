import 'package:flutter/material.dart';

class ForecastingScreen extends StatelessWidget {
  const ForecastingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forecasting'),
      ),
      body: const Center(
        child: Text(
          'Forecasting:',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
