"""
RAG Knowledge Base Search — Streamlit App
Powered by Snowflake Cortex Search + Cortex COMPLETE

Deploy as Streamlit in Snowflake (SiS) or run locally with:
  streamlit run streamlit_app.py
"""

import streamlit as st
from snowflake.snowpark.context import get_active_session
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

# --- Helper Functions ---

def search_documents(query: str, limit: int = 3) -> list:
    """Search the Cortex Search Service for relevant documents."""
    
    # Use Cortex Search via SQL (compatible with SiS)
    search_sql = f"""
    SELECT *
    FROM TABLE(
        {DATABASE}.{SCHEMA}.{SEARCH_SERVICE}!SEARCH(
            '{query.replace("'", "''")}',
            {{
                'columns': ['title', 'content', 'source_file'],
                'limit': {limit}
            }}
        )
    )
    """
    
    results = session.sql(search_sql).collect()
    return results


def generate_answer(query: str, context_docs: list) -> str:
    """Use Cortex COMPLETE to generate an answer grounded in retrieved documents."""
    
    # Build context from retrieved documents
    context = "\n\n---\n\n".join([
        f"**Document: {doc['TITLE']}**\n{doc['CONTENT']}" 
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

# Search input
query = st.text_input(
    "What would you like to know?",
    placeholder="e.g., How do I request production database access?"
)

# Settings in sidebar
with st.sidebar:
    st.header("Settings")
    num_results = st.slider("Number of source documents", 1, 5, 3)
    show_sources = st.checkbox("Show source documents", value=True)
    st.markdown("---")
    st.markdown("### About")
    st.markdown("""
    This app uses:
    - **Cortex Search** for semantic document retrieval
    - **Cortex COMPLETE** (Mistral Large) for answer generation
    - **RAG pattern**: Retrieve → Augment → Generate
    """)

# Execute search
if query:
    with st.spinner("Searching knowledge base..."):
        # Step 1: Retrieve relevant documents
        results = search_documents(query, limit=num_results)
    
    if results:
        # Step 2: Generate LLM answer
        with st.spinner("Generating answer..."):
            answer = generate_answer(query, results)
        
        # Display answer
        st.markdown("### Answer")
        st.markdown(answer)
        
        # Display sources
        if show_sources:
            st.markdown("---")
            st.markdown("### Source Documents")
            
            for i, doc in enumerate(results, 1):
                with st.expander(f"📄 {doc['TITLE']} ({doc['SOURCE_FILE']})"):
                    st.markdown(doc['CONTENT'])
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
