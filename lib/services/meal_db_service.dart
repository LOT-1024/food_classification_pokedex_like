import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MealDBService {
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  String _cleanQuery(String query) {
    return query.replaceAll(RegExp(r'[0-9,]'), '').trim();
  }

  Future<Map<String, dynamic>?> searchMeal(String query) async {
    final cleanedQuery = _cleanQuery(query);

    if (cleanedQuery.isEmpty) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search.php?s=$cleanedQuery'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          return data['meals'][0];
        }
      }

      return await _fuzzySearch(cleanedQuery);
    } catch (e) {
      debugPrint('Error fetching meal info from MealDB: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fuzzySearch(String query) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/search.php?s='));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          final lowerQuery = query.toLowerCase();

          for (var meal in data['meals']) {
            String mealName = meal['strMeal'].toString().toLowerCase();
            if (mealName.contains(lowerQuery) ||
                lowerQuery.contains(mealName)) {
              return meal;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error during fuzzy search: $e');
    }
    return null;
  }
}
