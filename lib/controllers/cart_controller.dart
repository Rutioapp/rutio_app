import 'package:flutter/foundation.dart';

import '../models/product.dart';

/// Controlador de carrito simple (ChangeNotifier) para la tienda.
/// Mantiene un `Map<Product, int>` con cantidades.
class CartController extends ChangeNotifier {
  final Map<Product, int> _items = <Product, int>{};

  Map<Product, int> get items => _items;

  int get totalItems => _items.values.fold<int>(0, (sum, v) => sum + v);

  void add(Product product, {int quantity = 1}) {
    if (quantity <= 0) return;
    _items.update(product, (q) => q + quantity, ifAbsent: () => quantity);
    notifyListeners();
  }

  void increment(Product product) => add(product, quantity: 1);

  void decrement(Product product) {
    final current = _items[product];
    if (current == null) return;
    if (current <= 1) {
      _items.remove(product);
    } else {
      _items[product] = current - 1;
    }
    notifyListeners();
  }

  void remove(Product product) {
    if (_items.remove(product) != null) {
      notifyListeners();
    }
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
