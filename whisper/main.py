import whisper
import tempfile
import os
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

print("Chargement du modèle Whisper...")
model = whisper.load_model("small")
print("Modèle prêt.")

@app.post("/transcribe")
async def transcribe(audio: UploadFile = File(...)):
    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
        tmp.write(await audio.read())
        tmp_path = tmp.name

    result = model.transcribe(tmp_path, language="fr")
    os.unlink(tmp_path)

    return {
        "text": result["text"].strip(),
        "language": result["language"]
    }

@app.get("/health")
def health():
    return {"status": "ok"}