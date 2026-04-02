from flask import Flask, request, jsonify
from config import ROOMS
from arduino import send_command
from dotenv import python_dotenv

app = Flask(__name__)

# GET /rooms  →  liste toutes les pièces disponibles
@app.get("/rooms")
def list_rooms():
    return jsonify({
        key: {"label": val["label"], "pin": val["pin"]}
        for key, val in ROOMS.items()
    })

# POST /command  →  reçoit la commande de n8n
@app.post("/command")
def command():
    data = request.get_json()

    # validation
    if not data or "room" not in data or "action" not in data:
        return jsonify({"error": "Champs 'room' et 'action' requis"}), 400

    room_key = data["room"].lower()
    action = data["action"].upper()

    if room_key not in ROOMS:
        return jsonify({
            "error": f"Pièce inconnue : {room_key}",
            "available": list(ROOMS.keys())
        }), 404

    if action not in ("ON", "OFF"):
        return jsonify({"error": "Action doit être 'on' ou 'off'"}), 400

    pin = ROOMS[room_key]["pin"]
    success = send_command(pin, action)

    if not success:
        return jsonify({"error": "Pas de réponse de l'Arduino"}), 502

    return jsonify({
        "room": room_key,
        "label": ROOMS[room_key]["label"],
        "pin": pin,
        "action": action,
        "status": "executed"
    })

# GET /health
@app.get("/health")
def health():
    return jsonify({"status": "ok", "rooms": len(ROOMS)})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)