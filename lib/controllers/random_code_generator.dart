import 'dart:math';

class RandomCodeGenerator {
  static String generateCode() {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
            (_) => characters.codeUnitAt(random.nextInt(characters.length)),
      ),
    );
  }
}