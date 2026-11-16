import 'package:flutter/material.dart';

import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/commerce/presentation/pages/commerce_pages.dart';
import '../../features/home/domain/entities/home_entities.dart';
import '../../features/experiences/presentation/pages/store_experiences.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const productDetails = '/products/details';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orders = '/orders';
  static const profile = '/profile';
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (settings.name == AppRoutes.productDetails && settings.arguments is Product) {
      return MaterialPageRoute<void>(builder: (_) => ProductDetailsPage(product: settings.arguments! as Product), settings: settings);
    }
    if (settings.name == AppRoutes.cart) {
      return MaterialPageRoute<void>(builder: (_) => const CartPage(), settings: settings);
    }
    if (settings.name == '/products/ar-preview' && settings.arguments is Product) {
      return MaterialPageRoute<void>(builder: (_) => ArProductPreviewPage(product: settings.arguments! as Product), settings: settings);
    }
    if (settings.name == AppRoutes.home) {
      return MaterialPageRoute<void>(
        builder: (_) => const HomeScreen(),
        settings: settings,
      );
    }
    final title = switch (settings.name) {
      AppRoutes.home => 'Home',
      AppRoutes.login => 'Login',
      AppRoutes.register => 'Register',
      AppRoutes.productDetails => 'Product details',
      AppRoutes.cart => 'Cart',
      AppRoutes.checkout => 'Checkout',
      AppRoutes.orders => 'Orders',
      AppRoutes.profile => 'Profile',
      _ => 'Page not found',
    };
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text('$title feature coming soon')),
      ),
    );
  }
}
