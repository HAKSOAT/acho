use anyhow::Result;
use tokenizers::{Encoding, Tokenizer};

use ort::session::Session;
use ort::session::builder::GraphOptimizationLevel;

type EncodingArray = ndarray::Array2<i64>;
type InputIds = ndarray::Array2<i64>;
pub type AttentionMask = ndarray::Array2<i64>;
pub type Embeddings = ndarray::Array2<f32>;



pub enum EncodingType {
    Ids,
    AttentionMask
}

pub fn load_artifacts(model_path: String, tokenizer_path:String) -> Result<(Tokenizer, Session)> {
    let mut tokenizer = Tokenizer::from_file(&tokenizer_path)
        .expect("Failed to load tokenizer.");
    let padding = Some(tokenizers::PaddingParams {
        strategy: tokenizers::PaddingStrategy::BatchLongest,
        direction: tokenizers::PaddingDirection::Right,
        pad_to_multiple_of: None,
        pad_id: 1,
        pad_type_id: 0,
        pad_token: "<pad>".to_string(),
    });
    tokenizer.with_padding(padding);

    let session = Session::builder()?
        .with_optimization_level(GraphOptimizationLevel::Level1)?
        .with_intra_threads(4)?
        .commit_from_file(&model_path).expect("Failed to load the ONNX model.");
    Ok((tokenizer, session))
}

pub fn get_encoding_array(encodings: &Vec<Encoding>, encoding_type: EncodingType) -> Result<EncodingArray> {
    let extract: fn(&Encoding) -> &[u32] = match encoding_type {
        EncodingType::Ids => |e: &Encoding| e.get_ids(),
        EncodingType::AttentionMask => |e: &Encoding| e.get_attention_mask(),
    };

    let nrows = encodings.len();
    let ncols = extract(&encodings[0]).len();
    let vec_matrix: Vec<i64> = encodings.iter()
        .flat_map(|e| extract(e).iter().map(|&x| x as i64).collect::<Vec<i64>>())
        .collect();
    Ok(
        ndarray::Array2::from_shape_vec((nrows, ncols), vec_matrix)
            .expect("Failed to create Array2D from encodings.")
    )
}

pub fn tokenize(texts: &Vec<String>, tokenizer: &Tokenizer) -> Result<(InputIds, AttentionMask)> {
    let encodings = tokenizer.encode_batch(texts.to_vec(), true)
        .expect("Tokenization failed.");

    let input_ids = get_encoding_array(&encodings, EncodingType::Ids)?;
    let attention_mask = get_encoding_array(&encodings, EncodingType::AttentionMask)?;  
    Ok((input_ids, attention_mask))
}

pub fn run_inference<'a>(text: &Vec<String>, model: &'a mut Session, tokenizer: &Tokenizer) -> Result<Embeddings>{
    let (tokens, attn_mask) = tokenize(text, tokenizer)?;
    let token_input_value = ort::value::Tensor::from_array(tokens)?;
    let attn_mask_input_value = ort::value::Tensor::from_array(attn_mask)?;
    let dense: ort::session::SessionOutputs<'_>= model.run(
        ort::inputs!["input_ids" => token_input_value, "attention_mask" => attn_mask_input_value]
    ).expect("Embedding model inference failed.");

    let dense_embeddings = (&dense["dense_embeddings"]).try_extract_array::<f32>()?
        .into_dimensionality::<ndarray::Ix2>()
        .expect("Failed to convert embeddings to 2D array.");
    Ok(dense_embeddings.to_owned())
}

pub fn similarity(query: &Vec<String>, texts: &Vec<String>, model_path: String, tokenizer_path:String) -> Result<()> {
    let (tokenizer, mut model) = load_artifacts(model_path, tokenizer_path)?;

    let all_embeddings: Embeddings = run_inference(&texts, &mut model, &tokenizer)?;
    let query: Embeddings = run_inference(query, &mut model, &tokenizer)?;

    let similarity_matrix = query.dot(&all_embeddings);
    println!("Similarity matrix:\n{:?}", similarity_matrix);

    Ok(())
}
