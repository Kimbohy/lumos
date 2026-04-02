# Service de Transcription Whisper

Ce dossier contient un microservice basé sur FastAPI permettant d'effectuer des transcriptions audio à l'aide du modèle `openai/whisper`.

## Prérequis

- Python 3.9+
- `ffmpeg` doit être installé sur votre système (nécessaire pour Whisper).

### Installation de FFmpeg

_Sous Ubuntu/Debian :_

```bash
sudo apt update && sudo apt install ffmpeg
```

_Sous macOS (Homebrew) :_

```bash
brew install ffmpeg
```

## Installation des dépendances

Il est recommandé d'utiliser un environnement virtuel :

```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Démarrage du service

Pour lancer l'API localement avec `uvicorn` :

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

L'API sera accessible sur `http://localhost:8000`. Vous pouvez consulter la documentation interactive Swagger générée automatiquement par FastAPI sur `http://localhost:8000/docs`.

## Endpoints

- **`POST /transcribe`** : Transcrire un fichier audio.
  - Paramètre _form-data_ : `audio` (le fichier vocal).
- **`GET /health`** : Vérifier l'état de l'API.

## Tests

Vous pouvez utiliser des outils comme `curl` ou Postman pour tester l'endpoint de transcription. Par exemple, avec `curl` :

```bash
curl -X POST "http://localhost:8000/transcribe" -F "audio=@/path/to/your/audiofile.mp3"
```
