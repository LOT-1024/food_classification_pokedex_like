import 'dart:io';
import 'package:flutter/material.dart';
import '../services/meal_db_service.dart';
import '../services/gemini_service.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final String prediction;
  final double confidence;

  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.prediction,
    required this.confidence,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Map<String, dynamic>? _mealInfo;
  Map<String, dynamic>? _nutritionInfo;
  bool _isLoadingMeal = true;
  bool _isLoadingNutrition = true;

  @override
  void initState() {
    super.initState();
    _fetchMealInfo();
    _fetchNutritionInfo();
  }

  Future<void> _fetchMealInfo() async {
    final mealInfo = await MealDBService().searchMeal(widget.prediction);
    setState(() {
      _mealInfo = mealInfo;
      _isLoadingMeal = false;
    });
  }

  Future<void> _fetchNutritionInfo() async {
    final nutritionInfo = await GeminiService().getNutritionInfo(
      widget.prediction,
    );
    setState(() {
      _nutritionInfo = nutritionInfo;
      _isLoadingNutrition = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade200),
              child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detection Result',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.prediction,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: widget.confidence,
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confidence: ${(widget.confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recipe Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (_isLoadingMeal)
                    const Center(child: CircularProgressIndicator())
                  else if (_mealInfo != null &&
                      _mealInfo!.containsKey('strMeal'))
                    _buildMealInfoCard(),

                  const SizedBox(height: 24),

                  const Text(
                    'Nutrition Facts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (_isLoadingNutrition)
                    const Center(child: CircularProgressIndicator())
                  else if (_nutritionInfo != null)
                    _buildNutritionCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_mealInfo!['strMealThumb'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                _mealInfo!['strMealThumb'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mealInfo!['strMeal'] ?? widget.prediction,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_mealInfo!['strCategory'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Category: ${_mealInfo!['strCategory']}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                if (_mealInfo!['strArea'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Cuisine: ${_mealInfo!['strArea']}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 16),

                const Text(
                  'Ingredients:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._buildIngredientsList(),

                const SizedBox(height: 16),

                const Text(
                  'Instructions:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _mealInfo!['strInstructions'] ?? 'No instructions available',
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildIngredientsList() {
    List<Widget> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      String ingredient = _mealInfo!['strIngredient$i'] ?? '';
      String measure = _mealInfo!['strMeasure$i'] ?? '';
      if (ingredient.isNotEmpty && ingredient.trim().isNotEmpty) {
        ingredients.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(
                  child: Text(
                    '$measure $ingredient'.trim(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return ingredients;
  }

  Widget _buildNutritionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildNutritionRow(
              'Calories',
              _nutritionInfo!['calories'] ?? 'N/A',
              'kcal',
            ),
            _buildNutritionRow(
              'Carbohydrates',
              _nutritionInfo!['carbohydrates'] ?? 'N/A',
              'g',
            ),
            _buildNutritionRow('Fat', _nutritionInfo!['fat'] ?? 'N/A', 'g'),
            _buildNutritionRow('Fiber', _nutritionInfo!['fiber'] ?? 'N/A', 'g'),
            _buildNutritionRow(
              'Protein',
              _nutritionInfo!['protein'] ?? 'N/A',
              'g',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            '$value $unit',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
