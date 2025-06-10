import numpy as np
from .indexer import get_listener_model, normalize, generate_tags, model

def retrieve(query, top_k=5, time_range=None, listener_ids=None):
    if listener_ids is None:
        raise ValueError("listener_ids is required")

    all_results = []

    tags = generate_tags(query)
    print("Tags:", tags)

    vec = model.encode([query])[0]
    vec = np.array([normalize(vec)], dtype=np.float32)

    for listener_id in listener_ids:
        listener = get_listener_model(listener_id)
        index = listener["index"]
        metadata_store = listener["metadata"]

        if index.ntotal == 0 or not metadata_store:
            continue

        scores, idxs = index.search(vec, top_k)
        keys = list(metadata_store.keys())

        for score, idx in zip(scores[0], idxs[0]):
            if idx < 0 or idx >= len(keys):
                continue
            uid = keys[idx]
            entry = metadata_store[uid]

            if not set(tags).intersection(entry['tags']):
                continue

            if time_range:
                start, end = time_range
                if not (start <= entry['timestamp'] <= end):
                    continue

            all_results.append({
                "id": uid,
                "listener_id": listener_id,
                **entry,
                "score": float(score)
            })

    # Optional: sort all results by score descending
    all_results.sort(key=lambda r: -r["score"])

    return all_results[:top_k]
