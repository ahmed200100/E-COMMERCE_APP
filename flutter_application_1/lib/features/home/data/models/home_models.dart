import '../../domain/entities/home_entities.dart';

class HomeResponseModel {
  const HomeResponseModel({
    required this.banners,
    required this.categories,
    required this.products,
    required this.page,
    required this.hasNextPage,
  });

  factory HomeResponseModel.fromJson(
    Map<String, dynamic> json,
  ) => HomeResponseModel(
    banners: (json['banners'] as List<dynamic>? ?? [])
        .map((item) => HomeBannerModel.fromJson(item as Map<String, dynamic>))
        .toList(),
    categories: (json['categories'] as List<dynamic>? ?? [])
        .map((item) => HomeCategoryModel.fromJson(item as Map<String, dynamic>))
        .toList(),
    products:
        (json['featuredProducts'] as List<dynamic>? ??
                json['products'] as List<dynamic>? ??
                [])
            .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
            .toList(),
    page: (json['page'] as num?)?.toInt() ?? 1,
    hasNextPage: json['hasNextPage'] as bool? ?? false,
  );

  final List<HomeBannerModel> banners;
  final List<HomeCategoryModel> categories;
  final List<ProductModel> products;
  final int page;
  final bool hasNextPage;

  HomeContent toEntity() => HomeContent(
    banners: banners.map((item) => item.toEntity()).toList(growable: false),
    categories: categories.isNotEmpty
        ? categories.map((item) => item.toEntity()).toList(growable: false)
        : products
              .where((item) => item.category.isNotEmpty)
              .map((item) => item.category)
              .toSet()
              .map((name) => HomeCategory(
                    id: name,
                    name: name,
                    imageUrl: products
                        .firstWhere((item) => item.category == name)
                        .imageUrl,
                  ))
              .toList(growable: false),
    featuredProducts: products
        .map((item) => item.toEntity())
        .toList(growable: false),
    page: page,
    hasNextPage: hasNextPage,
  );
}

class HomeBannerModel {
  const HomeBannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
  });

  factory HomeBannerModel.fromJson(Map<String, dynamic> json) =>
      HomeBannerModel(
        id: '${json['id'] ?? ''}',
        imageUrl: '${json['imageUrl'] ?? json['image_url'] ?? ''}',
        title: '${json['title'] ?? ''}',
      );

  final String id;
  final String imageUrl;
  final String title;

  HomeBanner toEntity() => HomeBanner(id: id, imageUrl: imageUrl, title: title);
}

class HomeCategoryModel {
  const HomeCategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory HomeCategoryModel.fromJson(Map<String, dynamic> json) =>
      HomeCategoryModel(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        imageUrl: '${json['imageUrl'] ?? json['image_url'] ?? ''}',
      );

  final String id;
  final String name;
  final String imageUrl;

  HomeCategory toEntity() =>
      HomeCategory(id: id, name: name, imageUrl: imageUrl);
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    this.images = const [],
    this.description = '',
    this.ingredients = '',
    this.variants = const [],
    this.category = '',
    this.compareAtPrice,
    required this.rating,
    required this.isWishlisted,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: '${json['id'] ?? ''}',
    title: '${json['title'] ?? json['name'] ?? ''}',
    imageUrl: _imageUrlFrom(json),
    images: _imagesFrom(json),
    description: '${json['description'] ?? ''}',
    ingredients: '${json['ingredients'] ?? ''}',
    variants: (json['variants'] as List<dynamic>? ?? [])
        .map((value) => '$value')
        .toList(growable: false),
    category: '${json['category'] ?? ''}',
    price: (json['price'] as num?)?.toDouble() ?? 0,
    compareAtPrice: (json['compareAtPrice'] as num?)?.toDouble(),
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    isWishlisted: json['isWishlisted'] as bool? ?? false,
  );

  final String id;
  final String title;
  final String imageUrl;
  final List<String> images;
  final String description;
  final String ingredients;
  final List<String> variants;
  final String category;
  final double price;
  final double? compareAtPrice;
  final double rating;
  final bool isWishlisted;

  Product toEntity() => Product(
    id: id,
    title: title,
    imageUrl: imageUrl,
    images: images,
    description: description,
    ingredients: ingredients,
    variants: variants,
    category: category,
    price: price,
    compareAtPrice: compareAtPrice,
    rating: rating,
    isWishlisted: isWishlisted,
  );
}

String _imageUrlFrom(Map<String, dynamic> json) {
  final directUrl = json['imageUrl'] ?? json['image_url'] ?? json['thumbnail'];
  if (directUrl is String && directUrl.trim().isNotEmpty) return directUrl;

  final images = json['images'];
  if (images is List && images.isNotEmpty && images.first is String) {
    return images.first as String;
  }
  return '';
}

List<String> _imagesFrom(Map<String, dynamic> json) {
  final images = json['images'];
  if (images is List) {
    return images.whereType<String>().where((value) => value.isNotEmpty).toList();
  }
  final url = _imageUrlFrom(json);
  return url.isEmpty ? const [] : [url];
}
