use anyhow::Result;

use inference::{load_artifacts, Embeddings, run_inference};

fn main() -> Result<()> {
    let (tokenizer, mut model) = load_artifacts()?;
    let texts = vec![
        "What is your name",
        "Ki lo ruko e?",
        "Ki lo je losan?"
    ];
    let all_embeddings: Embeddings = run_inference(&texts, &mut model, &tokenizer)?;
    let similarity_matrix = all_embeddings.dot(&all_embeddings.t());
    println!("Similarity matrix:\n{:?}", similarity_matrix);
    
    Ok(())
}