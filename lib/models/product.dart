class Product {
  final String id;
  final String name;
  final String description;

  /// Precio en monedas del juego.
  final int price;

  /// Ruta local (assets) o URL remota. Si es null, se muestra un placeholder.
  final String? image;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
  });
}
