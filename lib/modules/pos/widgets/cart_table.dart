import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_motion.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../controllers/cart_controller.dart';
import '../controllers/cart_selection_controller.dart';
import 'cart_line_row.dart';

/// Table head plus the scrolling list of lines. The list listens to the line
/// ids only; every row listens to its own line. Adding a line scrolls to the
/// end (prototype `scrollTo(scrollHeight)`).
class CartTable extends StatefulWidget {
  const CartTable({super.key});

  @override
  State<CartTable> createState() => _CartTableState();
}

class _CartTableState extends State<CartTable> {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _TableHead(),
        const SizedBox(height: AppSpacing.s6),
        Expanded(
          child: RawScrollbar(
            controller: _scroll,
            thumbColor: c.scrollThumbCart,
            thickness: AppSizes.scrollbarThickness,
            radius: const Radius.circular(AppRadii.full),
            child: Obx(() {
              final ids = cart.lineIds.toList();
              return ListView.builder(
                controller: _scroll,
                itemCount: ids.length,
                itemBuilder: (context, index) => CartLineRow(
                  key: ValueKey<int>(ids[index]),
                  productId: ids[index],
                  index: index,
                ),
                findChildIndexCallback: (key) {
                  final i = ids.indexOf((key as ValueKey<int>).value);
                  return i < 0 ? null : i;
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _TableHead extends StatelessWidget {
  const _TableHead();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final style = context.text
        .of(
          AppFontSize.s12,
          weight: AppFontWeight.semiBold,
          height: AppLineHeight.base,
        )
        .copyWith(color: c.text);
    Widget cell(String label, {TextAlign align = TextAlign.center}) =>
        Text(label, textAlign: align, maxLines: 1, style: style);
    const gap = SizedBox(width: AppSizes.cartLineGap);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.circular(AppRadii.r7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.cartHeadPadY,
          horizontal: AppSizes.cartPad,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: AppSizes.cartLineCheckbox,
              child: cell(s.cartTableNumber(), align: TextAlign.start),
            ),
            gap,
            Expanded(
              flex: CartColumns.itemFlex,
              child: cell(s.cartTableItem(), align: TextAlign.start),
            ),
            gap,
            SizedBox(
              width: AppSizes.qtyControlWidth,
              child: cell(s.cartTableQty()),
            ),
            gap,
            SizedBox(
              width: AppSizes.lineEditWidth,
              child: cell(s.cartTablePrice()),
            ),
            gap,
            SizedBox(
              width: AppSizes.lineEditWidth,
              child: cell(s.cartTableDiscount()),
            ),
            gap,
            Expanded(
              flex: CartColumns.totalFlex,
              child: cell(s.cartTableTotal()),
            ),
            gap,
            const SizedBox(width: AppSizes.trashSize),
          ],
        ),
      ),
    );
  }
}
