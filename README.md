# 🍽️ Food Recognizer

A Flutter mobile application that identifies food from photos using on-device machine learning, then provides recipe details and nutrition facts powered by TheMealDB API and Google Gemini AI.

---

## Features

- **Camera Capture** — Take a photo directly using the device camera
- **Gallery Import** — Pick an existing photo from the gallery
- **Image Cropping** — Crop and adjust the image before analysis
- **On-Device ML Inference** — Classifies food using a TFLite model running in a background isolate (no internet required for detection)
- **Recipe Information** — Fetches matching recipe, ingredients, and cooking instructions from TheMealDB
- **Nutrition Facts** — Retrieves calorie, protein, carb, fat, and fiber data via Google Gemini AI
- **Confidence Score** — Displays the model's prediction confidence as a progress bar

---

## App Flow

```
Home Screen
├── Take Photo → Camera Screen → Cropper → ML Inference → Result Screen
└── Choose from Gallery → Gallery Screen → Cropper → ML Inference → Result Screen

Result Screen
├── Detection result + confidence score
├── Recipe info (MealDB API)
└── Nutrition facts (Gemini AI)
```

---

## Project Structure

```
lib/
├── main.dart                  # App entry point, camera initialization
├── env/
│   ├── env.dart               # Envied config for API key loading
│   └── env.g.dart             # Generated obfuscated key file (do not edit)
├── screens/
│   ├── camera_screen.dart     # Live camera preview and capture
│   ├── cropper_screen.dart    # Image cropping UI
│   ├── gallery_screen.dart    # Gallery image picker
│   └── result_screen.dart     # Analysis results display
└── services/
    ├── ml_service.dart        # TFLite inference in a background isolate
    ├── gemini_service.dart    # Gemini AI nutrition facts API
    └── meal_db_service.dart   # TheMealDB recipe search API

assets/
├── model.tflite               # TFLite food classification model
└── labels.csv                 # Class labels for the model
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- A Google Gemini API key ([get one here](https://aistudio.google.com/app/apikey))
- Android or iOS device/emulator

### Installation

1. **Clone the repository**

   ```bash
   git clone <your-repo-url>
   cd food_recognizer
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Set up environment variables**

   Create a `.env` file in the project root:

   ```env
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

4. **Generate the env file**

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Add ML model assets**

   Place your TFLite model and labels file in the `assets/` directory:
   - `assets/model.tflite` — Food classification model (expects 224×224 RGB input)
   - `assets/labels.csv` — Class labels, one per line (supports `id,name` CSV format)

6. **Run the app**

   ```bash
   flutter run
   ```

---

## Dependencies

| Package | Purpose |
|---|---|
| `camera` | Live camera preview and capture |
| `image_picker` | Gallery image selection |
| `image_cropper` | Interactive image cropping |
| `tflite_flutter` | On-device TFLite model inference |
| `image` | Image decoding and resizing |
| `google_generative_ai` | Gemini AI for nutrition data |
| `http` | HTTP requests to TheMealDB |
| `envied` | Secure, obfuscated API key loading |
| `permission_handler` | Runtime camera permission requests |

---

## ML Model

- **Input:** 224×224 RGB image
- **Output:** Probability vector over food classes
- **Formats supported:** `float32` (normalized 0–1) and `uint8` (0–255) — auto-detected at runtime
- **Execution:** Runs in a Dart `Isolate` to keep the UI thread responsive

The labels file supports two formats:
- Plain list: one label per line
- CSV: `id,label_name` — the last column is used as the display name

---

## External APIs

### TheMealDB
- **Endpoint:** `https://www.themealdb.com/api/json/v1/1`
- **Usage:** Searches for recipes matching the predicted food name
- **Fallback:** Fuzzy search is attempted if the exact name returns no results
- **Key:** Free, no authentication required

### Google Gemini AI
- **Model:** `gemini-3.1-flash-lite-preview`
- **Usage:** Returns structured JSON with calories, protein, carbohydrates, fat, and fiber
- **Fallback:** Returns default mock values if the API call fails
- **Key:** Required — configured via `.env`

---

## Permissions

| Permission | Platform | Reason |
|---|---|---|
| `CAMERA` | Android & iOS | Live camera capture |
| `READ_EXTERNAL_STORAGE` / `Photos` | Android & iOS | Gallery image picker |

---

## Security Notes

- The Gemini API key is **obfuscated at build time** using `envied`. The `.env` file and `env.g.dart` should both be added to `.gitignore`.
- Never commit your `.env` file or raw API keys to version control.

Add to `.gitignore`:
```
.env
lib/env/env.g.dart
```

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.