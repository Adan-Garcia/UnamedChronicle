import numpy as np
from .indexer import get_index, normalize, generate_tags

def retrieve(query, top_k=5, time_range=None):
    # If no memories, return empty
    index, metadata_store, model = get_index()
    if index.ntotal == 0 or not metadata_store:
        return []
    # Auto-infer tags if none provided
    tags =  generate_tags(query)
    print(tags)
    # Encode and search
    vec = model.encode([query])[0]
    vec = np.array([normalize(vec)], dtype=np.float32)
    scores, idxs = index.search(vec, top_k)
    results = []
    keys = list(metadata_store.keys())
    for score, idx in zip(scores[0], idxs[0]):
        # Skip invalid indices
        if idx < 0 or idx >= len(keys):
            continue
        uid = keys[idx]
        entry = metadata_store[uid]
        # Filter by tags
        if not set(tags).intersection(entry['tags']):
            continue
        # Filter by time range
        if time_range:
            start, end = time_range
            if not (start <= entry['timestamp'] <= end):
                continue
        results.append({"id": uid, **entry, "score": float(score)})
    return results