import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../commerce/presentation/bloc/commerce_bloc.dart';
import '../../../home/domain/entities/home_entities.dart';

class ShoppingAssistantPage extends StatefulWidget {
  const ShoppingAssistantPage({required this.products, super.key});
  final List<Product> products;

  @override
  State<ShoppingAssistantPage> createState() => _ShoppingAssistantPageState();
}

class _ShoppingAssistantPageState extends State<ShoppingAssistantPage> {
  final _input = TextEditingController();
  final List<_ChatEntry> _messages = [
    const _ChatEntry('Hi! Tell me who you are shopping for, the occasion, or your budget and I’ll find a match from our store.', false),
  ];

  @override
  void dispose() { _input.dispose(); super.dispose(); }

  void _ask() {
    final query = _input.text.trim();
    if (query.isEmpty) return;
    _input.clear();
    final q = query.toLowerCase();
    final budgetMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(q);
    final budget = budgetMatch == null ? null : double.tryParse(budgetMatch.group(1)!);
    final words = q.split(RegExp(r'[\s,،.!؟?]+')).where((w) => w.length > 2).toSet();
    if (q.contains('عطر') || q.contains('perfume') || q.contains('fragrance')) {
      words.addAll({'perfume', 'fragrance', 'scent', 'عطر', 'عطور'});
    }
    if (q.contains('skincare') || q.contains('بشرة') || q.contains('العناية')) {
      words.addAll({'skincare', 'skin', 'beauty', 'بشرة', 'العناية'});
    }
    final ranked = widget.products.map((product) {
      final haystack = '${product.title} ${product.category} ${product.description}'.toLowerCase();
      var score = words.where(haystack.contains).length.toDouble();
      if (q.contains('gift') || q.contains('هدية') || q.contains('هديه')) score += 1;
      if (budget != null) score += product.price <= budget ? 2 : -2;
      return (product, score);
    }).toList()..sort((a, b) => b.$2.compareTo(a.$2));
    final suggestions = ranked.where((entry) => entry.$2 > 0).take(3).map((entry) => entry.$1).toList();
    setState(() {
      _messages.add(_ChatEntry(query, true));
      _messages.add(_ChatEntry(
        suggestions.isEmpty
            ? (q.contains(RegExp(r'[\u0600-\u06FF]'))
                ? 'لم أجد منتجات مناسبة ضمن المنتجات المحمّلة حالياً. جرّب البحث عن عطر أو عناية بالبشرة أو اذكر ميزانيتك.'
                : 'I couldn’t find a close match in the products loaded right now. Try a category like skincare, fragrance, or a price range.')
            : (q.contains(RegExp(r'[\u0600-\u06FF]'))
                ? 'دي اختيارات من المتجر ممكن تناسب طلبك:'
                : 'Here are a few store picks that fit what you described:'),
        false,
        products: suggestions,
      ));
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('NOVA shopping assistant')),
    body: Column(children: [
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final entry = _messages[index];
          return Align(
            alignment: entry.fromUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: entry.fromUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.text, style: TextStyle(color: entry.fromUser ? Theme.of(context).colorScheme.onPrimary : null)),
                ...entry.products.map((product) => _ProductSuggestion(product: product)),
              ]),
            ),
          );
        },
      )),
      SafeArea(top: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(children: [
          Expanded(child: TextField(controller: _input, textInputAction: TextInputAction.send, onSubmitted: (_) => _ask(), decoration: const InputDecoration(hintText: 'Ask for a gift, scent, or routine…', border: OutlineInputBorder(), isDense: true))),
          const SizedBox(width: 8), IconButton.filled(onPressed: _ask, icon: const Icon(Icons.arrow_upward_rounded)),
        ]),
      )),
    ]),
  );
}

class _ChatEntry {
  const _ChatEntry(this.text, this.fromUser, {this.products = const []});
  final String text;
  final bool fromUser;
  final List<Product> products;
}

class _ProductSuggestion extends StatelessWidget {
  const _ProductSuggestion({required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      leading: SizedBox(width: 44, child: CachedNetworkImage(imageUrl: product.imageUrl, fit: BoxFit.cover, errorWidget: (_, _, _) => const Icon(Icons.shopping_bag_outlined))),
      title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
      trailing: IconButton(tooltip: 'Add to cart', onPressed: () => context.read<CommerceBloc>().add(CartProductAdded(product)), icon: const Icon(Icons.add_shopping_cart_outlined)),
      onTap: () => Navigator.pushNamed(context, '/products/details', arguments: product),
    ),
  );
}

class StoreSearchPage extends StatefulWidget {
  const StoreSearchPage({required this.products, super.key});
  final List<Product> products;
  @override
  State<StoreSearchPage> createState() => _StoreSearchPageState();
}

class _StoreSearchPageState extends State<StoreSearchPage> {
  final _input = TextEditingController();
  String _localeId = 'en_US';
  bool _listening = false;
  bool _available = true;

  @override
  void dispose() { _input.dispose(); super.dispose(); }

  Future<void> _listen() async {
    if (_listening) return;
    setState(() { _listening = true; _available = true; });
    try {
      final words = await const MethodChannel('nova_store/voice_search')
          .invokeMethod<String>('listen', {'locale': _localeId.replaceAll('_', '-')});
      if (mounted && words != null && words.isNotEmpty) {
        setState(() { _input.text = words; _input.selection = TextSelection.collapsed(offset: words.length); });
      }
    } on PlatformException {
      if (mounted) setState(() => _available = false);
    } on MissingPluginException {
      if (mounted) setState(() => _available = false);
    } finally {
      if (mounted) setState(() => _listening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _input.text.trim().toLowerCase();
    final results = q.isEmpty ? <Product>[] : widget.products.where((product) => '${product.title} ${product.category} ${product.description}'.toLowerCase().contains(q)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Search NOVA')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: TextField(
          controller: _input,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search products',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(onPressed: _listen, tooltip: 'Search by voice', icon: Icon(_listening ? Icons.mic : Icons.mic_none, color: _listening ? Theme.of(context).colorScheme.primary : null)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        )),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          const Text('Voice language'), const SizedBox(width: 12),
          SegmentedButton<String>(segments: const [ButtonSegment(value: 'en_US', label: Text('English')), ButtonSegment(value: 'ar_EG', label: Text('العربية'))], selected: {_localeId}, onSelectionChanged: (value) => setState(() => _localeId = value.first)),
        ])),
        if (!_available) const Padding(padding: EdgeInsets.all(12), child: Text('Voice search is unavailable. Check microphone permission and speech services.')),
        Expanded(child: results.isEmpty
          ? Center(child: Text(q.isEmpty ? 'Search by typing or tapping the microphone.' : 'No matching products found.'))
          : ListView.builder(itemCount: results.length, itemBuilder: (context, index) {
              final product = results[index];
              return ListTile(leading: SizedBox(width: 52, child: CachedNetworkImage(imageUrl: product.imageUrl, fit: BoxFit.cover, errorWidget: (_, _, _) => const Icon(Icons.image))), title: Text(product.title), subtitle: Text('\$${product.price.toStringAsFixed(2)}'), onTap: () => Navigator.pushNamed(context, '/products/details', arguments: product));
            })),
      ]),
    );
  }
}

class GiftModePage extends StatefulWidget {
  const GiftModePage({super.key});
  @override
  State<GiftModePage> createState() => _GiftModePageState();
}

class _GiftModePageState extends State<GiftModePage> {
  final _form = GlobalKey<FormState>();
  final _recipient = TextEditingController();
  final _message = TextEditingController();
  String _contactType = 'Email';
  String? _tracking;

  @override
  void dispose() { _recipient.dispose(); _message.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Gift mode')),
    body: _tracking == null ? Form(key: _form, child: ListView(padding: const EdgeInsets.all(20), children: [
      const Icon(Icons.card_giftcard_rounded, size: 54),
      const SizedBox(height: 12),
      Text('Send a little surprise', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Add a recipient and a personal note. We’ll prepare a gift tracking preview for you.', textAlign: TextAlign.center),
      const SizedBox(height: 24),
      SegmentedButton<String>(segments: const [ButtonSegment(value: 'Email', label: Text('Email'), icon: Icon(Icons.email_outlined)), ButtonSegment(value: 'Phone', label: Text('Phone'), icon: Icon(Icons.sms_outlined))], selected: {_contactType}, onSelectionChanged: (v) => setState(() => _contactType = v.first)),
      const SizedBox(height: 16),
      TextFormField(
        controller: _recipient,
        keyboardType: _contactType == 'Email' ? TextInputType.emailAddress : TextInputType.phone,
        validator: (value) {
          final input = value?.trim() ?? '';
          if (input.isEmpty) return 'Enter a recipient ${_contactType.toLowerCase()} or number';
          if (_contactType == 'Email' && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(input)) return 'Enter a valid email address';
          if (_contactType == 'Phone' && input.replaceAll(RegExp(r'\D'), '').length < 7) return 'Enter a valid phone number';
          return null;
        },
        decoration: InputDecoration(labelText: 'Recipient $_contactType', border: const OutlineInputBorder()),
      ),
      const SizedBox(height: 14),
      TextFormField(controller: _message, maxLines: 4, maxLength: 180, decoration: const InputDecoration(labelText: 'Gift card message', hintText: 'Write a personal note…', border: OutlineInputBorder())),
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: () { if (_form.currentState!.validate()) setState(() => _tracking = 'NOVA-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'); }, icon: const Icon(Icons.redeem), label: const Text('Prepare gift')),
    ])) : Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.mark_email_read_outlined, size: 58),
      const SizedBox(height: 12),
      Text('Gift preview is ready', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text('Tracking code: $_tracking', textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text('To: ${_recipient.text}'),
      if (_message.text.isNotEmpty) Padding(padding: const EdgeInsets.all(16), child: Text('“${_message.text}”', textAlign: TextAlign.center)),
      const Text('Connect a checkout and messaging service to send the gift and tracking link.'),
      const SizedBox(height: 18),
      OutlinedButton(onPressed: () => setState(() => _tracking = null), child: const Text('Create another gift')),
    ]))),
  );
}

class ArProductPreviewPage extends StatefulWidget {
  const ArProductPreviewPage({required this.product, super.key});
  final Product product;
  @override
  State<ArProductPreviewPage> createState() => _ArProductPreviewPageState();
}

class _ArProductPreviewPageState extends State<ArProductPreviewPage> {
  double _scale = 1;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Preview in your space')),
    body: Column(children: [
      Expanded(child: Stack(fit: StackFit.expand, children: [
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE8E2D8), Color(0xFFCFC6B8), Color(0xFF988D7E)]))),
        Align(alignment: const Alignment(0, .62), child: Container(height: 2, color: Colors.white.withValues(alpha: .75))),
    Center(child: GestureDetector(onScaleUpdate: (details) => setState(() => _scale = (_scale * details.scale).clamp(.6, 2.2).toDouble()), child: Transform.scale(scale: _scale, child: CachedNetworkImage(imageUrl: widget.product.imageUrl, width: 220, height: 240, fit: BoxFit.contain, errorWidget: (_, _, _) => const Icon(Icons.shopping_bag_outlined, size: 100))))),
        Positioned(left: 18, right: 18, bottom: 18, child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Text('Pinch to resize the product preview. A product 3D model and AR camera integration are required for true room placement.', textAlign: TextAlign.center)))),
      ])),
      Padding(padding: const EdgeInsets.all(18), child: Row(children: [Expanded(child: Text(widget.product.title, maxLines: 1, overflow: TextOverflow.ellipsis)), Text('\$${widget.product.price.toStringAsFixed(2)}')]))
    ]),
  );
}

class LuckySpinPage extends StatefulWidget {
  const LuckySpinPage({super.key});
  @override
  State<LuckySpinPage> createState() => _LuckySpinPageState();
}

class _LuckySpinPageState extends State<LuckySpinPage> with SingleTickerProviderStateMixin {
  static const _prizes = ['10% OFF', '50 points', 'Free shipping', 'Try again'];
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  int? _prize;
  bool _spinning = false;
  bool _alreadySpun = false;

  @override
  void initState() {
    super.initState();
    _restoreDailySpin();
  }

  Future<void> _restoreDailySpin() async {
    final box = await Hive.openBox('nova_engagement');
    final today = _today;
    final savedPrize = box.get('luckySpinPrize') as int?;
    if (mounted && box.get('luckySpinDate') == today && savedPrize != null) {
      setState(() { _alreadySpun = true; _prize = savedPrize; });
    }
  }

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  @override
  void dispose() { _spin.dispose(); super.dispose(); }

  Future<void> _spinNow() async {
    if (_spinning || _alreadySpun) return;
    setState(() { _spinning = true; _prize = null; });
    await _spin.forward(from: 0);
    final prize = Random().nextInt(_prizes.length);
    final box = await Hive.openBox('nova_engagement');
    await box.put('luckySpinDate', _today);
    await box.put('luckySpinPrize', prize);
    if (mounted) setState(() { _prize = prize; _spinning = false; _alreadySpun = true; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your daily lucky spin')),
    body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('One spin. A little NOVA surprise.', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 28),
      AnimatedBuilder(animation: _spin, builder: (context, _) => Transform.rotate(angle: _spin.value * pi * 8, child: Container(width: 230, height: 230, decoration: BoxDecoration(shape: BoxShape.circle, gradient: SweepGradient(colors: [Theme.of(context).colorScheme.primary, const Color(0xFFD6B776), const Color(0xFF8B9A83), const Color(0xFFC07C68), Theme.of(context).colorScheme.primary]), border: Border.all(color: Colors.white, width: 7)), child: const Center(child: Icon(Icons.auto_awesome, size: 64, color: Colors.white))))),
      const SizedBox(height: 24),
      if (_prize != null) Text('Demo result: ${_prizes[_prize!]}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const Padding(padding: EdgeInsets.only(top: 8), child: Text('Reward previews are not redeemable until a loyalty service is connected.', textAlign: TextAlign.center)),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: _spinning || _alreadySpun ? null : _spinNow, icon: const Icon(Icons.casino_outlined), label: Text(_alreadySpun ? 'Today’s spin is complete' : 'Spin now')),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continue shopping')),
    ]))),
  );
}
