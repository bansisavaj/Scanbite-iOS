# Smart Food Scanner

Minimal MVP for scanning packaged food and showing an instant score card.

## Product stance

The app does not judge food. It explains what is inside so users can decide confidently.

Current UX:
- Big A-E health score
- One-line verdict
- Three highlights only
- One quick suggestion
- Skeleton loading while APIs respond

## Project structure

```text
SmartFoodScanner/
  SmartFoodScanner.xcodeproj
  SmartFoodScanner/
    SmartFoodScannerApp.swift
    ContentView.swift
    Models/
      Product.swift
      Nutrition.swift
      InsightResult.swift
      DietTypeResult.swift
      HealthSummary.swift
      IngredientAnalysis.swift
    ViewModels/
      HomeViewModel.swift
      ScannerViewModel.swift
      ProductViewModel.swift
      HistoryViewModel.swift
    Services/
      OpenFoodFactsService.swift
      InsightEngine.swift
      DietClassifierService.swift
      FoodDataService.swift
      HealthSummaryEngine.swift
      LocalFoodCacheService.swift
      OCRService.swift
      IngredientAnalysisEngine.swift
      FirebaseSupportService.swift
      LocationService.swift
      NotificationService.swift
    Views/
      HomeView.swift
      ScannerView.swift
      BarcodeScannerView.swift
      ProductResultView.swift
      IngredientsScannerView.swift
      IngredientCameraView.swift
      EducationView.swift
```

## Implemented MVP

- SwiftUI MVVM app
- One-tap barcode scanner using AVFoundation
- Manual barcode search
- Layered food data service
- OpenFoodFacts primary lookup
- USDA FoodData Central fallback through Firebase Remote Config key `usda_api_key`
- Local `UserDefaults` product cache for fast repeated lookups
- Firebase Analytics, Crashlytics, and Remote Config support
- Manual estimation fallback when APIs cannot resolve a product
- Rule-based `InsightEngine`
- Rule-based `HealthSummaryEngine`
- Ingredients photo scanner using AVFoundation camera capture
- OCR text extraction using Apple Vision `VNRecognizeTextRequest`
- Ingredient analysis for sugar, additives, allergens, diet type, and kids/elder tags
- Diet classifier for vegan, vegetarian, non-vegetarian, and uncertain cases
- Minimal result screen with A-E rating, verdict, three highlights, and one suggestion
- Education checklist screen
- CoreLocation shopping-awareness reminder with per-day, per-location cooldown

## Build

Open `SmartFoodScanner.xcodeproj` in Xcode and run the `SmartFoodScanner` scheme.

The project was checked with:

```sh
xcodebuild -project outputs/SmartFoodScanner/SmartFoodScanner.xcodeproj -scheme SmartFoodScanner -sdk iphonesimulator -configuration Debug -derivedDataPath work/DerivedData build
```

Build result: succeeded.
