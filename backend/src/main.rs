use anyhow::Result;
use inference::semantic_search::{load_artifacts, Embeddings, run_inference, get_top_k};

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

    let (_raw_score, _length) = similarity_matrix.into_raw_vec_and_offset();

    let top_k = get_top_k(_raw_score, 3)?;
    for i in top_k {
        println!("{0} {1}", i.score, i.index);
    }

    Ok(())
}
