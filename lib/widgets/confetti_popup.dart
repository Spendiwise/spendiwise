// lib/widgets/confetti_popup.dart

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

/// Shows a dialog with confetti blast when a goal is completed.
Future<void> showConfettiPopup(BuildContext context, String goalTitle) async {
  final controller = ConfettiController(duration: Duration(seconds: 3));
  controller.play();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti animation
          ConfettiWidget(
            confettiController: controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            maxBlastForce: 20,
            minBlastForce: 5,
            gravity: 0.1,
          ),
          // Dialog content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.celebration, size: 48, color: Colors.green),
                SizedBox(height: 8),
                Text(
                  'Congratulations!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'You have completed your goal\n"$goalTitle"!',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  controller.dispose();
}
