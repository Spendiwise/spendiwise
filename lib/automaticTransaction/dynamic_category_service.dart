// dynamic_category_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class DynamicCategoryService {
  static final CollectionReference _col =
  FirebaseFirestore.instance.collection('category_mappings');

  /// Fetch all existing pattern→category mappings,
  /// normalizing patterns to lowercase & trimmed.
  static Future<Map<String, String>> fetchMappings() async {
    final snapshot = await _col.get();
    final Map<String, String> map = {};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final rawPattern = data['pattern'] as String;
      final pattern = rawPattern.toLowerCase().trim();
      final category = data['category'] as String;
      map[pattern] = category;
    }
    return map;
  }

  /// Add a new mapping with server timestamp
  static Future<void> addMapping(String pattern, String category) async {
    // pattern passed in should already be lowercase & trimmed
    await _col.add({
      'pattern': pattern,
      'category': category,
    });
  }
}
