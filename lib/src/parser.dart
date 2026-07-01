import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;

/// Resolves a single file path into its [LibraryElement] using the analyzer API.
/// This is used primarily in CLI scenarios.
Future<LibraryElement> resolveFile(String filePath) async {
  final absolutePath = p.absolute(filePath);
  final collection = AnalysisContextCollection(includedPaths: [absolutePath]);
  final context = collection.contextFor(absolutePath);
  final session = context.currentSession;

  final resolvedLibrary = await session.getResolvedLibrary(absolutePath);
  if (resolvedLibrary is ResolvedLibraryResult) {
    return resolvedLibrary.element;
  }
  throw StateError('Failed to resolve library for file: $filePath');
}

/// Crawls a [LibraryElement] and all of its non-SDK imports,
/// returning the resolved [CompilationUnit]s.
Future<List<CompilationUnit>> crawlLibraryAsts(
  LibraryElement rootLibrary,
) async {
  final List<CompilationUnit> units = [];
  final Set<String> visited = {};

  Future<void> visit(LibraryElement lib) async {
    final path = lib.firstFragment.source.fullName;
    if (visited.contains(path)) return;
    visited.add(path);

    // Skip SDK libraries like dart:core or dart:math
    if (lib.isInSdk) return;

    // Skip external packages
    final rootUri = rootLibrary.firstFragment.source.uri;
    final libUri = lib.firstFragment.source.uri;
    if (libUri.scheme == 'package') {
      final pkgName = libUri.pathSegments.first;
      if (rootUri.scheme == 'package') {
        if (pkgName != rootUri.pathSegments.first) return;
      } else {
        return;
      }
    }

    // Skip dart2wgsl library itself to avoid transpiling annotations/stdlib
    if (lib.name == 'dart2wgsl' ||
        (lib.name != null && lib.name!.startsWith('dart2wgsl.'))) {
      return;
    }
    if (lib.firstFragment.source.uri.scheme == 'package' &&
        lib.firstFragment.source.uri.pathSegments.first == 'dart2wgsl') {
      return;
    }

    final resolvedUnit = await lib.session.getResolvedUnit(path);
    if (resolvedUnit is ResolvedUnitResult) {
      units.add(resolvedUnit.unit);
    }

    // Crawl library parts
    for (final part in lib.fragments.skip(1)) {
      final partPath = part.source.fullName;
      final partResolved = await lib.session.getResolvedUnit(partPath);
      if (partResolved is ResolvedUnitResult) {
        units.add(partResolved.unit);
      }
    }

    // Crawl library imports
    for (final imp in lib.firstFragment.libraryImports) {
      final importedLib = imp.importedLibrary;
      if (importedLib != null) {
        await visit(importedLib);
      }
    }
  }

  await visit(rootLibrary);
  return units;
}
