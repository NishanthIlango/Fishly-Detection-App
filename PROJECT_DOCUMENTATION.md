# Fish Detection App (Flutter)

## Overview
Fish Detection is a Flutter mobile application that performs on-device fish species detection using a **TorchScript object detection model** via the `flutter_pytorch` plugin. The app presents a splash screen, then a home screen where users can:
- Capture an image using the camera
- Select an image from the gallery
- Run fish detection
- Visualize detection boxes and confidence (score)

A secondary “Detection Results” screen exists in the codebase but is currently not wired into the navigation flow from the entry pages.

## Problem Statement
Users need a fast way to identify fish species from images (camera/gallery) without relying on a remote server. The application should:
- Load an on-device ML model
- Accept user images
- Produce detection results (class + confidence)
- Display results in a user-friendly way

## Objectives
- Provide a Flutter UI for image input (camera/gallery)
- Load a TorchScript detection model and labels from app assets
- Run object detection on selected images
- Render bounding boxes and show confidence score
- Maintain app responsiveness with loading states
- Package and configure model/label assets for Android/iOS/web/desktop

## Features
- Splash screen with timed navigation to Home
- Image capture using `image_picker`
- Image selection from gallery using `image_picker`
- On-device inference using `flutter_pytorch`
- Bounding box overlay rendering using `renderBoxesOnImage`
- Confidence score visualization using `SpeedometerChart`
- Carousel of example fish images (assets) and species names (label mapping in code)
- Loading indicator while model loads or inference runs
- Android permissions for camera and external storage

## Tech Stack
- **Flutter** (Material UI, Material 3)
- **Dart**
- **flutter_pytorch** (TorchScript model inference)
- **image_picker** (camera/gallery input)
- **SpeedometerChart** (confidence visualization)
- **carousel_slider** (example images carousel)
- **iconly** (icons)
- Platform build targets: **Android, iOS, Web, Windows** (desktop runner code present)

## Dependencies Used
From `pubspec.yaml`:
- `flutter_pytorch: ^1.0.1`
- `image_picker: ^0.8.7+5`
- `speedometer_chart: ^1.0.8`
- `carousel_slider: ^5.0.0`
- `iconly: ^1.0.1`
- `gif: ^2.3.0` (not clearly used in the inspected Dart files)
- `onboarding: ^4.0.2` (not clearly used in inspected Dart files)
- `cupertino_icons`, `win32`, `flutter_lints`, `flutter_test`, etc.

## Project Architecture
This project is implemented as a **feature-first / single-layer UI architecture**:
- There is no explicit Clean Architecture, MVVM, repository/service layers, or state management library (no Provider/GetX/BLoC/Riverpod observed).
- Business logic (model loading + inference) lives directly in **StatefulWidgets**:
  - `HomeScreen` contains model loading, inference, and UI state updates.
  - `DetectionResultScreen` duplicates the same logic pattern.

## Folder Structure
Key folders and responsibilities:

- `lib/`
  - `main.dart`
    - App entry point; sets `MaterialApp` theme and initial route/screen.
  - `design/`
    - `app_color.dart` defines color constants (`AppColor`), currently not used by the inspected screens.
  - `pages/`
    - `splash_screen/`
      - Splash UI and timed navigation to Home.
    - `home_screen/`
      - Main UI: model load, image selection, inference, and rendering.
    - `loader_state.dart`
      - `DetectionResultScreen`: an alternate detection-results UI (not wired from the inspected navigation flow).
- `assets/`
  - `assets/image/`
    - Splash and sample fish images used in UI (carousel/backgrounds).
  - `assets/models/`
    - ML models and labels:
      - `Trained_100eps_v5.torchscript`
      - `label.txt`
- `android/`
  - Android Gradle config and permissions.
- `ios/`
  - iOS Info.plist config.
- `web/`
  - Web index.html and manifest.json (template-level).
- `windows/`
  - Standard Flutter Windows runner C++ code (template-level).
- `test/`
  - Basic widget test template (counter smoke test, does not match app behavior).

## Application Flow

### App Launch → Splash → Home
1. `main.dart`
   - Runs `MyApp()`.
   - `MaterialApp(home: SplashScreen())`
2. `SplashScreen` (`lib/pages/splash_screen/splash_screen.dart`)
   - In `initState`, starts a `Timer(Duration(seconds: 2))`.
   - After 2 seconds, performs:
     - `Navigator.pushReplacement(... HomeScreen())`
3. `HomeScreen` (`lib/pages/home_screen/home_screen.dart`)
   - Calls `loadModel()` in `initState`.
   - Shows a loading spinner until model load completes.
   - User taps floating action button to toggle camera/gallery actions.
   - User selects/captures an image:
     - sets `_image`
     - calls `detectImage(_image!)`
   - After inference:
     - displays overlay boxes via `renderBoxesOnImage`
     - displays predicted class and confidence chart

### Detection Results Screen (Unused)
- `DetectionResultScreen` exists in `lib/pages/loader_state.dart`.
- It loads the same model and performs detection similarly.
- However, from the inspected code, it is not navigated to anywhere (no `Navigator.push` to it in the read screens).

## Screen Documentation

### 1) SplashScreen
**File:** `lib/pages/splash_screen/splash_screen.dart`  
**Purpose:** Show a splash UI for ~2 seconds, then navigate to `HomeScreen`.

**UI Components:**
- `Scaffold` with `body: Stack`
- Gradient background (linear gradient: dark blue to light blue)
- Splash image: `assets/image/splash_screen.png`
- Title text: “Fish Detection App”
- (Commented-out “Get Started” button exists but is not active)

**Functionalities:**
- Uses `Timer` in `initState` to navigate after 2 seconds.

**Navigation:**
- `Navigator.pushReplacement` → `HomeScreen()`

**State Management:**
- `SplashScreen` is a `StatefulWidget`
- No external state management library; navigation happens via timer.

**Important Widgets / Logic:**
- `Timer(Duration(seconds: 2), () { Navigator.pushReplacement(...) })`

**Related Files:**
- `lib/pages/home_screen/home_screen.dart`

---

### 2) HomeScreen
**File:** `lib/pages/home_screen/home_screen.dart`  
**Purpose:** Main app screen for:
- loading the ML model
- selecting image from camera/gallery
- running detection
- rendering results (boxes + confidence)

**UI Components:**
- `Scaffold`
  - `AppBar`
    - Background color: `Color.fromARGB(255, 17, 92, 154)`
    - Back icon appears only when `_image != null`; clears `_image` on press
  - Background gradient layer in `Stack`
  - Foreground content in `SingleChildScrollView`
  - Floating action button (FAB) stack:
    - main scan FAB toggles `showIcons`
    - when `showIcons == true`, shows two FABs:
      - Camera (calls `pickImage`)
      - Gallery (calls `pickGalleryImage`)
  - When `_image == null`:
    - Intro text (“Discover your fish partner”)
    - “Detectable fishes” + `CarouselSlider` with sample fish images and names
  - When `_image != null`:
    - If `_loading`: `CircularProgressIndicator`
    - Else: shows:
      - Title: “Detected fish partner”
      - Detection overlay:
        - `_objectModel.renderBoxesOnImage(_image!, objDetect)`
      - Confidence display:
        - Uses `_output!.first.score * 100`
        - `SpeedometerChart`
      - Predicted label:
        - `_output!.first.className`

**Functionalities (Business Logic):**
- **Model loading** (`loadModel`)
  - Loads object detection model:
    - model path: `assets/models/Trained_100eps_v5.torchscript`
    - classes: `6`
    - input size: `640 x 640`
    - label file: `assets/models/label.txt`
- **Inference** (`detectImage`)
  - Reads bytes from `File`:
    - `await image.readAsBytes()`
  - Calls:
    - `_objectModel.getImagePrediction(..., minimumScore: 0.5, IOUThershold: 0.3)`
  - Stores predictions in `_output`
  - Sets loading false
- **Image input**
  - Camera:
    - `picker.getImage(source: ImageSource.camera)`
  - Gallery:
    - `picker.getImage(source: ImageSource.gallery)`
- **Rendering**
  - Confident output displayed from `_output!.first` only
  - Boxes rendered via `renderBoxesOnImage(_image!, objDetect)`

**Navigation:**
- Direct navigation to other screens is not present in the inspected HomeScreen logic.
- All interaction occurs on the same screen.

**State Management:**
- Pure local state with `setState`:
  - `_loading`, `_image`, `_output`, `showIcons`
- Model instance stored in `late ModelObjectDetection _objectModel`

**Important Widgets / Logic:**
- Model call parameters:
  - `minimumScore: 0.5`
  - `IOUThershold: 0.3` (spelled as in code; should correspond to IOU threshold)
- Output usage:
  - Only the first detection is used for label + score chart.

**Related Files:**
- `lib/pages/loader_state.dart` (duplicate detection UI logic)
- `assets/models/Trained_100eps_v5.torchscript`
- `assets/models/label.txt`
- `assets/image/*`

---

### 3) DetectionResultScreen (Detection Results)
**File:** `lib/pages/loader_state.dart`  
**Purpose:** Alternate screen to show detection results for a provided image.

**UI Components:**
- `Scaffold` with `AppBar` titled “Detection Results”
- `body`:
  - while `_loading`: `CircularProgressIndicator`
  - else:
    - title: “Detected fish partner”
    - `Image.file(widget.image, height: 200)`
    - if detections exist:
      - predicted class name (first detection)
      - `SpeedometerChart` based on first detection score
      - confidence text (first detection)
    - else:
      - “No objects detected.”

**Functionalities:**
- `initState` calls `loadModelAndDetect()`
- Loads same TorchScript model and labels as HomeScreen
- Calls `getImagePrediction` on `widget.image.readAsBytes()`
- Stores output in `_output`

**Navigation:**
- Uses `Navigator.pop(context)` on back button
- However, it is not referenced from the inspected `main.dart`/`SplashScreen`/`HomeScreen`.

**State Management:**
- Local `setState` and `late ModelObjectDetection`.

**Important Widgets / Logic:**
- Uses `SpeedometerChart` with:
  - `value: _output!.first.score * 100`

**Related Files:**
- `lib/pages/home_screen/home_screen.dart` (logic duplication)

---

## Routing Flow
- `lib/main.dart`
  - App starts with `SplashScreen`
- `SplashScreen`
  - After 2 seconds: navigates to `HomeScreen` using `pushReplacement`

**Other routing:**
- `DetectionResultScreen` is not part of the routing flow in the inspected screens.

## State Management
No external state management library is used.
- `SplashScreen`: timer-based navigation
- `HomeScreen`: local `State` variables updated by `setState`
  - `_loading`: controls spinner
  - `_image`: controls whether results section is displayed
  - `_output`: holds detection results
  - `showIcons`: toggles camera/gallery FAB row
- `DetectionResultScreen`: similar local state management

## Business Logic

### Model Loading and Inference
There are no separate service/controller/repository classes. The business logic is embedded in widgets.

#### HomeScreen (`_HomeScreenState`)
- `loadModel()`
  - `FlutterPytorch.loadObjectDetectionModel(...)`
- `detectImage(File image)`
  - `_objectModel.getImagePrediction(...)`
  - stores output in `_output`

#### DetectionResultScreen (`_DetectionResultScreenState`)
- `loadModelAndDetect()`
  - loads model then calls `detectImage()`
- `detectImage()`
  - runs inference on `widget.image`

## Fish Detection Module

### Image Selection
- **Camera**
  - `ImagePicker().getImage(source: ImageSource.camera)`
- **Gallery**
  - `ImagePicker().getImage(source: ImageSource.gallery)`

### Model Loading
- Model file:
  - `assets/models/Trained_100eps_v5.torchscript`
- Labels:
  - `assets/models/label.txt`
- Model configuration:
  - classes: `6`
  - input size: `640 x 640`

### Detection Pipeline
1. Set `_loading = true`
2. Convert image to bytes:
   - `await image.readAsBytes()`
3. Call:
   - `_objectModel.getImagePrediction(bytes, minimumScore: 0.5, IOUThershold: 0.3)`
4. Cast results to:
   - `List<ResultObjectDetection>`

### Prediction Output
- Stored in `_output`
- **UI uses `_output!.first` only**
  - className displayed as detected species label
  - score used for confidence chart

### Confidence Score
- Chart value:
  - `_output!.first.score * 100`
- Confidence text:
  - `(_output!.first.score * 100).toStringAsFixed(0)}% Confident`

### Bounding Boxes
- HomeScreen renders boxes via:
  - `_objectModel.renderBoxesOnImage(_image!, objDetect)`
- Note: `objDetect` is initialized but not clearly populated in the provided `HomeScreen` code. This is likely a bug or incomplete integration.

### Species Classification
- Classification displayed as:
  - `_output!.first.className`
- Label mapping:
  - `assets/models/label.txt` contains 6 lines corresponding to classes.
- Additionally, HomeScreen has local arrays:
  - `urlNames` with 6 fish names + “Unlabeled”
  - Those names are used only for carousel display, not for inference mapping.

### Error Handling
- Model load:
  - `try/catch` with `print("Error loading model: $e")`
  - sets `_loading = false`
- Detection:
  - no dedicated try/catch in HomeScreen’s `detectImage` (only prints debug output after prediction)
- DetectionResultScreen:
  - wraps detection in try/catch and sets `_loading = false`

## Models
### ML Model Files (Assets)
- `assets/models/Trained_100eps_v5.torchscript`
  - TorchScript model loaded by `FlutterPytorch.loadObjectDetectionModel`
- `assets/models/label.txt`
  - Class labels used by the model loader

### Dart Model Classes
No custom ML model classes were created in this repo.
- `ModelObjectDetection`, `ResultObjectDetection` come from `flutter_pytorch`.

## Services
No standalone services exist in the inspected code.
- Model loading and inference are handled inside widgets.

## Repository Layer
No repository layer exists in the inspected codebase.

## API Integration
No backend API calls exist in this project.
- All inference is performed on-device.

## Local Storage
No local storage is implemented in the inspected Dart files.
- No SharedPreferences/Hive/SQLite usage found.

## Firebase Integration
No Firebase usage found in the inspected code:
- No `firebase_*` packages referenced in `pubspec.yaml`
- No Firebase initialization code present in the inspected Dart files

### Authentication / Firestore / Storage / Messaging / Analytics / Crashlytics
Not applicable (not present).

## Reusable Widgets
- There is one reusable UI builder in HomeScreen:
  - `Widget buildImage(String urlImage, String fishName, int index)`
- No separate widget files were created.

## Theme System
- `MaterialApp` theme is configured in `lib/main.dart`:
  - `colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)`
  - `useMaterial3: true`
- `AppColor` exists in `lib/design/app_color.dart`, but is not referenced by the inspected screens.

## Assets
### Images / Icons
- `assets/image/splash_screen.png` used in splash UI
- `assets/image/water_background.png`, `assets/image/splash_back.png`, `assets/image/splash.png`
  - Present but not confirmed used in inspected Dart files
- Sample fish images used in carousel:
  - `assets/image/1.png`, `2.png`, `3.png`, `4.jpg`, `5.jpg`

### Fonts
- `assets/fonts/Ubuntu-Regular.ttf`
  - Used in HomeScreen text: `fontFamily: 'Ubuntu'`

### ML Models and Labels
- `assets/models/Trained_100eps_v5.torchscript`
- `assets/models/label.txt`

## Configuration Files

### `pubspec.yaml`
- Declares assets and dependencies
- Includes `assets/image/` and `assets/models/`
- Adds Ubuntu font family mapping

### `analysis_options.yaml`
- Uses `package:flutter_lints/flutter.yaml`
- No custom lint overrides included besides commented options

### Android
#### `android/app/src/main/AndroidManifest.xml`
- Permissions:
  - `CAMERA`
  - `WRITE_EXTERNAL_STORAGE`
  - `READ_EXTERNAL_STORAGE`
- MainActivity is declared with Flutter embedding metadata

#### `android/app/build.gradle`
- Java/Kotlin compatibility:
  - Java 17 / Kotlin 17
- `aaptOptions`:
  - `noCompress 'tflite'`
  - `noCompress 'lite'`
  - (No explicit `noCompress` for `.torchscript`, but TorchScript is a file extension commonly managed by platform and plugin requirements)

#### `android/gradle.properties`
- Gradle JVM args and AndroidX settings

### iOS
#### `ios/Runner/Info.plist`
- Standard Flutter iOS plist
- Note: Camera permission usage strings (e.g., `NSCameraUsageDescription`) are not visible in the file content read.
  - In iOS, failing to include camera usage strings can break camera access at runtime.

### Web
#### `web/index.html`
- Standard Flutter web template with base href injection and flutter.js

#### `web/manifest.json`
- Standard PWA-ish metadata (icons + theme/background colors)

## Performance Optimizations
What’s present (and what’s not):
- Present:
  - Model load is done once in `initState` (`HomeScreen.loadModel`)
  - Loading spinner displayed during model load and during inference
- Not clearly present:
  - No explicit image preprocessing optimization beyond byte reading
  - No caching for prediction overlays
  - No batching or async isolates (inference call is awaited directly)
  - No throttling/debouncing on repeated captures

## Security Considerations
- The app does not include authentication or network calls.
- Android storage permissions are declared (`READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`).
  - On modern Android versions, storage permissions may be unnecessary depending on scoped storage usage and image picker behavior.
- iOS camera permission strings are not confirmed present (potential runtime failure).

## Error Handling
- Model loading:
  - HomeScreen uses try/catch and sets `_loading = false`
- Detection:
  - HomeScreen’s `detectImage` does not wrap inference with try/catch (only prints debug info)
  - DetectionResultScreen wraps inference with try/catch and sets `_loading = false`
- Navigation:
  - SplashScreen navigation is not guarded if HomeScreen build fails (assumes normal operation)

## Code Quality Review

### Good Practices
- Model loading separated into a dedicated method (`loadModel`)
- Uses loading state to avoid showing stale UI
- Clear separation of “image selection” and “detection” functions inside HomeScreen

### Bad Practices / Issues
1. **Duplicate logic across screens**
   - `HomeScreen` and `DetectionResultScreen` both implement the same model loading + inference logic with only minor differences.
2. **Potential bug: bounding box input list (`objDetect`)**
   - In HomeScreen:
     - `objDetect` is initialized empty
     - but `_objectModel.renderBoxesOnImage(_image!, objDetect)` uses `objDetect`, not `_output`
   - Inference results are stored in `_output`, not `objDetect`.
   - This suggests bounding boxes may not render correctly.
3. **Only first detection is displayed**
   - `_output!.first` is used for class name and confidence chart.
   - If multiple fish are detected, the UI ignores all but the first.
4. **No try/catch around inference in HomeScreen**
   - If inference fails, the app may remain in an inconsistent loading state or crash depending on thrown errors.
5. **Unused / redundant imports**
   - `flutter_pytorch/pigeon.dart` is imported in HomeScreen, but not referenced in the shown code.
6. **Test mismatch**
   - `test/widget_test.dart` contains a counter smoke test unrelated to the current UI.

### Potential Bugs
- Bounding boxes likely not based on `_output`.
- Confidence and label display assumes `_output` non-empty when `_output != null && _output!.isNotEmpty` is checked, but any mismatch between types/casts could still cause runtime issues.

### Performance Issues / Memory
- Large image bytes are read into memory on main isolate during inference.
- No downscaling/preprocessing shown (though model input size is configured to 640×640; plugin may handle resizing internally).

## Suggestions for Improvement (High → Low Priority)

1. **Fix bounding box rendering**
   - Use `_output` (or map it to the expected type) instead of `objDetect`.
   - Example intent: `renderBoxesOnImage(_image!, _output)` if types align.

2. **Unify detection logic**
   - Extract model loading + prediction into a shared utility/service to remove duplication between `HomeScreen` and `DetectionResultScreen`.

3. **Render all detections**
   - Display a list of all detected classes/scores or show the top-N.
   - Render boxes for all detections and show a more informative UI.

4. **Improve error handling in HomeScreen.detectImage**
   - Wrap inference in try/catch and ensure `_loading` is set false in `finally`.

5. **iOS camera permission**
   - Ensure `NSCameraUsageDescription` (and any needed photo/gallery usage descriptions) are present in `ios/Runner/Info.plist`.

6. **Remove unused dependencies/imports**
   - Clean up unused imports such as `flutter_pytorch/pigeon.dart` if not needed.

7. **Update tests**
   - Replace the template counter test with tests relevant to navigation, widget rendering, and detection state transitions (mock model).

8. **Consider architecture improvements**
   - Introduce a lightweight state management approach or at least extract logic into separate classes to improve maintainability.

## Future Scope
- Add multi-detection UI:
  - list of predictions with confidence thresholds
- Allow saving detected images with bounding boxes
- Add offline model management:
  - versioning and model updates (if desired)
- Add performance improvements:
  - background inference using isolates
  - image resizing pipeline
- Add user onboarding/tutorial screens (given `onboarding` dependency)
- Add robust analytics/error logging

## Build & Run Instructions

### Prerequisites
- Flutter installed
- Android SDK installed (for Android)
- Xcode installed (for iOS)
- (Optional) Windows build tools for Windows

### Steps
1. **Install dependencies**
   - `flutter pub get`
2. **Run the app**
   - Android: `flutter run`
   - iOS: `flutter run -d ios`
   - Web: `flutter run -d chrome`
   - Windows: `flutter run -d windows`
3. **Verify model assets**
   - Ensure `assets/models/Trained_100eps_v5.torchscript` and `assets/models/label.txt` are bundled.
4. **Camera testing**
   - Grant camera permission
   - Validate permission behavior on each platform

## Environment Variables
None required by the inspected code.

## Testing Status
- `test/widget_test.dart` is present but contains a default Flutter counter test unrelated to this app.
- No tests for detection, navigation, or error states are currently implemented.

## Conclusion
Fish Detection is a TorchScript-based, on-device Flutter application that detects fish species from camera/gallery images. The current implementation is functional in concept but contains notable code duplication and at least one likely issue in bounding box rendering due to using an unpopulated `objDetect` list instead of prediction output.

---

## Files Coverage Notes / Assumptions
- Documented Dart files:
  - `lib/main.dart`
  - `lib/pages/splash_screen/splash_screen.dart`
  - `lib/pages/home_screen/home_screen.dart`
  - `lib/pages/loader_state.dart`
  - `lib/design/app_color.dart`
- Documented configuration files read:
  - `pubspec.yaml`, `analysis_options.yaml`, `README.md`
  - Android: `AndroidManifest.xml`, `build.gradle`, `android/app/build.gradle`, `android/gradle.properties`
  - iOS: `ios/Runner/Info.plist`
  - Web: `web/index.html`, `web/manifest.json`
  - Windows runner: several template C++ files
- Assumptions explicitly called out:
  - iOS camera/gallery permission strings are not confirmed present from the read file.
  - No backend/API integration exists based on absence of network code in all inspected Dart files.
  - No local storage layer exists because no relevant packages or usage patterns were found in inspected Dart files.
