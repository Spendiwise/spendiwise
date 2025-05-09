// lib/text_extractor.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'review_transactions_screen.dart';
import 'text_parser.dart';
import 'category_inference.dart';

class TextExtractor {
  static Future<void> extractTextFromImage({
    required BuildContext context,
    required File imageFile,
  }) async {

    // Raw manual data without category
    final raw = <Map<String, dynamic>>[
      {
        'date': '16/02/2025',
        'description': 'spendiwise',
        'amount': 112.25,
      },
      {
        'date': '18/02/2025',
        'description': 'Kibhas Havalanlari Serv Girne',
        'amount': 350.00,
      },
      {
        'date': '23/02/2025',
        'description': 'Kas ITH.IHR.LTD. Güzelyurt',
        'amount': 235.00,
      },
      {
        'date': '24/02/2025',
        'description': 'Imam Guclu Simit Sarayi Güzelyurt',
        'amount': 70.00,
      },
      {
        'date': '24/02/2025',
        'description': 'Macromar ODTÜ Güzelyurt',
        'amount': 266.72,
      },
    ];

    // Build Transaction list, inferring category automatically
    final manualTransactions = raw.map((entry) {
      final desc = entry['description'] as String;
      return Transaction(
        date: entry['date'] as String,
        description: desc,
        amount: entry['amount'] as double,
        isIncome: false,
        category: CategoryInference.inferCategory(desc),
      );
    }).toList();

    // Navigate to review screen
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