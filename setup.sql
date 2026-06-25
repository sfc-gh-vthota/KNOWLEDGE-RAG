-- RAG pipeline setup with document chunking and Cortex Search Service
-- Co-authored with CoCo
/*
 * RAG Demo Setup: Cortex Search on Knowledge Base Documents
 * 
 * This script creates the infrastructure for a RAG pipeline:
 * 1. Database and schema
 * 2. Stage for markdown files (simulates S3)
 * 3. Table to hold parsed documents
 * 4. Loads documents from stage
 * 5. Python UDF for text chunking (no AI Functions privilege needed)
 * 6. Chunks documents using the Python UDF
 * 7. Creates Cortex Search Service on chunked data
 *
 * Prerequisites:
 *   - Upload .md files to the stage using:
 *     PUT file:///path/to/RAG-CORTEX-SEARCH-DEMO/docs/*.md @DOCS_STAGE AUTO_COMPRESS=FALSE;
 */

-- ============================================================
-- STEP 1: Infrastructure
-- ============================================================

USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS RAG_DEMO;
CREATE SCHEMA IF NOT EXISTS RAG_DEMO.KNOWLEDGE_BASE;
USE SCHEMA RAG_DEMO.KNOWLEDGE_BASE;

CREATE WAREHOUSE IF NOT EXISTS RAG_WH 
  WAREHOUSE_SIZE = 'XSMALL' 
  AUTO_SUSPEND = 60 
  AUTO_RESUME = TRUE;

USE WAREHOUSE RAG_WH;

-- ============================================================
-- STEP 2: Stage for markdown files
-- ============================================================

CREATE STAGE IF NOT EXISTS DOCS_STAGE
  DIRECTORY = (ENABLE = TRUE)
  COMMENT = 'Stage for knowledge base markdown documents';

-- Upload files (run from SnowSQL or Snowsight):
-- PUT file:///path/to/docs/onboarding-guide.md @DOCS_STAGE AUTO_COMPRESS=FALSE;
-- PUT file:///path/to/docs/data-governance-policy.md @DOCS_STAGE AUTO_COMPRESS=FALSE;
-- PUT file:///path/to/docs/incident-response.md @DOCS_STAGE AUTO_COMPRESS=FALSE;
-- PUT file:///path/to/docs/api-authentication.md @DOCS_STAGE AUTO_COMPRESS=FALSE;
-- PUT file:///path/to/docs/cloud-architecture.md @DOCS_STAGE AUTO_COMPRESS=FALSE;
-- PUT file:///path/to/docs/quarterly-review-process.md @DOCS_STAGE AUTO_COMPRESS=FALSE;

-- Verify files are uploaded:
LIST @DOCS_STAGE;

-- ============================================================
-- STEP 3: Table to hold parsed documents
-- ============================================================

CREATE OR REPLACE TABLE DOCUMENTS (
    doc_id STRING,
    title STRING,
    content STRING,
    source_file STRING,
    last_updated TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================
-- STEP 4: Load markdown content from stage into table
-- ============================================================

-- File format to read entire .md file as a single text value
CREATE OR REPLACE FILE FORMAT MD_FORMAT
  TYPE = 'CSV'
  FIELD_DELIMITER = NONE
  RECORD_DELIMITER = NONE
  FIELD_OPTIONALLY_ENCLOSED_BY = NONE;

-- Read actual file content from stage into DOCUMENTS table
INSERT INTO DOCUMENTS (doc_id, title, content, source_file)
SELECT
    MD5(METADATA$FILENAME) AS doc_id,
    REPLACE(REPLACE(METADATA$FILENAME, '.md', ''), '-', ' ') AS title,
    $1 AS content,
    METADATA$FILENAME AS source_file
FROM @DOCS_STAGE (FILE_FORMAT => 'MD_FORMAT')
WHERE METADATA$FILENAME LIKE '%.md';



-- Verify
SELECT doc_id, title, source_file, LENGTH(content) AS content_length 
FROM DOCUMENTS;

-- ============================================================
-- STEP 5: Python UDF for chunking (no AI Functions privilege needed)
-- ============================================================

-- This UDF replicates SPLIT_TEXT_RECURSIVE_CHARACTER behavior:
--   - Splits on markdown-aware separators (headers, code blocks, paragraphs, lines)
--   - Supports configurable chunk_size and overlap (in characters)
--   - Returns an ARRAY of text chunks

CREATE OR REPLACE FUNCTION SPLIT_TEXT_RECURSIVE(
    text_to_split STRING,
    chunk_size INT,
    chunk_overlap INT
)
RETURNS ARRAY
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
HANDLER = 'split_text'
AS
$$
def split_text(text_to_split: str, chunk_size: int, chunk_overlap: int) -> list:
    if not text_to_split:
        return []

    # Markdown-aware separators (ordered from largest to smallest boundary)
    separators = [
        "\n## ",      # h2 headers
        "\n### ",     # h3 headers
        "\n#### ",    # h4 headers
        "\n```",      # code blocks
        "\n\n",       # paragraph breaks
        "\n",         # line breaks
        " ",          # spaces
        ""           # character-level (last resort)
    ]

    def _split_recursive(text: str, seps: list) -> list:
        if len(text) <= chunk_size:
            return [text] if text.strip() else []

        # Find the best separator that exists in the text
        separator = seps[-1]
        for sep in seps:
            if sep in text:
                separator = sep
                break

        # Split on the chosen separator
        if separator == "":
            # Character-level split as last resort
            parts = [text[i:i+chunk_size] for i in range(0, len(text), chunk_size)]
        else:
            parts = text.split(separator)

        # Merge parts into chunks that respect chunk_size
        chunks = []
        current_chunk = ""

        for part in parts:
            candidate = current_chunk + separator + part if current_chunk else part

            if len(candidate) <= chunk_size:
                current_chunk = candidate
            else:
                if current_chunk:
                    chunks.append(current_chunk)
                # If single part exceeds chunk_size, recurse with finer separators
                if len(part) > chunk_size:
                    remaining_seps = seps[seps.index(separator)+1:] if separator in seps else seps[-1:]
                    chunks.extend(_split_recursive(part, remaining_seps))
                else:
                    current_chunk = part

        if current_chunk:
            chunks.append(current_chunk)

        return chunks

    # Get initial chunks
    chunks = _split_recursive(text_to_split, separators)

    # Apply overlap
    if chunk_overlap > 0 and len(chunks) > 1:
        overlapped = [chunks[0]]
        for i in range(1, len(chunks)):
            prev = chunks[i - 1]
            overlap_text = prev[-chunk_overlap:] if len(prev) >= chunk_overlap else prev
            overlapped.append(overlap_text + chunks[i])
        chunks = overlapped

    # Final cleanup: remove empty chunks
    return [c for c in chunks if c.strip()]
$$;

-- ============================================================
-- STEP 6: Chunk documents using the Python UDF
-- ============================================================

-- Chunking parameters (adjust as needed):
--   chunk_size:    max characters per chunk (1500 chars ≈ ~375 tokens)
--   chunk_overlap: overlapping characters between chunks (200 chars)

CREATE OR REPLACE TABLE DOCUMENTS_CHUNKED AS
SELECT
    d.doc_id || '-' || c.INDEX AS chunk_id,
    d.doc_id,
    d.title,
    c.VALUE::STRING AS content,
    d.source_file,
    c.INDEX AS chunk_index,
    d.last_updated
FROM DOCUMENTS d,
    LATERAL FLATTEN(
        input => SPLIT_TEXT_RECURSIVE(d.content, 100, 10)
    ) AS c;

-- Verify chunking results
SELECT 
    source_file, 
    COUNT(*) AS num_chunks, 
    AVG(LENGTH(content)) AS avg_chunk_length
FROM DOCUMENTS_CHUNKED
GROUP BY source_file;

-- ============================================================
-- STEP 7: Create Cortex Search Service on chunked data
-- ============================================================

-- Cortex Search automatically creates embeddings and a vector index.
-- Now operating on pre-chunked data for better retrieval quality.

CREATE OR REPLACE CORTEX SEARCH SERVICE DOC_SEARCH
  ON content
  ATTRIBUTES title, source_file
  WAREHOUSE = RAG_WH
  TARGET_LAG = '1 hour'
  AS (
    SELECT chunk_id, title, content, source_file
    FROM DOCUMENTS_CHUNKED
  );

-- Verify the service is created
SHOW CORTEX SEARCH SERVICES;

-- ============================================================
-- DONE! The Cortex Search Service is now ready.
-- Run the Streamlit app (streamlit_app.py) to search your docs.
-- ============================================================
