# Achọ


## Context

This project is planned to be an on-device search application for mobile, most likely the Android.

The objective is to extend semantic search functionalities to African languages on a common device such as the mobile phone. Semantic search functionalities are powered by embeddings, but the models that generate those embeddings often do not cover low-resource languages such as those spoken by Africans. They often tend to cover more global languages such as English, French, Spanish, etc.

One can imagine an African who converses mainly in their mother tongue and has a lot of documents on their phone that may be for different reasons e.g. business, religion, literature, news. In the situation where they would like to find a document that contains some context, the current search functionalities would only provide search based on filename. However, semantic search opens the doors to search at a more nuanced level.

One can also imagine that text messages are files, and an African who texts mainly in their mother tongue seeks to find texts with certain contexts from the past. Keyword search will be functional, but will put the onus on the user to remember the specific keywords from that conversation. Search of this kind makes it possible to find a wider range of documents, without exactly knowing the specific keywords for the retrieval of the relevant text.

## User Flow

- User installs the application
- User approves permission requests
- User specifies the search folders and desired file types
---
- *Assume the app completes indexing the specified files*
---

- User needs to find some files so provides the query
- User goes through the top k files in the results
- User either completes the session or refines the search

## Core

### Mobile App

- Contains the UI for user interactions
- Runs the background tasks that involves the embedding model creating embeddings and indexing them in the vector database
- Runs the search process that finds top k items in the index using the vector database

### Embedding Model

- Converts the file contexts into embeddings to be indexed in the vector database
- Keeps closeness in embedding space between cross-lingual texts that are similar
- Converts the query into embeddings to be used for nearest neighbour search

### Vector Database

- Creates an index for the embeddings
- Stores metadata for the stored embeddings
- Runs nearest neighbour search to find relevant embeddings at search time
