import numpy as np
from datetime import datetime
from .indexer import get_listener_model, normalize, model

def retrieve(query, top_k=5, listener_ids=None):
    if not query or not listener_ids:
        return []
    
    try:
        vec = model.encode([query])  # Ensure the query is passed as a list
        if vec is None or len(vec) == 0 or not isinstance(vec, np.ndarray):
            print("Embedding failed or returned invalid data.")
            return []
    except Exception as e:
        print(f"Embedding failed: {e}")
        return []
    
    vec = np.array([normalize(vec[0])], dtype=np.float32)
    all_results = []
    
    for listener_id in listener_ids:
        try:
            listener = get_listener_model(listener_id)

            index = listener["index"]
            print(f"{listener_id}: {index.ntotal} vectors stored")
            print(listener["metadata"])
            print(f"{listener_id}: {index.ntotal} vectors stored")
            metadata_store = listener["metadata"]
            
            if index.ntotal == 0:
                continue
            
            scores, idxs = index.search(vec, top_k)
            keys = list(metadata_store.keys())
            print(scores,idxs)
            for score, idx in zip(scores[0], idxs[0]):
            
                if idx < 0 or idx >= len(keys):
                    continue
                
                print(f"Attempting to get entry at index {idx}")
                if metadata_store is not None:
                    entry = list(metadata_store.values())[idx]
                    if entry is not None:  # Ensure the entry exists in the store
                        print("Entry retrieved successfully")
                    else:
                        print("No entry found at given index")
                else:
                    print("metadata_store is not initialized")
                
                uid = entry.get("id", str(idx))
                try:
                    ts = datetime.fromisoformat(entry['timestamp'])
                    age_seconds = (datetime.utcnow() - ts).total_seconds()
                except Exception:
                    age_seconds = 0
                
                recency_weight = max(0.1, 1 - (age_seconds / (60 * 60 * 24 * 30)))
                salience = entry.get("salience", 1.0)
                adjusted_score = float(score) * recency_weight * salience
                if adjusted_score > 0.25:
                    all_results.append({
                        "id": uid,
                        "listener_id": listener_id,
                        **entry,
                        "score": float(score),
                        "adjusted_score": adjusted_score
                    })
        except Exception as e:
            print(f"Error processing listener {listener_id}: {e}")
            continue
    
    all_results.sort(key=lambda r: -r.get("adjusted_score", 0))
    return all_results[:top_k]