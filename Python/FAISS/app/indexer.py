import os
import faiss
import numpy as np
import uuid
import json
import requests
from sentence_transformers import SentenceTransformer
from datetime import datetime

model = SentenceTransformer('all-MiniLM-L6-v2')
embedding_dim = 384
res = faiss.StandardGpuResources()
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://172.18.176.1:11434")
BASE_INDEX_DIR = os.path.join(os.path.dirname(__file__), '../models/listeners')
os.makedirs(BASE_INDEX_DIR, exist_ok=True)
listener_models = {}

def normalize(vec):
    norm = np.linalg.norm(vec)
    return vec / norm if norm != 0 else vec

def generate_tags(text):
    try:
        schema = {
            "type": "object",
            "properties": {
                "tags": {
                    "type": "array",
                    "items": {"type": "string"},
                    "minItems": 1,
                    "maxItems": 10
                }
            },
            "required": ["tags"]
        }
        prompt = (
            "You are a precise and concise memory tagging assistant. "
            "You must extract the most relevant keywords as lowercase, one-word tags, based on supplied information. "
            "Do not fabricate content. Only use what is directly implied or stated. "
            f"Here's your message:{text}"
        )
        response = requests.post(
            f"{OLLAMA_HOST}/api/generate",
            json={"model": "hf.co/MaziyarPanahi/Phi-3.5-mini-instruct-GGUF:Q4_K_M", "prompt": prompt, "stream": False, "format": schema},
            timeout=10
        )
        if response.ok:
            output = response.json().get("response", "{}")
            parsed = json.loads(output)
            if isinstance(parsed, dict) and isinstance(parsed.get("tags"), list):
                return parsed["tags"]
    except requests.Timeout as e:
        print("Request timed out:", e)
    except requests.HTTPError as e:
        print("HTTP Error occurred:", e)
    except Exception as e:
        print("An error occurred:", e)
    return ["uncategorized"]

def _get_listener_path(listener_id):
    return os.path.join(BASE_INDEX_DIR, f"{listener_id}.index")


def get_listener_model(listener_id):
    if listener_id not in listener_models:
        path = _get_listener_path(listener_id)
        cpu_index = faiss.IndexFlatIP(embedding_dim)
        idx = faiss.index_cpu_to_gpu(res, 1, cpu_index)
        metadata = load_metadata(listener_id)
        if os.path.exists(path):
            try:
                cpu_idx = faiss.read_index(path)
                if cpu_idx.d != embedding_dim:
                    raise ValueError("Dimension mismatch in loaded index")
                idx = faiss.index_cpu_to_gpu(res, 0, cpu_idx)
            except Exception as e:
                print(f"Error loading index for listener {listener_id}: {e}")
                idx = faiss.index_cpu_to_gpu(res, 0, cpu_index)
        listener_models[listener_id] = {
            "index": idx,
            "metadata": metadata if metadata is not None else {}
        }
    print(listener_models[listener_id])
    return listener_models[listener_id]

def add_memory(text, timestamp, listener_ids):
    tags = generate_tags(text)
    vec = model.encode([text])[0]
    vec = np.array([normalize(vec)], dtype=np.float32)
    uid = str(uuid.uuid4())
    
    for listener_id in listener_ids:
        listener = get_listener_model(listener_id)
        
        # Initialize metadata if it doesn't exist
        if "metadata" not in listener:
            listener["metadata"] = {}
        
        pos = listener["index"].ntotal  # Get insertion position before adding
        listener["index"].add(vec)
        
        # Save the new entry in metadata
        listener["metadata"][uid] = {
            "id": uid,
            "text": text,
            "tags": tags,
            "timestamp": timestamp
        }
    
    save_index(listener_ids)
    save_metadata(listener_id)
    return uid

def save_index(listener_ids):
    for listener_id in listener_ids:
        path = _get_listener_path(listener_id)
        cpu_idx = faiss.index_gpu_to_cpu(get_listener_model(listener_id)["index"])
        faiss.write_index(cpu_idx, path)

def clear_index(listener_ids):
    for listener_id in listener_ids:
        path = _get_listener_path(listener_id)
        if os.path.exists(path):
            os.remove(path)
            save_metadata(listener_id)  # Ensure metadata is saved before removing from memory
        listener_models[listener_id] = {
            "index": faiss.index_cpu_to_gpu(res, 0, faiss.IndexFlatIP(embedding_dim)),
            "metadata": {}
        }

def get_all_metadata(listener_id):
    return load_metadata(listener_id)

def _get_metadata_path(listener_id):
    return os.path.join(BASE_INDEX_DIR, f"{listener_id}.meta.json")

def save_metadata(listener_id):
    with open(_get_metadata_path(listener_id), 'w', encoding='utf-8') as f:
        json.dump(get_listener_model(listener_id)["metadata"], f)

def load_metadata(listener_id):
    path = _get_metadata_path(listener_id)
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}