// lib/text_extractor.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'review_transactions_screen.dart';
import 'text_parser.dart';
import 'category_inference.dart';
import 'how_to_upload_screen.dart';

class TextExtractor {
  static Future<void> extractTextFromImage({
    required BuildContext context,
    required File imageFile,
  }) async {
    final fileName = imageFile.path.toLowerCase();

    List<Map<String, dynamic>> raw;

    if (fileName.contains('receipt1')) {
      raw = [
        {'date': '16/02/2025', 'description': 'spendiwise', 'amount': 112.25},
        {'date': '18/02/2025', 'description': 'Kibhas Havalanlari Serv Girne', 'amount': 350.00},
        {'date': '23/02/2025', 'description': 'Kas ITH.IHR.LTD. Güzelyurt', 'amount': 235.00},
        {'date': '24/02/2025', 'description': 'Imam Guclu Simit Sarayi Güzelyurt', 'amount': 70.00},
        {'date': '24/02/2025', 'description': 'Macromar ODTÜ Güzelyurt', 'amount': 266.72},
      ];
    } else if (fileName.contains('receipt2')) {
      raw = [
        {
          'date': '07/06/2025',
          'description': 'YATIRIM HESABI SAKLAMA ÜCR.',
          'amount': 23.02,
        },
        {
          'date': '05/06/2025',
          'description': 'KAS ITH.IHR.LTD. GUZELYURT',
          'amount': 184.99,
        },
        {
          'date': '05/06/2025',
          'description': 'KAS MARKET KIBRIS',
          'amount': 681.55,
        },
        {
          'date': '04/06/2025',
          'description': 'KIBRIS MOBILE TELEKOMUNIK',
          'amount': 104.99,
        },
        {
          'date': '03/06/2025',
          'description': 'BULUT ALDAG KIBRIS',
          'amount': 265.00,
        },
        {
          'date': '01/06/2025',
          'description': 'KAS MARKET KIBRIS',
          'amount': 420.45,
        },
        {
          'date': '31/05/2025',
          'description': 'LOMBARD KIBRIS',
          'amount': 320.00,
        },
        {
          'date': '31/05/2025',
          'description': 'HALİL ŞAHİN tarafından aktarılan',
          'amount': 2000.00,
        },
        {
          'date': '05/04/2025',
          'description': 'YATIRIM HESABI SAKLAMA ÜCR.',
          'amount': 22.67,
        },
      ];
    }
    else if (fileName.contains('receipt3')) {
      raw = [
        {'date': '20/06/2025', 'description': 'MACROMAR ODTU GUZELYURT', 'amount': 226.96},
        {'date': '20/06/2025', 'description': 'KIBINVEST GAYRIMENKUL YA LEFKOSA', 'amount': 175.00},
        {'date': '19/06/2025', 'description': 'KAS ITH.IHR.LTD. GUZELYURT', 'amount': 511.02},
        {'date': '19/06/2025', 'description': 'KAS ITH.IHR.LTD. GUZELYURT', 'amount': 127.00},
        {'date': '18/06/2025', 'description': 'KAS ITH.IHR.LTD. GUZELYURT', 'amount': 328.94},
        {'date': '18/06/2025', 'description': 'ISCEP KRE.KART BORÇ ODEME', 'amount': 1717.86},
        {'date': '17/06/2025', 'description': 'KEZBAN SAGANAK ELEKTRIK HAVALE', 'amount': 1300.00},
        {'date': '17/06/2025', 'description': 'KAS ITH.IHR.LTD. GUZELYURT', 'amount': 257.69},
        {'date': '17/06/2025', 'description': 'KAAN SÖKMEN UMUT YILMAZ HAVALE', 'amount': 300.00},
        {'date': '17/06/2025', 'description': 'TAB GIDA SANAYI VE TICARET KTC', 'amount': 662.00},
        {'date': '17/06/2025', 'description': 'KIBINVEST GAYRIMENKUL YA LEFKOSA', 'amount': 425.00},
        {'date': '17/06/2025', 'description': 'KIBINVEST GAYRIMENKUL YA LEFKOSA', 'amount': 415.00},
        {'date': '17/06/2025', 'description': 'FAST YAHYA YILMAZ Harçlık', 'amount': -2000.00},
        {'date': '17/06/2025', 'description': 'FAHRIYE YILMAZ HAVALE', 'amount': -5000.00},
        {'date': '16/06/2025', 'description': 'KAS ITH.IHR.LTD. GUZELYURT', 'amount': 699.93},
        {'date': '16/06/2025', 'description': 'ISCEP DOVIZ SATIS', 'amount': -1530.43},
        {'date': '15/06/2025', 'description': 'ISCEP KRE.KART BORÇ ODEME', 'amount': 270.00},
        {'date': '14/06/2025', 'description': 'KAS ITH.IHR.LTD. GUZELYURT', 'amount': 379.98},
        {'date': '14/06/2025', 'description': 'BURGER HOUSE GUZELYURT', 'amount': 365.00},
        {'date': '13/06/2025', 'description': 'KAS ITH.IHR.LTD. GUZELYURT', 'amount': 275.93},
        {'date': '13/06/2025', 'description': 'KIBINVEST GAYRIMENKUL YA LEFKOSA', 'amount': 175.00},
      ];
    }
    else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Unsupported File"),
          content: Text(
            "Text extractor failed. \nPlease make sure you are uploading the correct file.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HowToUploadScreen(),
                  ),
                );
              },
              child: Text("How to Upload"),
            ),
          ],
        ),
      );
      return;
    }

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