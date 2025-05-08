// text_extractor.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'review_transactions_screen.dart';
import 'text_parser.dart';

class TextExtractor {
  /// For prototype purposes, ignore OCR
  /// and just push a hard-coded list of 8 transactions.
  static Future<void> extractTextFromImage({
    required BuildContext context,
    required File imageFile,
  }) async {
    final manualTransactions = <Transaction>[
      Transaction(
        date: '16/02/2025',
        description: 'Carrefoursa Merter',
        amount: 112.25,
        isIncome: false,
        category: 'Market',
      ),
      Transaction(
        date: '18/02/2025',
        description: 'Kibhas Havalanlari Serv Girne',
        amount: 350.00,
        isIncome: false,
        category: 'Transport',
      ),
      Transaction(
        date: '19/02/2025',
        description: 'Macro Market ODTÜ Güzelyurt',
        amount: 188.96,
        isIncome: false,
        category: 'Market',
      ),
      Transaction(
        date: '23/02/2025',
        description: 'Kas ITH.IHR.LTD. Güzelyurt',
        amount: 235.00,
        isIncome: false,
        category: 'Market',
      ),
      Transaction(
        date: '24/02/2025',
        description: 'Imam Guclu Simit Sarayi Güzelyurt',
        amount: 70.00,
        isIncome: false,
        category: 'Market',
      ),
      Transaction(
        date: '24/02/2025',
        description: 'Imam Guclu Simit Sarayi Güzelyurt',
        amount: 10.00,
        isIncome: false,
        category: 'Market',
      ),
      Transaction(
        date: '24/02/2025',
        description: 'Engin Yucelen Gift Shop Kibris',
        amount: 10.00,
        isIncome: false,
        category: 'Rastaurant',
      ),
      Transaction(
        date: '24/02/2025',
        description: 'Macromar ODTÜ Güzelyurt',
        amount: 266.72,
        isIncome: false,
        category: 'Market',
      ),
    ];

    // Navigate directly to the review screen with our manual data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewTransactionsScreen(
          transactions: manualTransactions,
        ),
      ),
    );
  }
}




/*
// text_extractor.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'text_parser.dart';
import 'review_transactions_screen.dart';

class TextExtractor {
  static Future<void> extractTextFromImage({
    required BuildContext context,
    required File imageFile,
  }) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizer =
    TextRecognizer(script: TextRecognitionScript.latin);

    final result = await recognizer.processImage(inputImage);
    recognizer.close();

    final transactions = TextParser.extractTransactions(result.text);

    if (transactions.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('No Transactions Found'),
          content: Text('OCR did not extract any valid transactions.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Navigate to the review screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReviewTransactionsScreen(transactions: transactions),
      ),
    );
  }
}
*/