import '../models/product.dart';

/// Datos mock de tienda.
/// Sustituye por tus datos reales cuando quieras.
class ShopData {
  static const List<String> categories = <String>[
    'Ropa',
    'Accesorios',
    'Consumibles',
  ];

  static const Map<String, List<Product>> productsByCategory = <String, List<Product>>{
    'Ropa': <Product>[
      Product(
        id: 'hoodie_01',
        name: 'Sudadera',
        description: 'Cómoda y calentita',
        price: 120,
        image: 'assets/shop/hoodie.png',
      ),
      Product(
        id: 'tshirt_01',
        name: 'Camiseta',
        description: 'Edición del festival',
        price: 60,
        image: 'assets/shop/tshirt.png',
      ),
    ],
    'Accesorios': <Product>[
      Product(
        id: 'cap_01',
        name: 'Gorra',
        description: 'Para días soleados',
        price: 45,
        image: 'assets/shop/cap.png',
      ),
      Product(
        id: 'bag_01',
        name: 'Mochila',
        description: 'Más espacio, menos lío',
        price: 90,
        image: 'assets/shop/bag.png',
      ),
    ],
    'Consumibles': <Product>[
      Product(
        id: 'potion_01',
        name: 'Poción',
        description: 'Recupera energía',
        price: 25,
        image: 'assets/shop/potion.png',
      ),
      Product(
        id: 'boost_01',
        name: 'Boost',
        description: 'Velocidad +10%',
        price: 40,
        image: 'assets/shop/boost.png',
      ),
    ],
  };
}
