extends Node

# --- Gameplay flow (direct eval) ---
func start_gameplay() -> void:
	JavaScriptBridge.eval("window.CouchGames.gameplayStart()")

func stop_gameplay() -> void:
	JavaScriptBridge.eval("window.CouchGames.gameplayEnd()")

func complete_gameplay() -> void:
	JavaScriptBridge.eval("window.CouchGames.gameplayComplete()")

# --- Helper to get base URL ---
func _get_base_url() -> String:
	if OS.get_name() == "HTML5":
		return JavaScriptBridge.eval("window.location.origin")
	return "https://couchgames.io"

# --- HTTP request helper ---
func _http_get(endpoint: String) -> Dictionary:
	# Local development fallback (non-HTML5)
	if OS.get_name() != "HTML5":
		if endpoint == "/api/game/getExperienceData":
			return {
				"success": true,
				"payload": {
					"date": "2026-06-03T12:27:46.492Z",
					"files": [],
					"type": "monthly",
					"mode": "standalone",
					"experienceIndex": 0,
					"title": "Local Test",
					"experienceId": "local-test-id",
					"experienceUrl": "",
					"experienceName": "Local Test"
				}
			}
		elif endpoint == "/api/game/getSessionStats":
			return {
				"success": true,
				"payload": {
					"cumulativeGameplayTimeMs": 5000,
					"gameplayCompleted": true
				}
			}
		else:
			return {"success": false, "message": "Unknown endpoint"}

	# HTML5 (live) request
	var http = HTTPRequest.new()
	add_child(http)
	var url = _get_base_url() + endpoint
	var error = http.request(url)
	if error != OK:
		http.queue_free()
		return {"success": false, "message": "HTTP request failed"}
	var response = await http.request_completed
	http.queue_free()
	var body = response[3].get_string_from_utf8()
	var json = JSON.parse_string(body)
	# Safety checks
	if json and json is Dictionary and json.has("success"):
		if json.success:
			return {"success": true, "payload": json.payload}
		else:
			return {"success": false, "message": json.get("message", "Unknown error")}
	else:
		return {"success": false, "message": "Invalid response"}

# --- Data retrieval via HTTP ---
func get_experience_data() -> Dictionary:
	return await _http_get("/api/game/getExperienceData")

func get_session_stats() -> Dictionary:
	return await _http_get("/api/game/getSessionStats")
