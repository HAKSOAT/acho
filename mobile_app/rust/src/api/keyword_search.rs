use seekstorm::index::{Index, open_index};
use std::path::Path;
use std::sync::Arc;
use tokio::sync::RwLock;

struct SearchFn {
    path_to_index: String,
}

impl SearchFn {
    pub async fn new(&self) -> SearchFn {
        use seekstorm::index::{
            AccessType, FrequentwordType, IndexMetaObject, NgramSet, SimilarityType, StemmerType,
            StopwordType, TokenizerType, create_index,
        };

        let schema = SchemaField::new("title".to_string(), true, true, FieldType::String16, false, false, 1.0, false, false);
        let meta = IndexMetaObject {
            id: 0,
            name: "acho_index".into(),
            similarity: SimilarityType::Bm25f,
            tokenizer: TokenizerType::AsciiAlphabetic,
            stemmer: StemmerType::None,
            stop_words: StopwordType::None,
            frequent_words: FrequentwordType::English,
            ngram_indexing: NgramSet::NgramFF as u8,
            access_type: AccessType::Mmap,
            spelling_correction: None,
            query_completion: None,
        };
        let segment_number_bits1 = 11;
        let index_arc = create_index(
            Path::new(self.path_to_index.as_str()),
            meta,
            &schema,
            &Vec::new(),
            11,
            false,
            None,
        )
        .await;

        SearchFn {
            path_to_index: self.path_to_index.clone(),
        }
    }

    pub async fn ingest_pdf_dir(&self, dir_path: &Path) -> Result<(), Box<dyn std::error::Error>> {
        use seekstorm::ingest::IndexPdfFile;

        let file_path = Path::new(&dir_path);
        let index_arc = open_index(Path::new(self.path_to_index.as_str()), false).await;

        match index_arc {
            Ok(mut index_arc) => {
                let _ = index_arc.index_pdf_file(file_path).await;
            }

            Err(error) => {
                // Err(error.into());
                println!("error: {}", error)
            }
        }

        Ok(())
    }

    ///For reset functionality, clearing index
    pub async fn delete_index(&self) -> () {
        let index_arc = open_index(Path::new(self.path_to_index.as_str()), false).await;

        match index_arc {
            Ok(index_arc) => {
                let _ = index_arc.write().await.delete_index();
            }

            Err(error) => {
                // Err(error.into());
            }
        }
    }