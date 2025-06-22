import 'package:flutter/material.dart';
import '../screens/forecasting_screen.dart';

class ForecastingButton extends StatelessWidget {
  const ForecastingButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ForecastingScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.online_prediction),
            SizedBox(height: 8),
            Text('Forecasting'),
          ],
        ),
      ),
    );
  }
}
