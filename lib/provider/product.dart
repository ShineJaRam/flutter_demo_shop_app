import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isFavorite = false,
  });

  void _setFavValue(bool newValue) {
    isFavorite = newValue;
    notifyListeners();
  }

  Future<void> toggleFavoriteStatus(String? token, String userId) async {
    final oldStatus = isFavorite;
    final url =
        'https://flutter-demo-shop-app-e041e-default-rtdb.firebaseio.com/userFavorites/$userId/$id.json';
    isFavorite = !isFavorite;
    try {
      final response = await Dio().put(
        url,
        queryParameters: {
          'auth': token,
        },
        data: {
          'isFavorite': isFavorite,
        },
      );

      if (response.statusCode != null) {
        if (response.statusCode! >= 400) {
          _setFavValue(oldStatus);
        }
      }
    } catch (error) {
      _setFavValue(oldStatus);
    }
    notifyListeners();
  }
}
