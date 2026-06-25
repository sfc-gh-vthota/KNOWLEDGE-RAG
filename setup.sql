/*
 * RAG Demo Setup: Cortex Search on Knowledge Base Documents
 * 
 * This script creates the infrastructure for a RAG pipeline:
 * 1. Database and schema
 * 2. Stage for markdown files (simulates S3)
 * 3. Table to hold parsed documents
 * 4. Loads documents from stage
 * 5. Creates Cortex Search Service (auto-embeds text)
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
-- LIST @DOCS_STAGE;

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

-- Read files from stage and insert into DOCUMENTS table
INSERT INTO DOCUMENTS (doc_id, title, content, source_file)
SELECT
    MD5(RELATIVE_PATH) AS doc_id,
    REPLACE(REPLACE(RELATIVE_PATH, '.md', ''), '-', ' ') AS title,
    TO_VARCHAR(GET_PRESIGNED_URL(@DOCS_STAGE, RELATIVE_PATH)) AS content,
    RELATIVE_PATH AS source_file
FROM DIRECTORY(@DOCS_STAGE)
WHERE RELATIVE_PATH LIKE '%.md';

-- Verify loaded documents
SELECT doc_id, title, source_file, LENGTH(content) AS content_length 
FROM DOCUMENTS;

-- ============================================================
-- STEP 5: Create Cortex Search Service
-- ============================================================

-- Cortex Search automatically creates embeddings and a vector index.
-- No manual EMBED_TEXT() calls needed!

CREATE OR REPLACE CORTEX SEARCH SERVICE DOC_SEARCH
  ON content
  ATTRIBUTES title, source_file
  WAREHOUSE = RAG_WH
  TARGET_LAG = '1 hour'
  AS (
    SELECT doc_id, title, content, source_file
    FROM DOCUMENTS
  );

-- Verify the service is created
SHOW CORTEX SEARCH SERVICES;

-- ============================================================
-- DONE! The Cortex Search Service is now ready.
-- Run the Streamlit app (streamlit_app.py) to search your docs.
-- ============================================================
