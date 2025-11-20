import 'dart:convert';

/// 文创产品模型
class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final String type;
  final String category;
  final String heritage;
  final String designer;
  final String story;
  final List<String> images;
  final String materials;
  final String size;
  final int stock;
  final int sales;
  final double rating;
  final String aiDesignProcess;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.type,
    required this.category,
    required this.heritage,
    required this.designer,
    required this.story,
    required this.images,
    required this.materials,
    required this.size,
    required this.stock,
    required this.sales,
    required this.rating,
    required this.aiDesignProcess,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      type: json['type'] as String,
      category: json['category'] as String,
      heritage: json['heritage'] as String,
      designer: json['designer'] as String,
      story: json['story'] as String,
      images: (json['images'] as List<dynamic>).map((e) => e.toString()).toList(),
      materials: json['materials'] as String,
      size: json['size'] as String,
      stock: json['stock'] as int,
      sales: json['sales'] as int,
      rating: (json['rating'] as num).toDouble(),
      aiDesignProcess: json['aiDesignProcess'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'type': type,
      'category': category,
      'heritage': heritage,
      'designer': designer,
      'story': story,
      'images': images,
      'materials': materials,
      'size': size,
      'stock': stock,
      'sales': sales,
      'rating': rating,
      'aiDesignProcess': aiDesignProcess,
    };
  }
}

/// 产品数据集合
class ProductCatalog {
  final List<Product> products;

  ProductCatalog({required this.products});

  factory ProductCatalog.fromJson(Map<String, dynamic> json) {
    return ProductCatalog(
      products: (json['products'] as List<dynamic>)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  factory ProductCatalog.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return ProductCatalog.fromJson(json);
  }

  /// 按类型筛选
  List<Product> getByType(String type) {
    return products.where((p) => p.type == type).toList();
  }

  /// 按非遗类型筛选
  List<Product> getByHeritage(String heritage) {
    return products.where((p) => p.heritage == heritage).toList();
  }

  /// 获取热销产品
  List<Product> getHotProducts({int limit = 10}) {
    final sorted = List<Product>.from(products);
    sorted.sort((a, b) => b.sales.compareTo(a.sales));
    return sorted.take(limit).toList();
  }

  /// 获取高评分产品
  List<Product> getTopRatedProducts({int limit = 10}) {
    final sorted = List<Product>.from(products);
    sorted.sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(limit).toList();
  }

  /// 搜索产品
  List<Product> search(String query) {
    final queryLower = query.toLowerCase();
    return products.where((p) {
      return p.title.toLowerCase().contains(queryLower) ||
          p.description.toLowerCase().contains(queryLower) ||
          p.heritage.toLowerCase().contains(queryLower) ||
          p.type.toLowerCase().contains(queryLower);
    }).toList();
  }
}
