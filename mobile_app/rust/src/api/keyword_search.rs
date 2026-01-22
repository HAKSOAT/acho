use seekstorm::index::{ open_index};
use seekstorm::index::IndexArc;
use std::path::Path;


pub struct SearchFn {
    pub path_to_index: String,
}

impl SearchFn {
    pub async fn new(&self) -> SearchFn {
        use seekstorm::index::{
            AccessType, FrequentwordType, IndexMetaObject, NgramSet, SimilarityType, StemmerType,
            StopwordType, TokenizerType, FieldType, create_index, SchemaField
        };

        let schema = vec![SchemaField::new("title".to_string(), true, true, FieldType::String16, false, false, 1.0, false, false)];
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
        let _segment_number_bits1 = 11;
         create_index(
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

    pub async fn ingest_pdf_dir(&self, dir_path: &Path) {
        use seekstorm::ingest::IndexPdfFile;

        let file_path = Path::new(&dir_path);
         let index_arc: Result<IndexArc, String> = open_index(Path::new(self.path_to_index.as_str()), false).await;

        match index_arc {
            Ok(index_arc) => {
                let _ = index_arc.index_pdf_file(file_path).await;
            }

            Err(_error) => {
                 Err(_error.into());
            }
        }

        Ok(())
    }

    ///For reset functionality, clearing index
    pub async fn delete_index(&self) {
        let index_arc: Result<IndexArc, String> = open_index(Path::new(self.path_to_index.as_str()), false).await;

        match index_arc {
            Ok(index_arc) => {
               index_arc.write().await.delete_index();
            }

            Err(_) => {
                // Err(error.into());
            }
        }
    }
}
