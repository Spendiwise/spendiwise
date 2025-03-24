class Transaction {
  final String date;
  final String description;
  final double amount;

  Transaction({
    required this.date,
    required this.description,
    required this.amount,
  });

  @override
  String toString() {
    return "- $date\n$description\n₺${amount.toStringAsFixed(2)}\n";
  }
}

class TextParser {
  static final RegExp dateRegex = RegExp(r'\d{2}/\d{2}/\d{4}');
  static final RegExp amountRegex = RegExp(r'\d{1,3}(\.\d{3})*,\d{2}');

  static List<Transaction> extractTransactions(String ocrText) {
    final List<Transaction> transactions = [];
    final lines = ocrText.split('\n');

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final dateMatch = dateRegex.firstMatch(line);

      if (dateMatch != null) {
        final date = dateMatch.group(0)!;
        String fullDescription = line.substring(dateMatch.end).trim();

        int j = i + 1;
        while (j < lines.length && !dateRegex.hasMatch(lines[j])) {
          fullDescription += ' ${lines[j].trim()}';
          j++;
        }

        final amountMatches = amountRegex.allMatches(fullDescription);
        if (amountMatches.isNotEmpty) {
          final amountMatch = amountMatches.last;
          final amountString = amountMatch.group(0)!;
          final amount = double.tryParse(
            amountString.replaceAll('.', '').replaceAll(',', '.'),
          );

          String description = fullDescription.substring(0, amountMatch.start).trim();

          final descriptionWords = description.split(RegExp(r'\s+'));
          description = descriptionWords.take(2).join(' ');

          if (amount != null) {
            transactions.add(Transaction(
              date: date,
              description: description,
              amount: amount,
            ));
          }
        }

      } else {
        i++;
      }
    }

    return transactions;
  }
}