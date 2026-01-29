use anyhow::Result;
use ndarray_stats::QuantileExt;

use inference::{load_artifacts, Embeddings, run_inference};

fn main() -> Result<()> {
    let (tokenizer, mut model) = load_artifacts("../mobile_app/assets/model.onnx".to_string(), "../mobile_app/assets/tokenizer.json".to_string())?;
    let texts = vec![
        "What is your name".to_string(),
        "Ki lo ruko e?".to_string(),
        "Ki lo je losan?".to_string(),
    ];
    let query = vec![
        "Ki lo ruko e?".to_string(),
    ];
    let all_embeddings: Embeddings = run_inference(&texts, &mut model, &tokenizer)?;
    let query_embeddings: Embeddings = run_inference(&query, &mut model, &tokenizer)?;

    let similarity_matrix = query_embeddings.dot(&all_embeddings.t());
    println!("Similarity matrix:\n{:?}", similarity_matrix);
    println!("Most similar statement: \n{:?}", similarity_matrix.argmax());
    
    Ok(())
}
