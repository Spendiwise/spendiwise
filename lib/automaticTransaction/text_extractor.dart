/*import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'text_parser.dart';

class TextExtractor {
  static Future<void> extractTextFromImage({
    required BuildContext context,
    required File imageFile,
  }) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final RecognizedText recognizedText =
    await textRecognizer.processImage(inputImage);

    String extractedText = recognizedText.text;

    final List<Transaction> parsedTransactions =
    TextParser.extractTransactions(extractedText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extracted Transactions'),
        content: SingleChildScrollView(
          child: Text(
            parsedTransactions.isNotEmpty
                ? parsedTransactions.map((txn) => txn.toString()).join('\n')
                : 'No transactions found.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    textRecognizer.close();
  }
}
*/
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'text_parser.dart';

class TextExtractor {
  static Future<void> extractTextFromImage({
    required BuildContext context,
    required File imageFile,
  }) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final RecognizedText recognizedText =
    await textRecognizer.processImage(inputImage);

    String extractedText = recognizedText.text;

    // Display the extracted text in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extracted Text'),
        content: SingleChildScrollView(
          child: Text(extractedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    textRecognizer.close();
  }
}