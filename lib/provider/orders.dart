import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import './cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    required this.id,
    required this.amount,
    required this.products,
    required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  static const url =
      'https://flutter-demo-shop-app-e041e-default-rtdb.firebaseio.com/orders.json';
  final dio = Dio();
  final String? authToken;
  late List<OrderItem> _orders;

  Orders(this.authToken, this._orders);

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> fetchAndSetOrders() async {
    final response = await dio.get(url, queryParameters: {
      'auth': authToken,
    });
    final List<OrderItem> loadedOrders = [];
    final extractedData = response.data;

    if (extractedData == null) {
      return;
    }

    extractedData.forEach((orderId, orderData) {
      loadedOrders.add(OrderItem(
        id: orderId,
        amount: orderData['amount'],
        dateTime: DateTime.parse(orderData['dateTime']),
        products: (orderData['products'] as List<dynamic>)
            .map((item) => CartItem(
                  id: item['id'],
                  title: item['title'],
                  quantity: item['quantity'],
                  price: item['price'],
                ))
            .toList(),
      ));
    });

    _orders = loadedOrders.reversed.toList();
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final timeStamp = DateTime.now();

    final response = await dio.post(url, queryParameters: {
      'auth': authToken,
    }, data: {
      'amount': total,
      'dateTime': timeStamp.toIso8601String(),
      'products': cartProducts
          .map((element) => {
                'id': element.id,
                'title': element.title,
                'quantity': element.quantity,
                'price': element.price,
              })
          .toList(),
    });

    _orders.insert(
        0,
        OrderItem(
          id: response.data['name'],
          amount: total,
          products: cartProducts,
          dateTime: timeStamp,
        ));

    notifyListeners();
  }
}
