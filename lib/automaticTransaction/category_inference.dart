
// category_inference.dart

import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
//import 'package:tflite_flutter/tflite_flutter.dart';

/// A helper that infers a transaction category from its description
/// First tries a simple keyword map, then falls back to a local TFLite model.
class CategoryInference {
  /// A simple keyword→category map for the most common merchants.
  static const Map<String, String> _keywordMap = {
    'carrefoursa': 'market',
    'market': 'market',
    'macromar': 'market',
    'kas ith': 'market',
    'simit sarayi': 'restaurant',
    'gift shop': 'market',
    'enginyucelen': 'restaurant',
    'havalanlari': 'transportation',

  };
}
/*
  static Interpreter? _interpreter;

  /// Call once on app startup to load the TFLite model for fallback classification.
  static Future<void> loadModel({String assetPath = 'assets/model.tflite'}) async {
    _interpreter = await Interpreter.fromAsset(assetPath);
  }

  /// Infer the category for a given [description].
  /// Returns a keyword match if found, otherwise uses the local ML model.
  static Future<String> inferCategory(String description) async {
    final descLower = description.toLowerCase();

    // 1) Keyword mapping
    for (final entry in _keywordMap.entries) {
      if (descLower.contains(entry.key)) {
        return entry.value;
      }
    }

    // 2) Fallback to local ML model
    return _predictWithModel(description);
  }

  /// Internal: run the tflite interpreter to predict a category label index,
  /// then map it back to a string label. You'll need to adjust this to your model.
  static String _predictWithModel(String description) {
    if (_interpreter == null) {
      // Model not loaded – return default
      return 'automatic transaction';
    }

    // TODO: Preprocess the description into model input (e.g. token IDs, embeddings).
    // This is highly model-specific; replace with your own preprocessing.
    final input = _textToInputVector(description);

    // Allocate output buffer – assume model outputs a fixed-size float array.
    final output = List.filled(_labelMap.length, 0.0).reshape([1, _labelMap.length]);

    _interpreter!.run(input, output);

    // Find the index with highest probability
    final probs = output[0] as List<double>;
    final maxIndex = probs.indexWhere((p) => p == probs.reduce(max));

    // Map that index back to a category label
    return _labelMap[maxIndex];
  }

  /// Convert raw text into model input. Replace with your real preprocessing.
  static List<List<double>> _textToInputVector(String description) {
    // Example stub: return a zero-vector input
    // Your model might expect token IDs or embeddings here.
    return [List.filled(_labelMap.length, 0.0)];
  }

  /// A list of labels in the same order as your model's output nodes.
  /// You must replace these with the actual labels your model was trained on.
  static const List<String> _labelMap = [
    'groceries',
    'dining',
    'transportation',
    'gifts',
    'education',
    'travel',
    // add more categories matching your model's output
  ];
}
 */
