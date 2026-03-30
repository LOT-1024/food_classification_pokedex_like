import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ml_service.dart';
import 'result_screen.dart';
import 'cropper_screen.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && context.mounted) {
      final croppedImage = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CropperScreen(imagePath: image.path),
        ),
      );

      if (croppedImage != null && context.mounted) {
        final result = await MLService().analyzeImage(croppedImage);
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                imagePath: croppedImage,
                prediction: result['prediction'],
                confidence: result['confidence'],
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose from Gallery'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 100, color: Colors.green.shade300),
            const SizedBox(height: 24),
            const Text(
              'Select a photo from your gallery',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _pickImage(context),
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose Photo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
