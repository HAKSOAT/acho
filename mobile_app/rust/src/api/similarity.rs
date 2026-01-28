use anyhow::Result;
use crate::api::acho::{load_artifacts, Embeddings, run_inference};

fn semanticSearch(texts: &Vec<String>) -> Result<()> {
    let (tokenizer, mut model) = load_artifacts()?;

    let all_embeddings: Embeddings = run_inference(&texts, &mut model, &tokenizer)?;
    let similarity_matrix = all_embeddings.dot(&all_embeddings.t());
    println!("Similarity matrix:\n{:?}", similarity_matrix);
    
    Ok(())
}
