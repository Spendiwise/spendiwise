// text_parser.dart

import 'dart:math';

/// A single financial transaction
class Transaction {
  final String date;
  final String description;
  final double amount;
  final bool isIncome;
  final String category;

  Transaction({
    required this.date,
    required this.description,
    required this.amount,
    this.isIncome = false,
    this.category = 'automatic transaction',
  });

  /// Convert this object into a map for Firebase
  Map<String, dynamic> toJson() => {
    'date': date,
    'description': description,
    'amount': amount,
    'isIncome': isIncome,
    'category': category,
  };

  @override
  String toString() {
    return '- $date\n'
        '$description\n'
        '₺${amount.toStringAsFixed(2)} '
        '(${isIncome ? "Income" : "Expense"}) '
        '[$category]';
  }
}

/// Parse raw OCR text into a list of [Transaction]s by matching
/// each date with the first >10₺ amount until the next date.
class TextParser {
  // Match dates in format dd/MM/yyyy anywhere
  static final RegExp _dateRegex = RegExp(r'(\d{2}/\d{2}/\d{4})');
  // Match amounts like 1.234,56 or 12,34
  static final RegExp _amountRegex = RegExp(r'\d{1,3}(?:\.\d{3})*,\d{2}');

  static List<Transaction> extractTransactions(String ocrText) {
    final List<Transaction> transactions = [];

    // Find all date positions
    final dateMatches = _dateRegex.allMatches(ocrText).toList();
    // Find all amount positions
    final amountMatches = _amountRegex.allMatches(ocrText).toList();

    for (var i = 0; i < dateMatches.length; i++) {
      final dateMatch = dateMatches[i];
      final date = dateMatch.group(1)!;

      // Determine boundary: either next date or end of text
      final nextDateStart = (i + 1 < dateMatches.length)
          ? dateMatches[i + 1].start
          : ocrText.length;

      // Search for first valid amount (>10₺) between date and nextDateStart
      Match? chosenAmountMatch;
      double? amountValue;
      for (final am in amountMatches) {
        if (am.start > dateMatch.end && am.start < nextDateStart) {
          final parsed = double.tryParse(
              am.group(0)!.replaceAll('.', '').replaceAll(',', '.'));
          if (parsed != null && parsed > 10.0) {
            chosenAmountMatch = am;
            amountValue = parsed;
            break;
          }
        }
      }

      if (chosenAmountMatch == null || amountValue == null) {
        // no valid amount for this date
        continue;
      }

      // Extract description: text between end of date and start of amount
      var description =
      ocrText.substring(dateMatch.end, chosenAmountMatch.start);

      // Replace newlines and collapse spaces
      description = description.replaceAll('\n', ' ').trim();
      description = description.replaceAll(RegExp(r'\s+'), ' ');

      // Fallback: if still empty, take first two words after date
      if (description.isEmpty) {
        final snippetEnd =
        min(ocrText.length, dateMatch.end + 50); // up to 50 chars
        final snippet = ocrText.substring(dateMatch.end, snippetEnd);
        final words = snippet.split(RegExp(r'\s+'));
        description = words.take(2).join(' ');
      }

      transactions.add(Transaction(
        date: date,
        description: description,
        amount: amountValue,
      ));
    }

    return transactions;
  }
}
