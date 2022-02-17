import 'package:flutter/material.dart';
import 'package:shop_app/models/http_exception.dart';
import 'product.dart';
import 'package:dio/dio.dart';

class Products with ChangeNotifier {
  static const url =
      'https://flutter-demo-shop-app-e041e-default-rtdb.firebaseio.com/products.json';
  final dio = Dio();

  late List<Product> _items = [];

  final String? authToken;
  final String userId;

  Products(this.authToken, this._items, this.userId);

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  // void showFavoritesOnly() {
  //   _showFavoritesOnly = true;
  //   notifyListeners();
  // }
  //
  // void showAll() {
  //   _showFavoritesOnly = false;
  //   notifyListeners();
  // }

  Future<void> fetchAndSetProducts() async {
    try {
      final response = await dio.get(url, queryParameters: {
        'auth': authToken,
      });
      final extractedData = response.data as Map<String, dynamic>;
      final tokenUrl =
          'https://flutter-demo-shop-app-e041e-default-rtdb.firebaseio.com/userFavorites/$userId.json';
      final favoriteResponse = await dio.get(tokenUrl, queryParameters: {
        'auth': authToken,
      });
      final favoriteData = favoriteResponse.data;
      final List<Product> loadedProducts = [];

      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          price: prodData['price'],
          imageUrl: prodData['imageUrl'],
          isFavorite: prodData['isFavorite'],
        ));
      });
      _items = loadedProducts;
      notifyListeners();
    } on DioError catch (error) {
      print('디오 에러 $error');
    } catch (e) {
      print('기타 에러 $e');
    }
  }

  Future<void> addProduct(Product product) async {
    // https://images.mypetlife.co.kr/content/uploads/2021/10/19151330/corgi-g1a1774f95_1280-1024x682.jpg

    try {
      final response = await dio.post(url, queryParameters: {
        'auth': authToken,
      }, data: {
        'title': product.title,
        'description': product.description,
        'imageUrl': product.imageUrl,
        'price': product.price,
        'isFavorite': product.isFavorite,
        'creatorId': userId,
      });

      final newProduct = Product(
        id: product.id,
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
      );

      _items.add(newProduct);
      // _items.insert(0, newProduct); 맨위로 아이템 추가
      notifyListeners();
    } on DioError catch (e) {
      print('에러 확인 ${e.response?.data}');
    }
  }

  void updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      try {
        final newUrl =
            'https://flutter-demo-shop-app-e041e-default-rtdb.firebaseio.com/products/$id.json';
        await dio.patch(newUrl, queryParameters: {
          'auth': authToken,
        }, data: {
          'title': newProduct.title,
          'description': newProduct.description,
          'imageUrl': newProduct.imageUrl,
          'price': newProduct.price,
        });
        _items[prodIndex] = newProduct;
        notifyListeners();
      } catch (error) {}
    } else {
      print('...');
    }
  }

  Future<void> deleteProduct(String id) async {
    final newUrl =
        'https://flutter-demo-shop-app-e041e-default-rtdb.firebaseio.com/products/$id.json';
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    Product? existingProduct = _items[existingProductIndex];

    try {
      _items.removeAt(existingProductIndex);
      await dio.delete(newUrl, queryParameters: {
        'auth': authToken,
      }).then((response) {
        if (response.statusCode! >= 400) {
          throw HttpException('Could not delete product.');
        }
      });
      existingProduct = null;
    } catch (_) {
      if (existingProduct != null) {
        _items.insert(existingProductIndex, existingProduct);
      }
    }
    notifyListeners();
  }
}
