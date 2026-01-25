// lib/search_rs.dart
// Dart FFI bindings for the search-rs Rust library

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// ============================================================================
// Native Types
// ============================================================================

/// Opaque pointer to SearchEngine
class CSearchEngine extends Opaque {}

/// Opaque pointer to QueryResult
class CQueryResult extends Opaque {}

/// C Document structure
class CDocument extends Struct {
  external Pointer<Utf8> path;
  
  @Double()
  external double score;
  
  @Uint32()
  external int docId;
}

/// C Search Results structure
class CSearchResults extends Struct {
  external Pointer<CDocument> documents;
  
  @IntPtr()
  external int count;
}

/// Error codes
abstract class ErrorCode {
  static const int success = 0;
  static const int nullPointer = 1;
  static const int invalidUtf8 = 2;
  static const int indexNotFound = 3;
  static const int buildFailed = 4;
  static const int searchFailed = 5;
  static const int unknownError = 99;
}

// ============================================================================
// Native Function Signatures
// ============================================================================

/// Build index
typedef search_build_index_native = Int32 Function(
  Pointer<Utf8> folderPath,
  Uint32 minFrequency,
  Double maxPercentage,
);
typedef SearchBuildIndex = int Function(
  Pointer<Utf8> folderPath,
  int minFrequency,
  double maxPercentage,
);

/// Load search engine
typedef search_engine_load_native = Pointer<CSearchEngine> Function(
  Pointer<Utf8> indexPath,
);
typedef SearchEngineLoad = Pointer<CSearchEngine> Function(
  Pointer<Utf8> indexPath,
);

/// Free search engine
typedef search_engine_free_native = Void Function(
  Pointer<CSearchEngine> engine,
);
typedef SearchEngineFree = void Function(
  Pointer<CSearchEngine> engine,
);

/// Free-text query
typedef search_query_freetext_native = Pointer<CSearchResults> Function(
  Pointer<CSearchEngine> engine,
  Pointer<Utf8> query,
  IntPtr limit,
);
typedef SearchQueryFreetext = Pointer<CSearchResults> Function(
  Pointer<CSearchEngine> engine,
  Pointer<Utf8> query,
  int limit,
);

/// Boolean query
typedef search_query_boolean_native = Pointer<CSearchResults> Function(
  Pointer<CSearchEngine> engine,
  Pointer<Utf8> query,
  IntPtr limit,
);
typedef SearchQueryBoolean = Pointer<CSearchResults> Function(
  Pointer<CSearchEngine> engine,
  Pointer<Utf8> query,
  int limit,
);

/// Get results count
typedef search_results_count_native = IntPtr Function(
  Pointer<CSearchResults> results,
);
typedef SearchResultsCount = int Function(
  Pointer<CSearchResults> results,
);

/// Get document from results
typedef search_results_get_document_native = Pointer<CDocument> Function(
  Pointer<CSearchResults> results,
  IntPtr index,
);
typedef SearchResultsGetDocument = Pointer<CDocument> Function(
  Pointer<CSearchResults> results,
  int index,
);

/// Free results
typedef search_results_free_native = Void Function(
  Pointer<CSearchResults> results,
);
typedef SearchResultsFree = void Function(
  Pointer<CSearchResults> results,
);

/// Free string
typedef search_string_free_native = Void Function(
  Pointer<Utf8> s,
);
typedef SearchStringFree = void Function(
  Pointer<Utf8> s,
);

// ============================================================================
// Dart Models
// ============================================================================

/// Search result document
class SearchDocument {
  final String path;
  final double score;
  final int docId;

  SearchDocument({
    required this.path,
    required this.score,
    required this.docId,
  });

  @override
  String toString() => 'SearchDocument(path: $path, score: $score, id: $docId)';
}

/// Search results collection
class SearchResults {
  final List<SearchDocument> documents;

  SearchResults(this.documents);

  int get length => documents.length;
  bool get isEmpty => documents.isEmpty;
  bool get isNotEmpty => documents.isNotEmpty;

  @override
  String toString() => 'SearchResults(${documents.length} documents)';
}

// ============================================================================
// Main API Class
// ============================================================================

class SearchEngine {
  late final DynamicLibrary _lib;
  late final SearchBuildIndex _buildIndex;
  late final SearchEngineLoad _loadEngine;
  late final SearchEngineFree _freeEngine;
  late final SearchQueryFreetext _queryFreetext;
  late final SearchQueryBoolean _queryBoolean;
  late final SearchResultsCount _resultsCount;
  late final SearchResultsGetDocument _getDocument;
  late final SearchResultsFree _freeResults;
  late final SearchStringFree _freeString;

  Pointer<CSearchEngine>? _enginePtr;

  SearchEngine(String libraryPath) {
    _lib = DynamicLibrary.open(libraryPath);
    _loadFunctions();
  }

  /// Load functions from the dynamic library
  void _loadFunctions() {
    _buildIndex = _lib
        .lookup<NativeFunction<search_build_index_native>>('search_build_index')
        .asFunction();

    _loadEngine = _lib
        .lookup<NativeFunction<search_engine_load_native>>('search_engine_load')
        .asFunction();

    _freeEngine = _lib
        .lookup<NativeFunction<search_engine_free_native>>('search_engine_free')
        .asFunction();

    _queryFreetext = _lib
        .lookup<NativeFunction<search_query_freetext_native>>(
            'search_query_freetext')
        .asFunction();

    _queryBoolean = _lib
        .lookup<NativeFunction<search_query_boolean_native>>(
            'search_query_boolean')
        .asFunction();

    _resultsCount = _lib
        .lookup<NativeFunction<search_results_count_native>>(
            'search_results_count')
        .asFunction();

    _getDocument = _lib
        .lookup<NativeFunction<search_results_get_document_native>>(
            'search_results_get_document')
        .asFunction();

    _freeResults = _lib
        .lookup<NativeFunction<search_results_free_native>>(
            'search_results_free')
        .asFunction();

    _freeString = _lib
        .lookup<NativeFunction<search_string_free_native>>('search_string_free')
        .asFunction();
  }

  // ==========================================================================
  // High-level API
  // ==========================================================================

  /// Build a new search index from a folder
  static void buildIndex(
    String libraryPath,
    String folderPath, {
    int minFrequency = 1,
    double maxPercentage = 0.99,
  }) {
    final engine = SearchEngine(libraryPath);
    final pathPtr = folderPath.toNativeUtf8();

    try {
      final result = engine._buildIndex(pathPtr, minFrequency, maxPercentage);
      
      if (result != ErrorCode.success) {
        throw SearchException(
          'Failed to build index: error code $result',
          result,
        );
      }
    } finally {
      malloc.free(pathPtr);
    }
  }

  /// Load an existing search index
  void load(String indexPath) {
    if (_enginePtr != null) {
      throw StateError('Search engine already loaded');
    }

    final pathPtr = indexPath.toNativeUtf8();

    try {
      _enginePtr = _loadEngine(pathPtr);

      if (_enginePtr == null || _enginePtr!.address == 0) {
        throw SearchException(
          'Failed to load search engine from $indexPath',
          ErrorCode.indexNotFound,
        );
      }
    } finally {
      malloc.free(pathPtr);
    }
  }

  /// Perform a free-text search query
  SearchResults searchFreetext(String query, {int limit = 10}) {
    _ensureLoaded();

    final queryPtr = query.toNativeUtf8();
    Pointer<CSearchResults>? resultsPtr;

    try {
      resultsPtr = _queryFreetext(_enginePtr!, queryPtr, limit);

      if (resultsPtr == null || resultsPtr.address == 0) {
        throw SearchException(
          'Search query failed',
          ErrorCode.searchFailed,
        );
      }

      return _convertResults(resultsPtr);
    } finally {
      malloc.free(queryPtr);
      if (resultsPtr != null && resultsPtr.address != 0) {
        _freeResults(resultsPtr);
      }
    }
  }

  /// Perform a boolean search query
  /// Example: "hello AND there OR NOT man"
  SearchResults searchBoolean(String query, {int limit = 10}) {
    _ensureLoaded();

    final queryPtr = query.toNativeUtf8();
    Pointer<CSearchResults>? resultsPtr;

    try {
      resultsPtr = _queryBoolean(_enginePtr!, queryPtr, limit);

      if (resultsPtr == null || resultsPtr.address == 0) {
        throw SearchException(
          'Boolean query failed',
          ErrorCode.searchFailed,
        );
      }

      return _convertResults(resultsPtr);
    } finally {
      malloc.free(queryPtr);
      if (resultsPtr != null && resultsPtr.address != 0) {
        _freeResults(resultsPtr);
      }
    }
  }

  // ==========================================================================
  // Helper Methods
  // ==========================================================================

  void _ensureLoaded() {
    if (_enginePtr == null) {
      throw StateError('Search engine not loaded. Call load() first.');
    }
  }

  SearchResults _convertResults(Pointer<CSearchResults> resultsPtr) {
    final count = _resultsCount(resultsPtr);
    final documents = <SearchDocument>[];

    for (var i = 0; i < count; i++) {
      final docPtr = _getDocument(resultsPtr, i);

      if (docPtr != null && docPtr.address != 0) {
        final doc = docPtr.ref;
        final path = doc.path.toDartString();

        documents.add(SearchDocument(
          path: path,
          score: doc.score,
          docId: doc.docId,
        ));
      }
    }

    return SearchResults(documents);
  }

  /// Free resources
  void dispose() {
    if (_enginePtr != null) {
      _freeEngine(_enginePtr!);
      _enginePtr = null;
    }
  }
}

// ============================================================================
// Exceptions
// ============================================================================

class SearchException implements Exception {
  final String message;
  final int errorCode;

  SearchException(this.message, this.errorCode);

  @override
  String toString() => 'SearchException($errorCode): $message';
}

// ============================================================================
// Usage Example
// ============================================================================

void main() async {
  // Platform-specific library path
  String getLibraryPath() {
    if (Platform.isLinux) {
      return 'target/release/libsearch_ffi.so';
    } else if (Platform.isMacOS) {
      return 'target/release/libsearch_ffi.dylib';
    } else if (Platform.isWindows) {
      return 'target/release/search_ffi.dll';
    }
    throw UnsupportedError('Unsupported platform');
  }

  final libPath = getLibraryPath();

  // Build index (one-time setup)
  try {
    print('Building search index...');
    SearchEngine.buildIndex(
      libPath,
      'path/to/documents',
      minFrequency: 1,
      maxPercentage: 0.99,
    );
    print('Index built successfully!');
  } catch (e) {
    print('Error building index: $e');
  }

  // Load and search
  final engine = SearchEngine(libPath);

  try {
    print('\nLoading search engine...');
    engine.load('path/to/documents/.index');
    print('Engine loaded!');

    // Free-text search
    print('\n--- Free-text Search ---');
    final results1 = engine.searchFreetext('hello world', limit: 5);
    print('Found ${results1.length} documents:');
    for (final doc in results1.documents) {
      print('  ${doc.path} (score: ${doc.score.toStringAsFixed(3)})');
    }

    // Boolean search
    print('\n--- Boolean Search ---');
    final results2 = engine.searchBoolean('hello AND world', limit: 5);
    print('Found ${results2.length} documents:');
    for (final doc in results2.documents) {
      print('  ${doc.path} (score: ${doc.score.toStringAsFixed(3)})');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    engine.dispose();
    print('\nEngine disposed.');
  }
}