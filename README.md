# كيفك  — Facial Expression Recognition App (Kayfak)

**كيفك** is a mobile application for real-time facial expression recognition using deep learning.  
The project combines a **MobileNetV3Large** convolutional neural network with **Supervised Contrastive Learning (SCL)** and deploys the trained model on Android using **TensorFlow Lite** and **Flutter**.

The application recognizes seven facial expression classes:

- 😠 Angry
- 🤢 Disgust
- 😨 Fear
- 😄 Happy
- 😐 Neutral
- 😢 Sad
- 😲 Surprise

---

## 📱 About the Project

This project was developed as part of a Master's project in Computer Science.

The main objective is to build an end-to-end facial expression recognition system covering:

**Dataset → Training → Evaluation → TFLite Conversion → Flutter Deployment**

The system uses the **FER2013** dataset and a transfer-learning approach based on **MobileNetV3Large**.

Supervised Contrastive Learning (SCL) is incorporated into the training strategy to improve the learned representation of facial expressions before final classification.

---

## 🧠 Model Architecture

The final model uses **MobileNetV3Large** pretrained on ImageNet as the backbone.

### Input

```text
224 × 224 × 3 RGB
```

### Backbone

```text
MobileNetV3Large
ImageNet pretrained weights
include_preprocessing = True
```

### Classification Head

```text
Input 224×224×3
        │
        ▼
MobileNetV3Large
        │
        ▼
7×7×960
        │
        ▼
Conv2D 1×1 — 256
        │
Batch Normalization
        │
       ReLU
        │
Global Average Pooling
        │
Dense 256
        │
Batch Normalization + ReLU
        │
Dropout
        │
Dense 128
        │
Batch Normalization + ReLU
        │
Dropout
        │
Dense 64 — Embedding
        │
        ▼
Dense 7 — Softmax
        │
        ▼
7 Facial Expressions
```

---

## 🔬 Supervised Contrastive Learning

The training methodology includes a **Supervised Contrastive Learning (SCL)** stage.

SCL encourages samples belonging to the same expression class to have closer representations in the embedding space while pushing representations from different classes farther apart.

The general training pipeline consists of:

```text
Stage 1
Supervised Contrastive Representation Learning
        ↓
Stage 2
Classification Training
        ↓
Stage 3
Fine-Tuning
        ↓
Final Model Selection
```

---

## 📊 Dataset

The project uses the **FER2013** facial expression dataset.

### Classes

| Class | Expression |
|---|---|
| 0 | Angry |
| 1 | Disgust |
| 2 | Fear |
| 3 | Happy |
| 4 | Neutral |
| 5 | Sad |
| 6 | Surprise |

The original FER2013 images are grayscale facial images. They are decoded as three-channel images and resized to the model input resolution.

---

## 📈 Final Model Performance

The final Keras model achieved:

| Metric | Result |
|---|---:|
| Test Accuracy | **64.39%** |
| Top-2 Accuracy | **80.89%** |
| Test Images | **7,178** |

The final exported Float16 TensorFlow Lite model was independently evaluated on the complete FER2013 test set.

### TFLite Results

| Metric | Result |
|---|---:|
| Accuracy | **64.22%** |
| Correct Predictions | **4,610 / 7,178** |

### Per-Class TFLite Accuracy

| Expression | Accuracy |
|---|---:|
| Angry | 51.57% |
| Disgust | 54.95% |
| Fear | 42.29% |
| Happy | 85.63% |
| Neutral | 65.21% |
| Sad | 52.85% |
| Surprise | 77.02% |

The small difference between the original model and the Float16 TFLite model is expected after model conversion and weight quantization.

---

## ⚡ TensorFlow Lite Deployment

The final model is exported using **Float16 weight quantization** for mobile deployment.

### TFLite Configuration

```text
Input Shape : [1, 224, 224, 3]
Input Type  : Float32
Input Range : 0–255
Output Shape: [1, 7]
Output Type : Float32
Weights     : Float16
```

Because preprocessing is included inside MobileNetV3Large, the Flutter application provides raw RGB values in the `0–255` range without manually dividing the input by 255.

---

## 📱 Flutter Application

The Flutter application provides an end-to-end mobile inference pipeline.

### Main Features

- 📷 Capture facial images using the camera
- 🖼️ Select images from the gallery
- 👤 Automatic face detection using Google ML Kit
- ✂️ Automatic face cropping and preprocessing
- 🧠 On-device TFLite inference
- 📊 Expression prediction and confidence
- 💾 Local result storage
- 🕘 Prediction history
- 🗑️ Delete stored results
- 🎨 Expression-specific colors and emojis
- 🔍 Debug tools for preprocessing and inference validation

All model inference is performed locally on the device.

---

## 🔄 Application Pipeline

```text
Camera / Gallery
        │
        ▼
Image Orientation Normalization
        │
        ▼
Google ML Kit Face Detection
        │
        ▼
Face Validation
        │
        ▼
Square Face Crop
        │
        ▼
Resize to 224×224 RGB
        │
        ▼
TensorFlow Lite
        │
        ▼
7-Class Softmax Output
        │
        ▼
Predicted Expression
        │
        ▼
Local History
```

---

## 🧪 Debug & Model Validation

A dedicated debugging workflow was implemented to verify consistency between Flutter and Python/TensorFlow Lite inference.

The application can export the **exact 224×224 image supplied to the TFLite model**.

The same image can then be evaluated directly using the TFLite interpreter in Python.

This validation confirmed that:

```text
Flutter preprocessing
        ↓
Exact model input
        ↓
Flutter TFLite inference
        ≈
Python TFLite inference
```

Matching predictions were obtained for identical model inputs, helping verify that the Flutter tensor construction and inference pipeline are consistent with the standalone TFLite environment.

---

## 🛠️ Technologies

### Machine Learning

- Python
- TensorFlow
- Keras
- MobileNetV3Large
- Supervised Contrastive Learning
- TensorFlow Lite
- NumPy
- Pandas
- Scikit-learn

### Mobile Application

- Flutter
- Dart
- TensorFlow Lite Flutter
- Google ML Kit Face Detection
- Camera
- Image Picker
- SQLite

---

## 📂 Project Structure

```text
lib/
├── main.dart
│
├── models/
│   ├── expression_prediction.dart
│   ├── expression_result.dart
│   ├── expression_statistics.dart
│   ├── face_quality_result.dart
│   └── debug_prediction_result.dart
│
├── screens/
│   ├── home_screen.dart
│   ├── camera_screen.dart
│   ├── preview_screen.dart
│   ├── result_screen.dart
│   ├── history_screen.dart
│   ├── result_details_screen.dart
│   └── debug_screen.dart
│
├── services/
│   ├── expression_classifier_service.dart
│   ├── face_detection_service.dart
│   ├── live_face_detection_service.dart
│   ├── face_quality_service.dart
│   ├── image_preprocessing_service.dart
│   ├── image_picker_service.dart
│   ├── image_storage_service.dart
│   ├── database_service.dart
│   └── debug_export_service.dart
│
├── utils/
│   ├── constants.dart
│   ├── image_utils.dart
│   └── expression_ui.dart
│
└── widgets/
    ├── expression_probability_bar.dart
    ├── saved_result_card.dart
    ├── statistics_card.dart
    └── face_guide_overlay.dart
```

---

## 🚀 Running the Application

### Requirements

- Flutter SDK
- Android SDK
- Android device or emulator
- Minimum Android SDK: 24

Clone the repository:

```bash
git clone https://github.com/ismail-omar/facial-expression-recognition.git
```

Enter the project:

```bash
cd facial-expression-recognition
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

---

## 📦 Building the Release APK

Build a standard release APK:

```bash
flutter build apk --release
```

For smaller architecture-specific APKs:

```bash
flutter build apk --release --split-per-abi
```

The generated APK files can be found under:

```text
build/app/outputs/flutter-apk/
```

> **Release note:** Code and resource shrinking are currently disabled in the Android release configuration to maintain compatibility and stability with the Google ML Kit face-detection pipeline.

---

## 🔖 Releases

### v1.0.0

First official stable release.

### v1.0.1 — ML Kit Release Stability Fix

- Fixed ML Kit face detection in release APK builds
- Fixed camera face validation in release mode
- Fixed gallery image processing in release mode
- Improved release-build stability
- Verified camera, gallery, prediction, storage, and deletion workflows

---

## ⚠️ Limitations

Facial expression recognition estimates **visible facial expressions** and should not be interpreted as a reliable measurement of a person's internal emotional state.

Prediction performance can also be affected by:

- Lighting conditions
- Head pose
- Facial occlusion
- Image quality
- Expression ambiguity
- Differences between FER2013 and real-world images

---

## 🎓 Academic Project

**Project:** Facial Expression Recognition using MobileNetV3Large and Supervised Contrastive Learning  
**Application:** كيفك  
**Program:** Master of Computer Science  
**Institution:** Syrian Virtual University  
**Year:** 2026

---

## 👨‍💻 Author

**Ismail Omar**

Master of Computer Science  
Syrian Virtual University

---

## 📄 License

This repository was developed for academic and research purposes.

Please review the repository's license before reuse or redistribution.
