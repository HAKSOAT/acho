use clap::{Args, Parser, Subcommand};
use seekstorm::index::{Index, open_index};
use std::path::Path;
use std::sync::Arc;
use tokio::sync::RwLock;

struct SearchFn {
    path_to_index: String,
}

impl SearchFn {
    pub async fn new() -> SearchFn {
        use seekstorm::index::{
            AccessType, FrequentwordType, IndexMetaObject, NgramSet, SimilarityType, StemmerType,
            StopwordType, TokenizerType, create_index,
        };

        let schema = serde_json::from_str(schema_json).unwrap();
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

    pub async fn ingest_json(&self, json_file: &Path) -> Result<(), Box<dyn std::error::Error>> {
        use seekstorm::ingest::IngestJson;

        let index_arc = open_index(Path::new(self.path_to_index.as_str()), false).await;

        match index_arc {
            Ok(index_arc) => {
                index_arc.ingest_json(json_file).await;
                println!("{}", self.path_to_index);
            }

            Err(_error) => {
                // Err(error.into());
                println!("error: {}", error)
            }
        }

        Ok(())
    }

    ///Functionality to search index
    pub async fn search_index(&self, query: String) {
        use seekstorm::highlighter::{Highlight, highlighter};
        use seekstorm::search::{QueryFacet, QueryRewriting, QueryType, ResultType, Search};
        use std::collections::HashSet;

        let offset = 0;
        let length = 10;
        let query_type = QueryType::Intersection;
        let result_type = ResultType::TopkCount;
        let include_uncommitted = false;
        let field_filter = Vec::new();
        let query_facets = vec![QueryFacet::String16 {
            field: "town".to_string(),
            prefix: "".to_string(),
            length: u16::MAX,
        }];
        let facet_filter = Vec::new();

        let result_sort = Vec::new();
        let index_arc = open_index(Path::new(self.path_to_index.as_str()), false).await;
        println!("{}", query);

        match index_arc {
            Ok(index_arc) => {
                let result_object = index_arc
                    .search(
                        query,
                        query_type,
                        offset,
                        length,
                        result_type,
                        include_uncommitted,
                        field_filter,
                        query_facets,
                        facet_filter,
                        result_sort,
                        QueryRewriting::SearchOnly,
                    )
                    .await;

                // ### display results

                let highlights: Vec<Highlight> = vec![Highlight {
                    field: "body".to_owned(),
                    name: String::new(),
                    fragment_number: 2,
                    fragment_size: 160,
                    highlight_markup: true,
                    ..Default::default()
                }];
                let highlighter =
                    Some(highlighter(&index_arc, highlights, result_object.query_terms).await);
                let return_fields_filter = HashSet::new();
                let distance_fields = Vec::new();
                let index = index_arc.write().await;

                for result in result_object.results.iter() {
                    let doc = index
                        .get_document(
                            result.doc_id,
                            false,
                            &highlighter,
                            &return_fields_filter,
                            &distance_fields,
                        )
                        .await
                        .unwrap();
                    println!(
                        "result {} rank {} body field {:?}",
                        result.doc_id,
                        result.score,
                        doc.get("body")
                    );
                }
                println!(
                    "result counts {} {} {}",
                    result_object.results.len(),
                    result_object.result_count,
                    result_object.result_count_total
                );

                println!(
                    "{}",
                    serde_json::to_string_pretty(&result_object.facets).unwrap()
                );
            }

            Err(_error) => {
                // Err(error.into());
            }
        }
    }
}

///CLI for keyword search
#[derive(Parser, Debug)]
#[command(version, about = "Index documents")]
pub struct SearchCli {
    #[command(subcommand)]
    pub action: Action,
}

#[derive(Subcommand, Debug)]
pub enum Action {
    Index { path_to_file: String },
    Search { keyword: String },
}

pub async fn search() -> Result<(), Box<dyn std::error::Error>> {
    let cli = SearchCli::parse();

    match &cli.action {
        Action::Index { path_to_file } => {
            let user_search = SearchFn::new(&SearchFn {
                path_to_index: String::from(""), //TODO: Add path_to_index
            })
            .await;
            let _ = user_search.ingest_json(Path::new(&path_to_file)).await;
            Ok(())
        }

        Action::Search { keyword } => {
            let user_search = SearchFn::new(&SearchFn {
                path_to_index: String::from(""), //TODO: Add path_to_index
            })
            .await;

            let _ = user_search.search_index(keyword.to_string()).await;
            Ok(())
        }
    }
}
