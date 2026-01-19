// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$syncServiceHash() => r'609d0536c29b6e456e669a59934fa4659ae9765c';

/// See also [syncService].
@ProviderFor(syncService)
final syncServiceProvider = AutoDisposeProvider<SyncService>.internal(
  syncService,
  name: r'syncServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$syncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SyncServiceRef = AutoDisposeProviderRef<SyncService>;
String _$lastSyncTimeHash() => r'a1152bcdacc6b32dac5a7bc27c70a3e1dbea940f';

/// See also [lastSyncTime].
@ProviderFor(lastSyncTime)
final lastSyncTimeProvider = AutoDisposeFutureProvider<DateTime?>.internal(
  lastSyncTime,
  name: r'lastSyncTimeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$lastSyncTimeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LastSyncTimeRef = AutoDisposeFutureProviderRef<DateTime?>;
String _$syncControllerHash() => r'0b13f8123c0326db037d30b517358d731b8d7517';

/// See also [SyncController].
@ProviderFor(SyncController)
final syncControllerProvider =
    AutoDisposeNotifierProvider<SyncController, AsyncValue<void>>.internal(
  SyncController.new,
  name: r'syncControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syncControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SyncController = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
