import os
import faiss
import numpy as np
import uuid
import json
import requests
from sentence_transformers import SentenceTransformer
from datetime import datetime

INDEX_PATH = os.path.join(os.path.dirname(__file__), '../models/faiss.index')

model = SentenceTransformer('all-MiniLM-L6-v2')
embedding_dim = 384
metadata_store = {}

# Set up GPU index
res = faiss.StandardGpuResources()
cpu_index = faiss.IndexFlatIP(embedding_dim)
index = faiss.index_cpu_to_gpu(res, 0, cpu_index)

# Adjust this to your Windows host IP (usually 172.22.224.1 or check `ipconfig` under WSL adapter)
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://192.168.1.22:11434")

def normalize(vec):
    norm = np.linalg.norm(vec)
    return vec / norm if norm != 0 else vec

def generate_tags(text):
    # Use Ollama Web API to generate tags in structured JSON format
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
        "create informative tags that aid memory recall. "
        "Do not fabricate content. Only use what is directly implied or stated. "
        "Respond strictly using the provided JSON schema."
        f"Heres your message:{text}"
        )
        response = requests.post(
            f"{OLLAMA_HOST}/api/generate",
            json={"model": "hf.co/MaziyarPanahi/Phi-3.5-mini-instruct-GGUF:Q4_K_M", "prompt": prompt, "stream": False, "format":schema,"temperature":0.0},
            timeout=10
        )
        if response.ok:
            
            output = response.json().get("response", "{}")
            
            parsed = json.loads(output)
           
            if isinstance(parsed, dict) and isinstance(parsed.get("tags"), list):
                print(parsed["tags"])
                return parsed["tags"]
    except Exception as e:
        print(f"Tag generation failed: {e}")
    return ["uncategorized"]

def add_memory(text, timestamp):

    tags = generate_tags(text)

    vec = model.encode([text])[0]
    vec = np.array([normalize(vec)], dtype=np.float32)
    uid = str(uuid.uuid4())
    index.add(vec)
    metadata_store[uid] = {
        "text": text,
        "tags": tags,
        "timestamp": timestamp
    }
    return uid

def save_index():
    cpu_idx = faiss.index_gpu_to_cpu(index)
    faiss.write_index(cpu_idx, INDEX_PATH)

def clear_index():
    global index, metadata_store
    cpu_index = faiss.IndexFlatIP(embedding_dim)
    index = faiss.index_cpu_to_gpu(res, 0, cpu_index)
    metadata_store = {}
    if os.path.exists(INDEX_PATH):
        os.remove(INDEX_PATH)

def get_all_metadata():
    return metadata_store

def get_index():
    return index, metadata_store, model

