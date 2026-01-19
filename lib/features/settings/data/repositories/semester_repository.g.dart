// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$semesterRepositoryHash() =>
    r'497f545936aafca1e364395d5885f3f69722e679';

/// See also [semesterRepository].
@ProviderFor(semesterRepository)
final semesterRepositoryProvider =
    AutoDisposeProvider<SemesterRepository>.internal(
  semesterRepository,
  name: r'semesterRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$semesterRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SemesterRepositoryRef = AutoDisposeProviderRef<SemesterRepository>;
String _$watchSemestersHash() => r'603fdf07852de3606139369b791cfa9a2f234e05';

/// See also [watchSemesters].
@ProviderFor(watchSemesters)
final watchSemestersProvider =
    AutoDisposeStreamProvider<List<Semester>>.internal(
  watchSemesters,
  name: r'watchSemestersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$watchSemestersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WatchSemestersRef = AutoDisposeStreamProviderRef<List<Semester>>;
String _$activeSemesterHash() => r'5583e2774e200dd501ac972abac994c9ef23b948';

/// See also [activeSemester].
@ProviderFor(activeSemester)
final activeSemesterProvider = AutoDisposeStreamProvider<Semester?>.internal(
  activeSemester,
  name: r'activeSemesterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeSemesterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ActiveSemesterRef = AutoDisposeStreamProviderRef<Semester?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
