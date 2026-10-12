// Demo entry flow (splash, login) helpers for the browser checks.
//
// The app starts on the splash and then the login unless it was built or run
// with `--dart-define=SKIP_ENTRY=true`, which starts on the POS page. Every
// check that loads the page and expects the POS screen needs that define:
//   flutter build web --dart-define=SKIP_ENTRY=true            (release)
//   flutter run -d web-server ... --dart-define=SKIP_ENTRY=true (debug)
// A check that drives the real flow instead passes `--entry` (debug_check.mjs)
// and builds WITHOUT the define.
export const SKIP_ENTRY_DEFINE = '--dart-define=SKIP_ENTRY=true';

/**
 * Walks the real flow: waits for the splash to end by itself (about 2 s plus
 * the hop), types a demo username and password (autofocus is on the username)
 * and presses Enter. `step(name, fn)` records a screenshot and the console of
 * each stage. Nothing here stores or logs the demo password beyond typing it.
 */
export async function signInThroughEntry({ step, insert, key, click, sleep, width, height }) {
  await step('entry: splash (real, not skipped)', async () => { await sleep(1000); });
  await step("entry: login", async () => { await sleep(3200); });
  await step('entry: empty submit shows errors', async () => { await key('Enter', 13); await sleep(400); });
  await step('entry: sign in (database users, then fade to POS)', async () => {
    // cashier1 has one store and one counter: the picker is skipped. The demo
    // password is listed in assets/seed/users.json (DEMO_SEED build only).
    await sleep(1200); // the debug build needs a moment before the field takes text
    await insert(process.env.ENTRY_USER ?? 'cashier1');
    await key('Tab', 9);
    await insert(process.env.ENTRY_PASS ?? 'Demo#Cashier1');
    await key('Enter', 13);
    await sleep(2200);
  });
}
