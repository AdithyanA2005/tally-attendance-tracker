import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/syncable_model.dart';

abstract class CacheRepository<T extends SyncableModel> {
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

  void initSync() {
    debugPrint('CacheRepository: Starting sync for $tableName');

    supabase
        .channel('public:$tableName')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: (payload) async {
            debugPrint('Realtime payload for $tableName: ${payload.eventType}');

            if (payload.eventType == PostgresChangeEvent.delete) {
              final id = payload.oldRecord[primaryKey];
              if (id != null) {
                final local = box.get(id);
                // Only delete if NO pending sync
                if (local == null || !local.hasPendingSync) {
                  await box.delete(id);
                }
              }
            } else {
              final json = payload.newRecord;
              final remote = fromJson(json);
              final local = box.get(remote.id);

              // RECONCILIATION LOGIC:
              // 1. If local has pending sync, NEVER overwrite it from the stream.
              // 2. If local doesn't exist or doesn't have pending sync,
              //    only update if remote is newer.
              if (local == null) {
                await box.put(remote.id, remote);
              } else if (!local.hasPendingSync) {
                if (remote.lastUpdated.isAfter(local.lastUpdated)) {
                  await box.put(remote.id, remote);
                }
              }
            }
          },
        )
        .subscribe();
  }

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

  Future<void> saveLocal(T item) async {
    await box.put(item.id, item);
  }

  Future<void> deleteLocal(String id) async {
    await box.delete(id);
  }
}
