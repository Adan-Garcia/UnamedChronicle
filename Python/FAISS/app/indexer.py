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

OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://192.168.1.22:11434")
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
            "Respond strictly using the provided JSON schema."
            f"Heres your message:{text}"
        )
        response = requests.post(
            f"{OLLAMA_HOST}/api/generate",
            json={"model": "hf.co/MaziyarPanahi/Phi-3.5-mini-instruct-GGUF:Q4_K_M", "prompt": prompt, "stream": False, "format": schema, "temperature": 0.0},
            timeout=10
        )
        if response.ok:
            output = response.json().get("response", "{}")
            parsed = json.loads(output)
            if isinstance(parsed, dict) and isinstance(parsed.get("tags"), list):
                return parsed["tags"]
    except Exception as e:
        print(f"Tag generation failed: {e}")
    return ["uncategorized"]

def _get_listener_path(listener_id):
    return os.path.join(BASE_INDEX_DIR, f"{listener_id}.index")

def get_listener_model(listener_id):
    if listener_id not in listener_models:
        path = _get_listener_path(listener_id)
        cpu_index = faiss.IndexFlatIP(embedding_dim)
        idx = faiss.index_cpu_to_gpu(res, 0, cpu_index)
        metadata = {}
        if os.path.exists(path):
            cpu_idx = faiss.read_index(path)
            idx = faiss.index_cpu_to_gpu(res, 0, cpu_idx)
        listener_models[listener_id] = {
            "index": idx,
            "metadata": metadata
        }
    return listener_models[listener_id]

def add_memory(text, timestamp, listener_ids):
    tags = generate_tags(text)
    vec = model.encode([text])[0]
    vec = np.array([normalize(vec)], dtype=np.float32)
    uid = str(uuid.uuid4())

    for listener_id in listener_ids:
        listener = get_listener_model(listener_id)
        listener["index"].add(vec)
        listener["metadata"][uid] = {
            "text": text,
            "tags": tags,
            "timestamp": timestamp
        }

    return uid

def save_index(listener_ids):
    for listener_id in listener_ids:
        listener = get_listener_model(listener_id)
        cpu_idx = faiss.index_gpu_to_cpu(listener["index"])
        faiss.write_index(cpu_idx, _get_listener_path(listener_id))

def clear_index(listener_ids):
    for listener_id in listener_ids:
        path = _get_listener_path(listener_id)
        if os.path.exists(path):
            os.remove(path)
        listener_models[listener_id] = {
            "index": faiss.index_cpu_to_gpu(res, 0, faiss.IndexFlatIP(embedding_dim)),
            "metadata": {}
        }

def get_all_metadata(listener_id):
    all_data = {}
   
    listener = get_listener_model(listener_id)
    all_data[listener_id] = listener["metadata"]
    return all_data
