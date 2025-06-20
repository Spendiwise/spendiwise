// category_inference.dart

import 'dynamic_category_service.dart';

class CategoryInference {
  /// Static keyword→category rules
  static const Map<String, String> _keywordMap = {
    // Grocer
    'market': 'groceries',
    'supermarket': 'groceries',
    'macro market': 'groceries',
    'migros': 'groceries',
    'carrefoursa': 'groceries',
    'bim': 'groceries',
    'a101': 'groceries',
    'şok': 'groceries',
    'macromar': 'groceries',
    'kas ith': 'groceries',

    // Dining / Restaurants
    'restaurant': 'dining',
    'döner': 'dining',
    'kebap': 'dining',
    'simit sarayi': 'dining',
    'pide': 'dining',
    'burger': 'dining',
    'kfc': 'dining',
    'dominos': 'dining',
    'subway': 'dining',

    // Fuel / Auto
    'shell': 'fuel',
    'bp': 'fuel',
    'opet': 'fuel',
    'petrol': 'fuel',
    'gas': 'fuel',

    // Transportation
    'uber': 'transportation',
    'havalanlari': 'transportation',
    'otobus': 'transportation',

    // Shopping
    'shop': 'shopping',
    'hepsiburada': 'shopping',
    'trendyol': 'shopping',
    'amazon': 'shopping',
    'n11': 'shopping',

    // Entertainment
    'cinema': 'entertainment',
    'sinema': 'entertainment',
    'biletix': 'entertainment',
    'netflix': 'entertainment',
    'spotify': 'entertainment',
    'youtube': 'entertainment',

    // Health / sport
    'pharmacy': 'health',
    'eczane': 'health',
    'hastane': 'health',
    'hospital': 'health',
    'gym': 'health',
    'fitness': 'health',

    // Travel / Accommodation
    'hotel': 'travel',
    'booking.com': 'travel',
    'airbnb': 'travel',

    // … other static rules can add here
  };

  /// In-memory cache of dynamic mappings
  static Map<String, String> _dynamicMap = {};

  /// Must be called once at startup
  static Future<void> init() async {
    _dynamicMap = await DynamicCategoryService.fetchMappings();
  }

  /// Infer category: static first, then dynamic, else default.
  static String inferCategory(String description) {
    final key = description.toLowerCase().trim();

    // 1) Static rules
    for (final entry in _keywordMap.entries) {
      if (key.contains(entry.key)) {
        return entry.value;
      }
    }

    // 2) Dynamic user‐defined rules
    for (final entry in _dynamicMap.entries) {
      if (key.contains(entry.key)) {
        return entry.value;
      }
    }

    // 3) Fallback
    return 'automatic transaction';
  }

  /// Save a user‐defined mapping only if no static or dynamic rule applies.
  static Future<void> addUserMapping(
      String description, String category) async {
    final key = description.toLowerCase().trim();

    // If a static rule already covers this, skip
    for (final entry in _keywordMap.entries) {
      if (key.contains(entry.key)) return;
    }

    // If a dynamic rule already covers this, skip
    for (final entry in _dynamicMap.entries) {
      if (key.contains(entry.key)) return;
    }

    // Otherwise add new mapping
    await DynamicCategoryService.addMapping(key, category);
    _dynamicMap[key] = category;
  }
}