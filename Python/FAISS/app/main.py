from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from .indexer import add_memory, save_index, clear_index, get_all_metadata

from .search import retrieve

app = FastAPI()

class MemoryItem(BaseModel):
    text: str
    listener_ids: List[str]
    timestamp: Optional[str] = None

class QueryRequest(BaseModel):
    query: str
    top_k: Optional[int] = 5
    listener_ids: List[str]
    time_range: Optional[List[str]] = None

@app.post("/add")
def add_entry(item: MemoryItem):
    uid = add_memory(item.text, item.timestamp or datetime.utcnow().isoformat(), item.listener_ids)
    save_index(item.listener_ids)
    return {"status": "added", "id": uid}

@app.post("/query")
def query_entries(q: QueryRequest):
    results = retrieve(q.query, q.top_k, q.listener_ids)
    if not results:
        raise HTTPException(status_code=404, detail="No relevant memories found")
    return {"results": results}
    
@app.get("/all/{listener_id}")
def all_entries(listener_id: str):
    return get_all_metadata(listener_id)

@app.delete("/clear/{listener_id}")
def clear_entries(listener_id: str):
    clear_index(listener_id)
    return {"status": "cleared"}
