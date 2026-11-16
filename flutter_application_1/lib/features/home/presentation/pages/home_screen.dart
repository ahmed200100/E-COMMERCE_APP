import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/di/injection.dart';
import '../../../commerce/presentation/bloc/commerce_bloc.dart';
import '../../../commerce/presentation/pages/commerce_pages.dart';
import '../../../experiences/presentation/pages/store_experiences.dart';
import '../../domain/entities/home_entities.dart';
import '../bloc/home_bloc.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<HomeBloc>()..add(const HomeStarted()),
    child: const _HomeView(),
  );
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  int _tab = 0;
  bool _dailySpinChecked = false;

  Future<void> _checkDailySpin() async {
    final box = await Hive.openBox('nova_engagement');
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    if (box.get('lastLuckySpinPrompt') == today || !mounted) return;
    await box.put('lastLuckySpinPrompt', today);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.casino_outlined),
        title: const Text('Your daily lucky spin is here'),
        content: const Text('Spin once today for a chance to win a discount or loyalty points.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Maybe later')),
          FilledButton(onPressed: () {
            Navigator.pop(dialogContext);
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LuckySpinPage()));
          }, child: const Text('Spin now')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NOVA Store',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => StoreSearchPage(products: context.read<HomeBloc>().state.content?.featuredProducts ?? const []))),
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const GiftModePage())),
            icon: const Icon(Icons.card_giftcard_outlined),
            tooltip: 'Gift mode',
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LuckySpinPage())),
            icon: const Icon(Icons.casino_outlined),
            tooltip: 'Daily reward',
          ),
          BlocBuilder<CommerceBloc, CommerceState>(builder: (context, state) => IconButton(
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            icon: Badge(isLabelVisible: state.itemCount > 0, label: Text('${state.itemCount}'), child: const Icon(Icons.shopping_bag_outlined)),
            tooltip: 'Cart',
          )),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'Categories'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Wishlist'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ShoppingAssistantPage(products: context.read<HomeBloc>().state.content?.featuredProducts ?? const []))),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Ask NOVA'),
            )
          : null,
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state.content != null && !_dailySpinChecked) {
            _dailySpinChecked = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _checkDailySpin());
          }
          if (state.errorMessage != null && state.content != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          if (_tab == 0 && state.status == HomeStatus.loading && state.content == null) {
            return const _HomeShimmer();
          }
          if (_tab == 0 && state.status == HomeStatus.failure && state.content == null) {
            return _ErrorView(
              message: state.errorMessage ?? 'Unable to load the store.',
            );
          }
          final content = state.content;
          if (_tab == 2) return const WishlistPage();
          if (_tab == 3) return const ProfilePage();
          if (_tab == 1) return CategoriesPage(categories: content?.categories ?? const [], products: content?.featuredProducts ?? const []);
          if (content == null) return const SizedBox.shrink();
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<HomeBloc>().add(const HomeRefreshed()),
            child: _HomeContent(
              content: content,
              isLoadingMore: state.isLoadingMore,
            ),
          );
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.content, required this.isLoadingMore});

  final HomeContent content;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification &&
              notification.metrics.extentAfter < 300) {
            context.read<HomeBloc>().add(const HomeNextPageRequested());
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _PromoCarousel(banners: content.banners)),
            SliverToBoxAdapter(child: _SectionTitle(title: 'Shop by category')),
            SliverToBoxAdapter(
              child: _CategoryStrip(categories: content.categories),
            ),
            SliverToBoxAdapter(
              child: _SectionTitle(title: 'Featured products'),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 16,
                  childAspectRatio: .64,
                ),
                itemCount: content.featuredProducts.length,
                itemBuilder: (context, index) {
                  final product = content.featuredProducts[index];
              return ProductCard(
                    product: product,
                onTap: () => Navigator.pushNamed(context, '/products/details', arguments: product),
                onWishlistTap: () {
                  context.read<HomeBloc>().add(HomeWishlistToggled(product.id));
                  context.read<CommerceBloc>().add(WishlistProductToggled(product));
                },
                onAddToCart: () {
                  context.read<CommerceBloc>().add(CartProductAdded(product));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                },
                  );
                },
              ),
            ),
            if (isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      );
}

class _BannerStrip extends StatelessWidget {
  const _BannerStrip({required this.banners});

  final List<HomeBanner> banners;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 180,
    child: PageView.builder(
      padEnds: false,
      controller: PageController(viewportFraction: .88),
      itemCount: banners.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                banners[index].imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: Color(0xFF0D1B2A)),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    banners[index].title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel({required this.banners});

  final List<HomeBanner> banners;

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  static const _promos = [
    ('A little glow goes a long way', 'UP TO 30% OFF  ·  SKINCARE', Color(0xFF344B40), Color(0xFF788A70)),
    ('Your season, your signature', 'DISCOVER THE NEW COLLECTION', Color(0xFF75594D), Color(0xFFB99170)),
    ('The perfect gift is waiting', 'COMPLIMENTARY DELIVERY', Color(0xFF353C59), Color(0xFF777C9B)),
  ];

  late final PageController _controller;
  Timer? _timer;
  int _page = 0;

  int get _count => widget.banners.isEmpty ? _promos.length : widget.banners.length;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: .92);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients || _count < 2) return;
      final next = (_page + 1) % _count;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 174,
        child: PageView.builder(
          controller: _controller,
          itemCount: _count,
          onPageChanged: (index) => setState(() => _page = index),
          itemBuilder: (context, index) {
            final hasRemoteBanners = widget.banners.isNotEmpty;
            final promo = _promos[index % _promos.length];
            final title = hasRemoteBanners ? widget.banners[index].title : promo.$1;
            final eyebrow = hasRemoteBanners ? 'JUST FOR YOU' : promo.$2;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasRemoteBanners && widget.banners[index].imageUrl.isNotEmpty)
                      Image.network(
                        widget.banners[index].imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _promoGradient(promo),
                      )
                    else
                      _promoGradient(promo),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withValues(alpha: .62), Colors.transparent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(eyebrow, style: const TextStyle(color: Color(0xFFF3DDAE), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.3)),
                          const SizedBox(height: 9),
                          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 22, height: 1.12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 11),
                          const Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('SHOP NOW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                            SizedBox(width: 7), Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 2),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_count, (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: index == _page ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: index == _page ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(8),
          ),
        )),
      ),
    ],
  );

  Widget _promoGradient((String, String, Color, Color) promo) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [promo.$3, promo.$4],
        begin: Alignment.centerLeft,
        end: Alignment.bottomRight,
      ),
    ),
  );
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.categories});

  final List<HomeCategory> categories;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 112,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(width: 14),
      itemBuilder: (context, index) => SizedBox(
        width: 72,
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(categories[index].imageUrl),
              onBackgroundImageError: (_, _) {},
            ),
            const SizedBox(height: 8),
            Text(
              categories[index].name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -.3),
    ),
  );
}

class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    highlightColor: Theme.of(context).colorScheme.surface,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 170,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 24),
        Container(height: 20, width: 160, color: Colors.white),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(height: 12, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: .66,
          children: List.generate(4, (index) => Container(color: Colors.white)),
        ),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.read<HomeBloc>().add(const HomeStarted()),
            child: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
