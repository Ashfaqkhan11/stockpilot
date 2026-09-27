class Product {
  String? id;
  String name;
  String sku;
  int quantity;
  double price;
  String? imageUrl;
  String? supplierId;
  Product({this.id, required this.name,
    required this.sku,
    required this.quantity,
    required this.price,
    this.imageUrl, this.supplierId});

  factory Product.fromJson(Map<String,dynamic> json) => Product(
      id: json['id'], name: json['name'], sku: json['sku'],
      quantity: json['quantity'], price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'], supplierId: json['supplier_id']
  );
  Map<String,dynamic> toJson() => {'name': name,
    'sku': sku,
    'quantity': quantity,
    'price': price,
    'image_url': imageUrl,
    'supplier_id': supplierId,
    };
}