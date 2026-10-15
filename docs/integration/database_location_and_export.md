# Where the database lives, and how to export and open it

Audited 2026-10-15 from code (`lib/core/database/`, `web/`). Only the web path was run in a browser; everything else is read from code or covered by VM tests.

## How the database is opened

| Platform | Connection | Location |
|---|---|---|
| Windows, macOS, Android, iOS | Drift `NativeDatabase.createInBackground(File)`: real SQLite in a background isolate | `getApplicationSupportDirectory()` + `axpert_pos.sqlite` |
| Web | Drift `WasmDatabase.open` (SQLite WASM in the Drift worker) | Browser storage under the database name `axpert_pos`: OPFS or IndexedDB, picked by Drift at runtime. Assets: `web/sqlite3.wasm`, `web/drift_worker.js` |

- Selection: conditional import in `database_provider_factory.dart` (`dart.library.io` native, `dart.library.js_interop` web). There is no silent fallback to LocalStore, memory or mock; the `*_BACKEND=localStore` defines are explicit rollbacks, off by default.
- WAL is NOT enabled (no `journal_mode` pragma; only `PRAGMA foreign_keys = ON`). Schema version 10.
- Folders (path_provider): macOS `~/Library/Application Support/<bundle id>/` (inside `~/Library/Containers/<bundle id>/Data/...` because the app is sandboxed); Windows `%APPDATA%\<company>\<product>\`; Android/iOS app-private. Windows paths are unverified (cannot build here).

## Export (Settings, "Export database", admin only)

1. Settings > Export database > confirm (the file holds users, password hashes and customer data).
2. File name `pos_<store>_<yyyyMMdd_HHmm>.db`; `<store>` is the store name reduced to `A-Za-z0-9_-` (fallback: first 8 characters of the store id).
3. Snapshot (`DatabaseExportService`):
   - native: `VACUUM INTO` a new temp file, read it, delete it (never copies the live file);
   - web: the page copies schema and rows into an in-memory SQLite WASM file (foreign keys off, rowids, BLOB and NULL kept, indexes and `user_version` kept), one source transaction.
4. Delivery (`DatabaseExportSaver`): web = browser download; elsewhere Downloads, else Documents, never overwriting (`_2`, `_3`). The toast shows the full path with a Copy action.

## Opening the file

- DB Browser for SQLite: File > Open Database, pick the `.db`.
- CLI: `sqlite3 pos_..._.db ".tables"` and `PRAGMA user_version;` (10).
- The live database can be opened the same way on native (`axpert_pos.sqlite`) with the app closed; on web it cannot be reached outside the browser, use the export.

## Unverified

Windows, macOS, Android and iOS export were not run. Web was run in headless Chrome (debug build, `DEMO_SEED=true`, admin `Demo#Admin1`): `tool/web_check/export_check.mjs`.
