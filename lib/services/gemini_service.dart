import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../env/env.dart';

class GeminiService {
  final String _apiKey = Env.geminiApiKey;

  Future<Map<String, dynamic>> getNutritionInfo(String foodName) async {
    try {
      final schema = Schema.object(
        properties: {
          'calories': Schema.string(description: 'Total calories per serving'),
          'carbohydrates': Schema.string(description: 'Total carbs in grams'),
          'fat': Schema.string(description: 'Total fat in grams'),
          'fiber': Schema.string(description: 'Total fiber in grams'),
          'protein': Schema.string(description: 'Total protein in grams'),
        },
      );

      final model = GenerativeModel(
        model: 'gemini-3.1-flash-lite-preview',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: schema,
        ),
      );

      final prompt =
          'Provide accurate nutrition facts for a standard serving of $foodName.';
      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text == null) throw Exception('Empty response from Gemini');

      return jsonDecode(response.text!) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Gemini 3.1 Error: $e');
      return _getMockNutritionData(foodName);
    }
  }

  Map<String, dynamic> _getMockNutritionData(String foodName) {
    return {
      'calories': '350',
      'carbohydrates': '40',
      'fat': '15',
      'fiber': '3',
      'protein': '12',
    };
  }
}
