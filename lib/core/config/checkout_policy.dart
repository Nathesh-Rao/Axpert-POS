/// When a checkout waits for storage (DEC-129).
///
/// `false` (default, option b2): the sale, stock, points, cart clear, receipt
/// and toast happen at once, exactly as before; the database commit then runs
/// in the background and a failure shows `toastSaveFailed`.
///
/// `true` (option b1): the receipt, the cart clear and the success toast wait
/// for the commit, so "receipt shown" implies "committed" (a fully failed
/// commit still shows the error toast and then completes the flow).
///
/// Set `--dart-define=CHECKOUT_COMMIT_BEFORE_RECEIPT=true` to switch; no code
/// change. MUST be `true` before real card payments go live (a charge must not
/// be confirmed to the cashier before the sale is stored); b1 also needs a
/// void/refund path for a charge whose sale could not be stored (KG-195).
abstract final class CheckoutPolicy {
  static const bool commitBeforeReceipt = bool.fromEnvironment(
    'CHECKOUT_COMMIT_BEFORE_RECEIPT',
  );
}
