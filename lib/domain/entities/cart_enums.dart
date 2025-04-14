/// Represents the current synchronization status of the cart
enum CartSyncStatus {
  /// The cart is fully synchronized with the server
  synced,
  
  /// The cart is currently synchronizing with the server
  syncing,
  
  /// The cart is waiting to be synchronized (pending changes)
  pending,
  
  /// There was an error during synchronization
  error,
  
  /// The cart is offline and cannot sync with the server
  offline,
}
