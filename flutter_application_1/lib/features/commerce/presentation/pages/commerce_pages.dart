import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../home/domain/entities/home_entities.dart';
import '../bloc/commerce_bloc.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({required this.product, super.key});
  final Product product;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1;
  int imageIndex = 0;
  String? variant;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.images.isEmpty ? [product.imageUrl] : product.images;
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SizedBox(
            height: 340,
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (index) => setState(() => imageIndex = index),
              itemBuilder: (_, index) => CachedNetworkImage(
                imageUrl: images[index], fit: BoxFit.cover,
                errorWidget: (_, _, _) => const Icon(Icons.image_not_supported_outlined, size: 48),
              ),
            ),
          ),
          if (images.length > 1)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(images.length, (i) => Padding(
              padding: const EdgeInsets.all(3), child: Icon(Icons.circle, size: 8, color: i == imageIndex ? Theme.of(context).colorScheme.primary : Colors.black26),
            ))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('\$${product.price.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/products/ar-preview', arguments: product),
                icon: const Icon(Icons.view_in_ar_outlined),
                label: const Text('Preview in your space'),
              ),
              const SizedBox(height: 20),
              Text(product.description.isEmpty ? 'Discover the details of ${product.title}.' : product.description),
              if (product.ingredients.isNotEmpty) ...[
                const SizedBox(height: 20), const Text('Ingredients', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6), Text(product.ingredients),
              ],
              if (product.variants.isNotEmpty) ...[
                const SizedBox(height: 20), const Text('Size / Color', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(spacing: 8, children: product.variants.map((value) => ChoiceChip(label: Text(value), selected: variant == value, onSelected: (_) => setState(() => variant = value))).toList()),
              ],
              const SizedBox(height: 24),
              Row(children: [
                IconButton(onPressed: quantity > 1 ? () => setState(() => quantity--) : null, icon: const Icon(Icons.remove_circle_outline)),
                Text('$quantity', style: Theme.of(context).textTheme.titleMedium),
                IconButton(onPressed: () => setState(() => quantity++), icon: const Icon(Icons.add_circle_outline)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () {
                    context.read<CommerceBloc>().add(CartProductAdded(product, quantity: quantity));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                  },
                  icon: const Icon(Icons.shopping_bag_outlined), label: const Text('Add to Cart'),
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your cart')),
    body: BlocBuilder<CommerceBloc, CommerceState>(builder: (context, state) {
      if (state.cart.isEmpty) return const Center(child: Text('Your cart is empty'));
      final shipping = state.subtotal == 0 ? 0.0 : 4.99;
      return Column(children: [
        Expanded(child: ListView(children: state.cart.values.map((line) => ListTile(
          leading: SizedBox(width: 56, child: CachedNetworkImage(imageUrl: line.product.imageUrl, fit: BoxFit.cover, errorWidget: (_, _, _) => const Icon(Icons.image))),
          title: Text(line.product.title), subtitle: Text('\$${line.product.price.toStringAsFixed(2)}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(onPressed: () => context.read<CommerceBloc>().add(CartQuantityChanged(line.product.id, line.quantity - 1)), icon: const Icon(Icons.remove)),
            Text('${line.quantity}'),
            IconButton(onPressed: () => context.read<CommerceBloc>().add(CartQuantityChanged(line.product.id, line.quantity + 1)), icon: const Icon(Icons.add)),
            IconButton(onPressed: () => context.read<CommerceBloc>().add(CartProductRemoved(line.product.id)), icon: const Icon(Icons.delete_outline)),
          ]),
        )).toList())),
        Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          _PriceRow(label: 'Subtotal', value: state.subtotal),
          _PriceRow(label: 'Shipping', value: shipping),
          const Divider(), _PriceRow(label: 'Total', value: state.subtotal + shipping, bold: true),
          const SizedBox(height: 16), SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pushNamed(context, '/checkout'), child: const Text('Checkout'))),
        ])),
      ]);
    }),
  );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value, this.bold = false});
  final String label; final double value; final bool bold;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Text(label, style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null), const Spacer(), Text('\$${value.toStringAsFixed(2)}', style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null)]));
}

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<CommerceBloc, CommerceState>(builder: (context, state) => state.wishlist.isEmpty
    ? const Center(child: Text('Your wishlist is empty'))
    : GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .75), itemCount: state.wishlist.length, itemBuilder: (context, index) {
      final product = state.wishlist.values.elementAt(index);
      return InkWell(onTap: () => Navigator.pushNamed(context, '/products/details', arguments: product), child: Card(clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: CachedNetworkImage(imageUrl: product.imageUrl, width: double.infinity, fit: BoxFit.cover, errorWidget: (_, _, _) => const Icon(Icons.image))), Padding(padding: const EdgeInsets.all(10), child: Text(product.title, maxLines: 1)), Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 10), child: Text('\$${product.price.toStringAsFixed(2)}'))])));
    }));
}

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key, required this.categories, required this.products});
  final List<HomeCategory> categories; final List<Product> products;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    if (categories.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Categories will appear when store data is available.')),
    ...categories.map((category) {
      final matching = products.where((p) => p.category.toLowerCase() == category.name.toLowerCase()).toList();
      return ExpansionTile(title: Text(category.name), leading: CircleAvatar(backgroundImage: category.imageUrl.isEmpty ? null : NetworkImage(category.imageUrl), child: category.imageUrl.isEmpty ? const Icon(Icons.category_outlined) : null), children: [
        if (matching.isEmpty) const ListTile(title: Text('Browse products in this category')),
        ...matching.map((p) => ListTile(title: Text(p.title), subtitle: Text('\$${p.price.toStringAsFixed(2)}'), onTap: () => Navigator.pushNamed(context, '/products/details', arguments: p))),
      ]);
    }),
  ]);
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(children: const [
    SizedBox(height: 24), CircleAvatar(radius: 38, child: Icon(Icons.person_outline, size: 40)),
    ListTile(title: Text('Account'), leading: Icon(Icons.person_outline)),
    ListTile(title: Text('Addresses'), leading: Icon(Icons.location_on_outlined)),
    ListTile(title: Text('Order history'), leading: Icon(Icons.receipt_long_outlined)),
  ]);
}
