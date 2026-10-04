extends Resource
class_name DecisionModel

## A Jev-style decision model (TypeSafe System One).
## Instead of writing text it answers typed questions (choice / score / noul)
## about a block of state with probabilities and a confidence value.

## Base URL of the server, e.g. "http://127.0.0.1:11435" (Ollaya / Ollama)
## or the hosted TypeSafe API base URL.
@export var endpoint: String = "http://127.0.0.1:11435"
## "/api/decide" for Ollaya/Ollama, "/v1/systemone" for the TypeSafe wire format.
@export var path: String = "/api/decide"
@export var Name: String = "jev"
## Environment variable holding a bearer token. Empty or unset means no auth.
@export var api_key_env: String = "TYPESAFE_API_KEY"
## Only sent to the native /api/* endpoints; /v1/* rejects unknown fields.
@export var keep_alive: String = "10m"


func build_body(state: String, questions: Dictionary) -> Dictionary:
	var body := {"model": Name, "state": state, "questions": questions}
	if path.begins_with("/api/") and keep_alive != "":
		body["keep_alive"] = keep_alive
	return body


func headers() -> PackedStringArray:
	var h := PackedStringArray(["Content-Type: application/json"])
	var key := OS.get_environment(api_key_env) if api_key_env != "" else ""
	if key != "":
		h.append("Authorization: Bearer %s" % key)
	return h
