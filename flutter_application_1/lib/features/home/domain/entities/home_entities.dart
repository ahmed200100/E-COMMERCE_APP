class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.imageUrl,
    required this.title,
  });

  final String id;
  final String imageUrl;
  final String title;
}

class HomeCategory {
  const HomeCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String imageUrl;
}

class Product {
  const Product({
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
    this.rating = 0,
    this.isWishlisted = false,
  });

  final String id;
  final String title;
  final String imageUrl;
  final double price;
  final List<String> images;
  final String description;
  final String ingredients;
  final List<String> variants;
  final String category;
  final double? compareAtPrice;
  final double rating;
  final bool isWishlisted;

  Product copyWith({bool? isWishlisted}) => Product(
    id: id,
    title: title,
    imageUrl: imageUrl,
    price: price,
    images: images,
    description: description,
    ingredients: ingredients,
    variants: variants,
    category: category,
    compareAtPrice: compareAtPrice,
    rating: rating,
    isWishlisted: isWishlisted ?? this.isWishlisted,
  );
}

class HomeContent {
  const HomeContent({
    required this.banners,
    required this.categories,
    required this.featuredProducts,
    required this.page,
    required this.hasNextPage,
  });

  final List<HomeBanner> banners;
  final List<HomeCategory> categories;
  final List<Product> featuredProducts;
  final int page;
  final bool hasNextPage;

  HomeContent copyWith({
    List<Product>? featuredProducts,
    int? page,
    bool? hasNextPage,
  }) => HomeContent(
    banners: banners,
    categories: categories,
    featuredProducts: featuredProducts ?? this.featuredProducts,
    page: page ?? this.page,
    hasNextPage: hasNextPage ?? this.hasNextPage,
  );
}
