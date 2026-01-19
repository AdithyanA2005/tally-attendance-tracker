import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A base repository that implements a Read-Through Caching strategy.
///
/// - **Reads**: Always come from the local [Hive] box.
/// - **Background Sync**: Listens to Supabase [stream] and updates [Hive].
/// - **Writes**: Should be implemented by subclasses to update [Hive] immediately (optimistic) and then push to Supabase.
abstract class CacheRepository<T extends HiveObject> {
  final Box<T> box;
  final SupabaseClient supabase;
  final String tableName;
  final T Function(Map<String, dynamic>) fromJson;
  final String primaryKey;

  CacheRepository({
    required this.box,
    required this.supabase,
    required this.tableName,
    required this.fromJson,
    this.primaryKey = 'id',
  });

  /// Starts the background sync process.
  /// Call this in the constructor or lazily when data is first accessed.
  @protected
  void initSync({String? userId}) {
    // If userId is provided, ensure we only sync data for that user if RLS doesn't handle it implicitly.
    // However, RLS usually handles it. Supabase stream() respects RLS.

    debugPrint('CacheRepository: Starting sync for $tableName');

    try {
      supabase
          .from(tableName)
          .stream(primaryKey: [primaryKey])
          .listen(
            (List<Map<String, dynamic>> data) async {
              debugPrint(
                'CacheRepository: Received ${data.length} items for $tableName',
              );

              // 1. Convert to Model Objects
              final remoteItems = data.map((json) => fromJson(json)).toList();

              // 2. Identify IDs present in remote
              // We assume T has an 'id' or we use the primaryKey if we can access it dynamically.
              // Since T is generic, we can't easily access 'id' unless we enforce an interface.
              // But HiveObject doesn't guarantee 'id' field.
              // For now, we'll assume we simply clear and putAll, OR we try to be smarter.
              // Clear and PutAll is safest for "Mirroring" the remote state exactly.

              final remoteMap = {
                for (var item in remoteItems) getId(item): item,
              };

              // 3. Update Hive
              // We can't easily detect deletions unless we know which IDs *should* be there.
              // Since stream() returns the FULL set, any ID in Box that is NOT in remoteMap means it was deleted remotely.

              final localKeys = box.keys
                  .cast<String>()
                  .toSet(); // Assuming String IDs
              final remoteKeys = remoteMap.keys.toSet();

              // Delete missing keys
              final keysToDelete = localKeys.difference(remoteKeys);
              if (keysToDelete.isNotEmpty) {
                debugPrint(
                  'CacheRepository: Deleting ${keysToDelete.length} stale items from $tableName',
                );
                await box.deleteAll(keysToDelete);
              }

              // Put/Update all remote items
              // Hive's putAll works with Map<key, value>.
              await box.putAll(remoteMap);
            },
            onError: (error) {
              debugPrint('CacheRepository Error ($tableName): $error');
            },
          );
    } catch (e) {
      debugPrint('CacheRepository Fatal Error ($tableName): $e');
    }
  }

  /// Helper to get ID from the generic object.
  /// Required override by subclasses.
  String getId(T item);

  /// Exposes the local data as a Stream.
  /// This is what the UI should consume.
  Stream<Box<T>> get stream {
    return Stream.multi((controller) {
      // Emit initial value
      controller.add(box);

      void listener() {
        controller.add(box);
      }

      final listenable = box.listenable();
      listenable.addListener(listener);

      controller.onCancel = () {
        listenable.removeListener(listener);
      };
    });
  }

  /// Helper for Optimistic Updates.
  /// Updates local cache immediately.
  Future<void> saveLocal(T item) async {
    await box.put(getId(item), item);
  }

  Future<void> deleteLocal(String id) async {
    await box.delete(id);
  }
}
