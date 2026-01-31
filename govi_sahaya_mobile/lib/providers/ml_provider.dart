import 'dart:io';
import 'package:flutter/material.dart';
import '../services/ml_service.dart';
import '../models/disease_model.dart';

class MLProvider with ChangeNotifier {
  final MLService _mlService = MLService();

  DiseaseModel? _lastPrediction;
  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  DiseaseModel? get lastPrediction => _lastPrediction;
  File? get selectedImage => _selectedImage;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Set selected image
  void setSelectedImage(File? image) {
    _selectedImage = image;
    notifyListeners();
  }

  // Predict disease from image
  Future<void> predictDisease(File imageFile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastPrediction = await _mlService.predictDisease(imageFile);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear prediction
  void clearPrediction() {
    _lastPrediction = null;
    _selectedImage = null;
    _errorMessage = null;
    notifyListeners();
  }
}
