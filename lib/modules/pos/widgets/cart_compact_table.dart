import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/responsive/cart_compact_columns.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_density_sizes.dart';
import '../../../core/theme/tokens/app_motion.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../controllers/cart_controller.dart';
import '../controllers/cart_selection_controller.dart';
import '../controllers/pos_work_view_controller.dart';
import 'cart_compact_gift_row.dart';
import 'cart_compact_head.dart';
import 'cart_compact_row.dart';

/// Desktop cart table: the head and the scrolling list of 48 px rows. Rows
/// are laid out with a fixed item extent, listen to their own line only, and
/// adding a line scrolls to the end (as the prototype does).
class CartCompactTable extends StatefulWidget {
  const CartCompactTable({super.key});

  @override
  State<CartCompactTable> createState() => _CartCompactTableState();
}

class _CartCompactTableState extends State<CartCompactTable> {
  final ScrollController _scroll = ScrollController();
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    _worker = ever<int>(
      Get.find<CartSelectionController>().scrollRequest,
      (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: AppMotion.slideInMs),
          curve: Curves.easeOut,
        );
      }),
    );
  }

  @override
  void dispose() {
    _worker?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cart = Get.find<CartController>();
    final windowHeight = MediaQuery.sizeOf(context).height;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = CartCompactColumns.forSize(
          cartWidth: constraints.maxWidth,
          windowHeight: windowHeight,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CartCompactHead(columns: columns),
            Expanded(
              child: RawScrollbar(
                controller: _scroll,
                thumbColor: c.scrollThumbCart,
                thickness: AppSizes.scrollbarThickness,
                radius: const Radius.circular(AppRadii.full),
                child: Focus(
                  focusNode: Get.find<PosWorkViewController>().cartFocus,
                  child: Obx(() {
                    final ids = cart.lineIds.toList();
                    final gifts = cart.gifts.toList();
                    return ListView.builder(
                      controller: _scroll,
                      itemExtent: AppDensitySizes.cartRowHeight,
                      itemCount: ids.length + gifts.length,
                      itemBuilder: (context, index) => index < ids.length
                          ? CartCompactRow(
                              key: ValueKey<int>(ids[index]),
                              productId: ids[index],
                              index: index,
                              columns: columns,
                            )
                          : CartCompactGiftRow(
                              key: ValueKey<String>(
                                'gift-${gifts[index - ids.length].offer.id}',
                              ),
                              gift: gifts[index - ids.length],
                              columns: columns,
                            ),
                      findChildIndexCallback: (key) {
                        if (key is! ValueKey<int>) return null;
                        final i = ids.indexOf(key.value);
                        return i < 0 ? null : i;
                      },
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
