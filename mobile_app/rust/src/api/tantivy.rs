use anyhow::{anyhow, Result};
use once_cell::sync::Lazy;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use tantivy::collector::TopDocs;
use tantivy::query::QueryParser;
use tantivy::schema::*;
use tantivy::{ Index, IndexReader, IndexWriter, ReloadPolicy, TantivyDocument, Term};


#[derive(Debug, Clone)]
pub struct Document {
    pub id: String,
    pub text: String,
}


#[derive(Debug, Clone)]
pub struct SearchResult {
    pub score: f32,
    pub doc: Document,
}


struct TantivyApi {
    index: Index,
    writer: Mutex<IndexWriter>,
    reader: IndexReader,
    schema: Schema,
    id_field: Field,
    text_field: Field,
}


static STATE: Lazy<Arc<Mutex<Option<TantivyApi>>>> = Lazy::new(|| Arc::new(Mutex::new(None)));



#[flutter_rust_bridge::frb(sync)]
pub fn init_tantivy(dir_path: String) -> Result<()> {
    let mut state_lock = STATE.lock().unwrap();
    if state_lock.is_some() {
        
        return Ok(());
    }

    let index_dir = PathBuf::from(dir_path);
    std::fs::create_dir_all(&index_dir)?;

    let (index, schema) = if index_dir.join("meta.json").exists() {
        
        let index = Index::open_in_dir(&index_dir)?;
        let schema = index.schema();
        (index, schema)
    } else {
        
        let mut schema_builder = Schema::builder();
        
        schema_builder.add_text_field("id", STRING | STORED);
        
        schema_builder.add_text_field("text", TEXT | STORED);
        let schema = schema_builder.build();
        let index = Index::create_in_dir(&index_dir, schema.clone())?;
        (index, schema)
    };

    let id_field = schema.get_field("id").map_err(|_| anyhow!("'id' field not found"))?;
    let text_field = schema.get_field("text").map_err(|_| anyhow!("'text' field not found"))?;

    let writer = index.writer(50_000_000)?; 

    
    let reader = index
        .reader_builder()
        .reload_policy(ReloadPolicy::Manual)
        .try_into()?;

    let api = TantivyApi {
        index,
        writer: Mutex::new(writer),
        reader,
        schema,
        id_field,
        text_field,
    };

    *state_lock = Some(api);

    Ok(())
}




pub fn add_document(doc: Document) -> Result<()> {
    let state_lock = STATE.lock().unwrap();
    let api = state_lock.as_ref().ok_or_else(|| anyhow!("Tantivy not initialized"))?;

    let mut writer = api.writer.lock().unwrap();

    
    let id_term = Term::from_field_text(api.id_field, &doc.id);
    writer.delete_term(id_term.clone());

    let mut tantivy_doc = TantivyDocument::new();
    tantivy_doc.add_text(api.id_field, &doc.id);
    tantivy_doc.add_text(api.text_field, &doc.text);

    writer.add_document(tantivy_doc)?;
    writer.commit()?;

    Ok(())
}


pub fn search_documents(query: String, top_k: usize) -> Result<Vec<SearchResult>> {
    let state_lock = STATE.lock().unwrap();
    let api = state_lock.as_ref().ok_or_else(|| anyhow!("Tantivy not initialized"))?;

    
    api.reader.reload()?;

    
    let searcher = api.reader.searcher();

    let query_parser = QueryParser::for_index(&api.index, vec![api.text_field]);
    let query = query_parser.parse_query(&query)?;

    let top_docs = searcher.search(&query, &TopDocs::with_limit(top_k))?;

    let mut results = Vec::new();
    for (score, doc_address) in top_docs {
        let retrieved_doc = searcher.doc::<TantivyDocument>(doc_address)?;
        let id = retrieved_doc.get_first(api.id_field)
            .and_then(|v| v.as_str())
            .unwrap_or_default()
            .to_string();
        let text = retrieved_doc.get_first(api.text_field)
            .and_then(|v| v.as_str())
            .unwrap_or_default()
            .to_string();

        results.push(SearchResult {
            score,
            doc: Document { id, text },
        });
    }

    Ok(results)
}



#[flutter_rust_bridge::frb(sync)]
pub fn get_document_by_id(id: String) -> Result<Option<Document>> {
    let state_lock = STATE.lock().unwrap();
    let api = state_lock.as_ref().ok_or_else(|| anyhow!("Tantivy not initialized"))?;

    
    let searcher = api.reader.searcher();

    let id_term = Term::from_field_text(api.id_field, &id);
    let query = tantivy::query::TermQuery::new(id_term, IndexRecordOption::Basic);

    let top_docs = searcher.search(&query, &TopDocs::with_limit(1))?;

    if let Some((_, doc_address)) = top_docs.first() {
        let retrieved_doc = searcher.doc::<TantivyDocument>(*doc_address)?;
        let text = retrieved_doc.get_first(api.text_field)
            .and_then(|v| v.as_str())
            .unwrap_or_default()
            .to_string();

        return Ok(Some(Document { id, text }));
    }

    Ok(None)
}



pub fn update_document(doc: Document) -> Result<()> {
    
    add_document(doc)
}


pub fn delete_document(id: String) -> Result<()> {
    let state_lock = STATE.lock().unwrap();
    let api = state_lock.as_ref().ok_or_else(|| anyhow!("Tantivy not initialized"))?;

    let mut writer = api.writer.lock().unwrap();
    let id_term = Term::from_field_text(api.id_field, &id);

    writer.delete_term(id_term);
    writer.commit()?;

    Ok(())
}


pub fn add_documents_batch(docs: Vec<Document>) -> Result<()> {
    let state_lock = STATE.lock().unwrap();
    let api = state_lock.as_ref().ok_or_else(|| anyhow!("Tantivy not initialized"))?;

    let mut writer = api.writer.lock().unwrap();

    for doc in docs {
        
        let id_term = Term::from_field_text(api.id_field, &doc.id);
        writer.delete_term(id_term);

        let mut tantivy_doc = TantivyDocument::new();
        tantivy_doc.add_text(api.id_field, &doc.id);
        tantivy_doc.add_text(api.text_field, &doc.text);

        writer.add_document(tantivy_doc)?;
    }

    
    writer.commit()?;

    Ok(())
}


pub fn delete_documents_batch(ids: Vec<String>) -> Result<()> {
    let state_lock = STATE.lock().unwrap();
    let api = state_lock.as_ref().ok_or_else(|| anyhow!("Tantivy not initialized"))?;

    let mut writer = api.writer.lock().unwrap();

    for id in ids {
        let id_term = Term::from_field_text(api.id_field, &id);
        writer.delete_term(id_term);
    }

    
    writer.commit()?;

    Ok(())
}



#[flutter_rust_bridge::frb(sync)]
pub fn commit() -> Result<()> {
    let state_lock = STATE.lock().unwrap();
    let api = state_lock.as_ref().ok_or_else(|| anyhow!("Tantivy not initialized"))?;

    let mut writer = api.writer.lock().unwrap();
    writer.commit()?;

    Ok(())
}



pub fn add_document_no_commit(doc: Document) -> Result<()> {
    let state_lock = STATE.lock().unwrap();
    let api = state_lock.as_ref().ok_or_else(|| anyhow!("Tantivy not initialized"))?;

    let mut writer = api.writer.lock().unwrap();

    let id_term = Term::from_field_text(api.id_field, &doc.id);
    writer.delete_term(id_term);

    let mut tantivy_doc = TantivyDocument::new();
    tantivy_doc.add_text(api.id_field, &doc.id);
    tantivy_doc.add_text(api.text_field, &doc.text);

    writer.add_document(tantivy_doc)?;

    Ok(())
}


pub fn delete_document_no_commit(id: String) -> Result<()> {
    let state_lock = STATE.lock().unwrap();
    let api = state_lock.as_ref().ok_or_else(|| anyhow!("Tantivy not initialized"))?;

    let mut writer = api.writer.lock().unwrap();
    let id_term = Term::from_field_text(api.id_field, &id);

    writer.delete_term(id_term);

    Ok(())
}
