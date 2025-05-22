from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from .indexer import add_memory, save_index, clear_index, get_all_metadata
from .search import retrieve

app = FastAPI()

class MemoryItem(BaseModel):
    text: str
    
    timestamp: Optional[str] = None

class QueryRequest(BaseModel):
    query: str
    top_k: int = 5

    time_range: Optional[List[str]] = None

@app.post("/add")
def add_entry(item: MemoryItem):
    uid = add_memory(item.text, item.timestamp or datetime.utcnow().isoformat())
    save_index()
    return {"status": "added", "id": uid}

@app.post("/query")
def query_entries(q: QueryRequest):
    results = retrieve(q.query, q.top_k, q.time_range)
    if not results:
        raise HTTPException(status_code=404, detail="No relevant memories found")
    return {"results": results}

@app.get("/all")
def all_entries():
    return get_all_metadata()

@app.delete("/clear")
def clear_entries():
    clear_index()
    return {"status": "cleared"}
