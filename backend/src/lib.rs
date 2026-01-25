// search-ffi/src/lib.rs
// C FFI bindings for search-rs to use with Dart
use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;
use std::panic;
use std::slice;

// Assuming these are available from the search crate
// You'll need to adjust based on the actual API
// use search::{IndexBuilder, SearchEngine, QueryResult};

/// Opaque pointer type for SearchEngine
pub struct CSearchEngine {
    _private: [u8; 0],
}

/// Opaque pointer type for QueryResult
pub struct CQueryResult {
    _private: [u8; 0],
}

/// Result document structure
#[repr(C)]
pub struct CDocument {
    pub path: *mut c_char,
    pub score: f64,
    pub doc_id: u32,
}

/// Search results structure  
#[repr(C)]
pub struct CSearchResults {
    pub documents: *mut CDocument,
    pub count: usize,
}

/// Error codes
#[repr(C)]
pub enum CErrorCode {
    Success = 0,
    NullPointer = 1,
    InvalidUtf8 = 2,
    IndexNotFound = 3,
    BuildFailed = 4,
    SearchFailed = 5,
    UnknownError = 99,
}

// ============================================================================
// Index Building Functions
// ============================================================================

/// Build a new search index from a folder of documents
/// 
/// # Parameters
/// - `folder_path`: Path to folder containing documents
/// - `min_frequency`: Minimum term frequency threshold
/// - `max_percentage`: Maximum document percentage threshold (0.0 to 1.0)
/// 
/// # Returns
/// - 0 on success
/// - Error code on failure
#[no_mangle]
pub extern "C" fn search_build_index(
    folder_path: *const c_char,
    min_frequency: u32,
    max_percentage: f64,
) -> CErrorCode {
    if folder_path.is_null() {
        return CErrorCode::NullPointer;
    }

    let result = panic::catch_unwind(|| {
        let path_str = unsafe {
            match CStr::from_ptr(folder_path).to_str() {
                Ok(s) => s,
                Err(_) => return CErrorCode::InvalidUtf8,
            }
        };

        // TODO: Implement actual index building
        // Example:
        // let builder = IndexBuilder::new(path_str);
        // builder.min_frequency(min_frequency)
        //        .max_percentage(max_percentage)
        //        .build()?;
        
        println!("Building index at: {}", path_str);
        println!("Min frequency: {}, Max %: {}", min_frequency, max_percentage);
        
        CErrorCode::Success
    });

    match result {
        Ok(code) => code,
        Err(_) => CErrorCode::UnknownError,
    }
}

// ============================================================================
// SearchEngine Functions
// ============================================================================

/// Load a search engine from an existing index
///
/// # Parameters
/// - `index_path`: Path to the index folder
///
/// # Returns
/// - Pointer to SearchEngine on success
/// - null on failure
#[no_mangle]
pub extern "C" fn search_engine_load(index_path: *const c_char) -> *mut CSearchEngine {
    if index_path.is_null() {
        return ptr::null_mut();
    }

    let result = panic::catch_unwind(|| {
        let path_str = unsafe {
            match CStr::from_ptr(index_path).to_str() {
                Ok(s) => s,
                Err(_) => return ptr::null_mut(),
            }
        };

        // TODO: Implement actual engine loading
        // Example:
        // let engine = SearchEngine::load(path_str)?;
        // Box::into_raw(Box::new(engine)) as *mut CSearchEngine
        
        println!("Loading index from: {}", path_str);
        
        // For now, return a dummy pointer (in real impl, load actual engine)
        Box::into_raw(Box::new(())) as *mut CSearchEngine
    });

    match result {
        Ok(ptr) => ptr,
        Err(_) => ptr::null_mut(),
    }
}

/// Free a search engine instance
///
/// # Parameters
/// - `engine`: Pointer to SearchEngine
#[no_mangle]
pub extern "C" fn search_engine_free(engine: *mut CSearchEngine) {
    if engine.is_null() {
        return;
    }

    unsafe {
        let _ = panic::catch_unwind(|| {
            // TODO: Convert back to actual type and drop
            // Example:
            // let _ = Box::from_raw(engine as *mut SearchEngine);
            
            let _ = Box::from_raw(engine as *mut ());
        });
    }
}

// ============================================================================
// Search Functions
// ============================================================================

/// Perform a free-text search query
///
/// # Parameters
/// - `engine`: Pointer to SearchEngine
/// - `query`: Search query string
/// - `limit`: Maximum number of results
///
/// # Returns
/// - Pointer to search results on success
/// - null on failure
#[no_mangle]
pub extern "C" fn search_query_freetext(
    engine: *mut CSearchEngine,
    query: *const c_char,
    limit: usize,
) -> *mut CSearchResults {
    if engine.is_null() || query.is_null() {
        return ptr::null_mut();
    }

    let result = panic::catch_unwind(|| {
        let query_str = unsafe {
            match CStr::from_ptr(query).to_str() {
                Ok(s) => s,
                Err(_) => return ptr::null_mut(),
            }
        };

        // TODO: Implement actual search
        // Example:
        // let engine = unsafe { &*(engine as *const SearchEngine) };
        // let results = engine.search_freetext(query_str, limit)?;
        
        println!("Free-text query: {} (limit: {})", query_str, limit);
        
        // Create dummy results
        let mut docs = Vec::new();
        docs.push(CDocument {
            path: CString::new("document1.txt").unwrap().into_raw(),
            score: 0.95,
            doc_id: 1,
        });
        docs.push(CDocument {
            path: CString::new("document2.txt").unwrap().into_raw(),
            score: 0.87,
            doc_id: 2,
        });

        let count = docs.len();
        let results = Box::new(CSearchResults {
            documents: docs.as_mut_ptr(),
            count,
        });
        
        std::mem::forget(docs); // Prevent deallocation
        
        Box::into_raw(results)
    });

    match result {
        Ok(ptr) => ptr,
        Err(_) => ptr::null_mut(),
    }
}

/// Perform a boolean search query
///
/// # Parameters
/// - `engine`: Pointer to SearchEngine
/// - `query`: Boolean query string (e.g., "hello AND there OR NOT man")
/// - `limit`: Maximum number of results
///
/// # Returns
/// - Pointer to search results on success
/// - null on failure
#[no_mangle]
pub extern "C" fn search_query_boolean(
    engine: *mut CSearchEngine,
    query: *const c_char,
    limit: usize,
) -> *mut CSearchResults {
    if engine.is_null() || query.is_null() {
        return ptr::null_mut();
    }

    let result = panic::catch_unwind(|| {
        let query_str = unsafe {
            match CStr::from_ptr(query).to_str() {
                Ok(s) => s,
                Err(_) => return ptr::null_mut(),
            }
        };

        // TODO: Implement actual boolean search
        println!("Boolean query: {} (limit: {})", query_str, limit);
        
        // Return empty results for now
        let results = Box::new(CSearchResults {
            documents: ptr::null_mut(),
            count: 0,
        });
        
        Box::into_raw(results)
    });

    match result {
        Ok(ptr) => ptr,
        Err(_) => ptr::null_mut(),
    }
}

// ============================================================================
// Result Handling Functions
// ============================================================================

/// Get document at index from search results
///
/// # Parameters
/// - `results`: Pointer to search results
/// - `index`: Index of document to retrieve
///
/// # Returns
/// - Pointer to document on success
/// - null on failure or out of bounds
#[no_mangle]
pub extern "C" fn search_results_get_document(
    results: *const CSearchResults,
    index: usize,
) -> *const CDocument {
    if results.is_null() {
        return ptr::null();
    }

    unsafe {
        let results_ref = &*results;
        if index >= results_ref.count {
            return ptr::null();
        }
        
        results_ref.documents.add(index)
    }
}

/// Get the number of documents in search results
///
/// # Parameters
/// - `results`: Pointer to search results
///
/// # Returns
/// - Number of documents, or 0 if results is null
#[no_mangle]
pub extern "C" fn search_results_count(results: *const CSearchResults) -> usize {
    if results.is_null() {
        return 0;
    }

    unsafe { (*results).count }
}

/// Free search results
///
/// # Parameters
/// - `results`: Pointer to search results
#[no_mangle]
pub extern "C" fn search_results_free(results: *mut CSearchResults) {
    if results.is_null() {
        return;
    }

    unsafe {
        let _ = panic::catch_unwind(|| {
            let results_box = Box::from_raw(results);
            
            // Free document strings
            if !results_box.documents.is_null() {
                let docs = slice::from_raw_parts_mut(
                    results_box.documents,
                    results_box.count,
                );
                
                for doc in docs {
                    if !doc.path.is_null() {
                        let _ = CString::from_raw(doc.path);
                    }
                }
                
                // Free documents array
                let _ = Vec::from_raw_parts(
                    results_box.documents,
                    results_box.count,
                    results_box.count,
                );
            }
        });
    }
}

// ============================================================================
// Utility Functions
// ============================================================================

/// Free a C string allocated by Rust
///
/// # Parameters
/// - `s`: Pointer to C string
#[no_mangle]
pub extern "C" fn search_string_free(s: *mut c_char) {
    if s.is_null() {
        return;
    }

    unsafe {
        let _ = CString::from_raw(s);
    }
}

/// Get last error message (for debugging)
///
/// # Returns
/// - C string with error message (must be freed with search_string_free)
#[no_mangle]
pub extern "C" fn search_get_last_error() -> *mut c_char {
    // TODO: Implement thread-local error storage
    CString::new("No error information available").unwrap().into_raw()
}