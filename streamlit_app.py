"""
RAG Knowledge Base Search — Streamlit App
Powered by Snowflake Cortex Search (Python API) + Cortex COMPLETE

Deploy as Streamlit in Snowflake (SiS) or run locally with:
  streamlit run streamlit_app.py
"""

import streamlit as st
import json
import time
from snowflake.snowpark.context import get_active_session
from snowflake.core import Root
from snowflake.cortex import Complete

# --- Page Config ---
st.set_page_config(page_title="Knowledge Base Search", page_icon="📚", layout="wide")

# --- Session ---
session = get_active_session()

# --- Constants ---
DATABASE = "RAG_DEMO"
SCHEMA = "KNOWLEDGE_BASE"
SEARCH_SERVICE = "DOC_SEARCH"
LLM_MODEL = "mistral-large2"


def search_documents(query: str, limit: int = 3) -> list:
    """Search the Cortex Search Service using the Python REST API."""
    
    start_time = time.time()
    
    root = Root(session)
    cortex_search_service = (
        root.databases[DATABASE]
        .schemas[SCHEMA]
        .cortex_search_services[SEARCH_SERVICE]
    )
    
    search_response = cortex_search_service.search(
        query=query,
        columns=["chunk_id", "title", "content", "source_file"],
        limit=limit
    )
    
    response_time = (time.time() - start_time) * 1000
    
    results = []
    if hasattr(search_response, 'results') and search_response.results:
        for result in search_response.results:
            if isinstance(result, dict):
                results.append(result)
            elif hasattr(result, 'content'):
                results.append(result.content)
            else:
                try:
                    results.append(dict(result))
                except:
                    pass
    
    return results, response_time


def generate_answer(query: str, context_docs: list) -> str:
    """Use Cortex COMPLETE to generate an answer grounded in retrieved documents."""
    
    context = "\n\n---\n\n".join([
        f"**Document: {doc.get('title', 'Unknown')}**\n{doc.get('content', '')}" 
        for doc in context_docs
    ])
    
    prompt = f"""You are a helpful knowledge base assistant. Answer the user's question 
based ONLY on the provided context documents. If the answer is not in the context, 
say "I don't have enough information to answer that question."

Be concise and specific. Reference which document the answer comes from.

Context Documents:
{context}

User Question: {query}

Answer:"""
    
    answer = Complete(LLM_MODEL, prompt, session=session)
    return answer


# --- UI ---
st.title("📚 Knowledge Base Search")
st.markdown("Ask questions about company policies, processes, and technical documentation.")
st.info("🚀 **Powered by Cortex Search Python API** — Semantic retrieval + LLM-generated answers")

# Search input
query = st.text_input(
    "What would you like to know?",
    placeholder="e.g., How do I request production database access?"
)

# Settings in sidebar
with st.sidebar:
    st.header("Settings")
    num_results = st.slider("Number of source chunks", 1, 10, 3)
    show_sources = st.checkbox("Show source documents", value=True)
    show_api_details = st.checkbox("Show API request details", value=False)
    st.markdown("---")
    st.markdown("### About")
    st.markdown("""
    This app uses:
    - **Cortex Search** (Python API) for semantic retrieval
    - **Cortex COMPLETE** (Mistral Large) for answer generation
    - **RAG pattern**: Retrieve → Augment → Generate
    """)
    st.markdown("---")
    st.markdown("### Architecture")
    st.markdown("""
    ```
    User Query
        │
        ▼
    Cortex Search Service
    (auto-embedded chunks)
        │
        ▼
    Top-K relevant chunks
        │
        ▼
    Cortex COMPLETE (LLM)
        │
        ▼
    Grounded Answer
    ```
    """)

# Execute search
if query:
    with st.spinner("Searching knowledge base..."):
        results, response_time = search_documents(query, limit=num_results)
    
    if results:
        # Display performance
        st.success(f"⚡ **Search Response**: {response_time:.0f}ms | Found {len(results)} relevant chunks")
        
        # Generate LLM answer
        with st.spinner("Generating answer..."):
            gen_start = time.time()
            answer = generate_answer(query, results)
            gen_time = (time.time() - gen_start) * 1000
        
        # Display answer
        st.markdown("### Answer")
        st.markdown(answer)
        st.caption(f"Generated in {gen_time:.0f}ms using {LLM_MODEL}")
        
        # Display sources
        if show_sources:
            st.markdown("---")
            st.markdown("### Source Documents")
            
            for i, doc in enumerate(results, 1):
                title = doc.get('title', 'Unknown')
                source = doc.get('source_file', 'Unknown')
                content = doc.get('content', '')
                
                with st.expander(f"📄 {title} ({source})"):
                    st.markdown(content)
        
        # Show API details
        if show_api_details:
            st.markdown("---")
            st.markdown("### API Request Details")
            
            with st.expander("🔧 View Cortex Search API Call", expanded=False):
                api_details = {
                    "service": f"{DATABASE}.{SCHEMA}.{SEARCH_SERVICE}",
                    "method": "cortex_search_service.search()",
                    "parameters": {
                        "query": query,
                        "columns": ["chunk_id", "title", "content", "source_file"],
                        "limit": num_results
                    },
                    "response": {
                        "result_count": len(results),
                        "response_time_ms": f"{response_time:.0f}"
                    }
                }
                
                st.markdown("**Python API Call:**")
                st.code(f"""
from snowflake.core import Root

root = Root(session)
cortex_search_service = (
    root.databases["{DATABASE}"]
    .schemas["{SCHEMA}"]
    .cortex_search_services["{SEARCH_SERVICE}"]
)

response = cortex_search_service.search(
    query="{query}",
    columns=["chunk_id", "title", "content", "source_file"],
    limit={num_results}
)
""", language="python")
                
                st.markdown("**Response Metadata:**")
                st.json(api_details["response"])
    else:
        st.warning("No relevant documents found. Try rephrasing your question.")

# Example queries
if not query:
    st.markdown("---")
    st.markdown("### Example Questions")
    
    examples = [
        "How do I request access to production databases?",
        "What are the severity levels for incidents?",
        "How does the OAuth authentication flow work?",
        "What is our data retention policy for customer records?",
        "What is our disaster recovery RTO for the primary database?",
        "How are OKRs scored in quarterly reviews?",
    ]
    
    cols = st.columns(2)
    for i, example in enumerate(examples):
        col = cols[i % 2]
        if col.button(example, key=f"example_{i}"):
            st.session_state["query"] = example
            st.rerun()
