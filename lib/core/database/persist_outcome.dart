/// How a checkout or refund reached storage (DEC-129).
enum PersistOutcome {
  /// Written as intended (Drift transaction, or the independent writes).
  saved,

  /// The Drift transaction failed and rolled back; the lists were written to
  /// LocalStore instead and Drift is marked stale (re-copied at next start).
  savedViaFallback,

  /// Neither Drift nor the LocalStore fallback took the data: it exists only
  /// in this session. The user is told (`toastSaveFailed`).
  failed,
}
