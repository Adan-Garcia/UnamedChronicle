extends Resource
class_name AIModel

## Text-generation model served by an Ollama-compatible /api/generate endpoint.
@export var endpoint: String = "http://127.0.0.1:11434"
@export var Name: String = "llama3"
@export var extras: Dictionary = {"temperature": 0.4}
