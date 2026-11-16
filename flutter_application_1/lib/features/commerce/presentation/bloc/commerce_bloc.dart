import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../home/domain/entities/home_entities.dart';

sealed class CommerceEvent {
  const CommerceEvent();
}

final class CartProductAdded extends CommerceEvent {
  const CartProductAdded(this.product, {this.quantity = 1});
  final Product product;
  final int quantity;
}

final class CartQuantityChanged extends CommerceEvent {
  const CartQuantityChanged(this.productId, this.quantity);
  final String productId;
  final int quantity;
}

final class CartProductRemoved extends CommerceEvent {
  const CartProductRemoved(this.productId);
  final String productId;
}

final class WishlistProductToggled extends CommerceEvent {
  const WishlistProductToggled(this.product);
  final Product product;
}

final class CommerceState {
  const CommerceState({this.cart = const {}, this.wishlist = const {}});
  final Map<String, CartLine> cart;
  final Map<String, Product> wishlist;
  int get itemCount => cart.values.fold(0, (sum, line) => sum + line.quantity);
  double get subtotal => cart.values.fold(
    0,
    (sum, line) => sum + line.product.price * line.quantity,
  );
}

class CartLine {
  const CartLine(this.product, this.quantity);
  final Product product;
  final int quantity;
}

final class CommerceBloc extends Bloc<CommerceEvent, CommerceState> {
  CommerceBloc() : super(const CommerceState()) {
    on<CartProductAdded>((event, emit) {
      final cart = Map<String, CartLine>.of(state.cart);
      final current = cart[event.product.id];
      cart[event.product.id] = CartLine(
        event.product,
        (current?.quantity ?? 0) + event.quantity,
      );
      emit(CommerceState(cart: cart, wishlist: state.wishlist));
    });
    on<CartQuantityChanged>((event, emit) {
      final cart = Map<String, CartLine>.of(state.cart);
      if (event.quantity <= 0) {
        cart.remove(event.productId);
      } else if (cart.containsKey(event.productId)) {
        cart[event.productId] = CartLine(
          cart[event.productId]!.product,
          event.quantity,
        );
      }
      emit(CommerceState(cart: cart, wishlist: state.wishlist));
    });
    on<CartProductRemoved>((event, emit) {
      final cart = Map<String, CartLine>.of(state.cart)..remove(event.productId);
      emit(CommerceState(cart: cart, wishlist: state.wishlist));
    });
    on<WishlistProductToggled>((event, emit) {
      final wishlist = Map<String, Product>.of(state.wishlist);
      wishlist.containsKey(event.product.id)
          ? wishlist.remove(event.product.id)
          : wishlist[event.product.id] = event.product;
      emit(CommerceState(cart: state.cart, wishlist: wishlist));
    });
  }
}
