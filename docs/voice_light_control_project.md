# Lumos

Voice-Controlled Light System

> Personal project — Control lights using natural voice commands via speech-to-text recognition, AI processing, and Arduino

---

## Table of Contents

- [Lumos](#lumos)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Global Architecture](#global-architecture)
  - [System Components](#system-components)
    - [1. Flutter Application](#1-flutter-application)
    - [2. Python Server — Whisper](#2-python-server--whisper)
    - [3. n8n — Automation and AI](#3-n8n--automation-and-ai)
    - [4. Flask Bridge — Serial Communication](#4-flask-bridge--serial-communication)
    - [5. Arduino Uno — Physical Control](#5-arduino-uno--physical-control)
  - [Complete Data Flow](#complete-data-flow)
  - [Hardware Configuration](#hardware-configuration)
    - [PC (local server)](#pc-local-server)
    - [Required electronic hardware](#required-electronic-hardware)
  - [Software Configuration](#software-configuration)
    - [System dependencies (Debian)](#system-dependencies-debian)
    - [Python dependencies](#python-dependencies)
    - [Flutter dependencies (Dart packages)](#flutter-dependencies-dart-packages)
    - [Network ports used](#network-ports-used)
  - [Technical Choices and Rationale](#technical-choices-and-rationale)
    - [Why Flutter and not a React web frontend?](#why-flutter-and-not-a-react-web-frontend)
    - [Why Whisper and not a cloud API?](#why-whisper-and-not-a-cloud-api)
    - [Why n8n for automation?](#why-n8n-for-automation)
    - [Why separate the Flask bridge from the Whisper server?](#why-separate-the-flask-bridge-from-the-whisper-server)
    - [Why an Arduino Uno and not a Raspberry Pi?](#why-an-arduino-uno-and-not-a-raspberry-pi)
    - [Why the Whisper `small` model?](#why-the-whisper-small-model)
  - [Known Limitations and Constraints](#known-limitations-and-constraints)
    - [Total latency](#total-latency)
    - [No real-time recognition](#no-real-time-recognition)
    - [Sensitivity to background noise](#sensitivity-to-background-noise)
    - [Dependency on Ollama if using a local LLM](#dependency-on-ollama-if-using-a-local-llm)
    - [Electrical safety](#electrical-safety)
    - [Disk space](#disk-space)
  - [Possible Improvements](#possible-improvements)
    - [Short term](#short-term)
    - [Medium term](#medium-term)
    - [Long term](#long-term)
  - [Setup Checklist](#setup-checklist)
    - [Preparation](#preparation)
    - [Software installation](#software-installation)
    - [Wiring](#wiring)
    - [Progressive testing](#progressive-testing)
    - [Production deployment](#production-deployment)

---

## Overview

The goal is to build a system that allows controlling lights in specific rooms using natural speech. The user speaks into a microphone, the command is transcribed, interpreted by a language model, and the corresponding action is executed on an Arduino that drives a physical relay module.

**Example usage:**

- The user says: _"turn on the light in Paul's bedroom"_
- The system identifies: action = turn on, room = Paul's bedroom
- The Arduino activates the relay corresponding to that room

**Key features:**

- 100% local — no voice data sent to any external service
- Natural language — no fixed keywords to memorize
- Extensible — rooms and actions can be added without rewriting everything
- Low hardware cost — an Arduino Uno and relay modules are sufficient

---

## Global Architecture

The system is made up of five distinct layers that communicate sequentially:

```text
[Microphone] → [Flutter App] → [Python / Whisper] → [n8n] → [LLM] → [Flask Bridge] → [Arduino] → [Light]
```

Each layer has a single, clearly defined responsibility. No component does more than one thing at a time, which makes debugging and future changes much easier.

---

## System Components

### 1. Flutter Application

**Role:** User interface. Entry point of the chain. This is where the user interacts with the system.

**Why Flutter instead of a web frontend?**
Modern browsers require microphone access to be served over HTTPS or from `localhost`. This complicates deployment on a local home network. A compiled Flutter application (Linux Desktop or Android) accesses microphone permissions directly through the operating system without this constraint, which is far better suited to a local project.

**Responsibilities:**

- Display a button to start and stop audio recording
- Access the microphone via system permissions (no HTTPS dependency)
- Capture audio and encode it in WAV or PCM format
- Send the audio file to the Python server via an HTTP POST request
- Display the returned transcription and system response (success / error)
- Visually indicate the system state (listening, processing, command executed)

**Technologies:**

- Flutter (Dart framework — Google)
- `record` or `flutter_sound` package for audio capture
- `http` or `dio` package for HTTP requests to the Python server

**Possible target platforms:**

| Platform          | Advantages                                                    | Disadvantages                                       |
| ----------------- | ------------------------------------------------------------- | --------------------------------------------------- |
| **Linux Desktop** | Runs directly on the server PC, no mobile installation needed | Less natural to use                                 |
| **Android**       | Convenient, phone always within reach                         | Requires an Android phone on the same Wi-Fi network |
| iOS               | Works with iPhone                                             | Requires a Mac to compile                           |

**Recommendation:** Build for Android if you have a smartphone handy, or Linux Desktop if you prefer to keep everything on the PC.

**What this component does NOT do:**

- It does not transcribe audio itself
- It makes no decision about which action to perform
- It does not communicate directly with n8n or the Arduino

**Key points:**

- On Android, microphone permission must be granted on first launch
- On Linux Desktop, Flutter requires the Flutter SDK and GTK dependencies to be installed
- Recording duration should be limited to avoid overly large audio files (recommended: 10 seconds maximum)
- The app must know the local IP address of the PC running the Python server (e.g. `192.168.88.20:8000`)
- A clear visual indicator is important so the user knows when to speak

---

### 2. Python Server — Whisper

**Role:** Audio-to-text transcription. This is the core of the voice processing pipeline.

**Responsibilities:**

- Receive the audio file from the Flutter app
- Load the Whisper model into memory when the server starts
- Transcribe the audio into text
- Return the transcribed text to the app and/or forward it to n8n

**Technologies:**

- Python 3.10+
- `openai-whisper` (local model, no external API calls)
- `FastAPI` (lightweight and fast web server)
- `ffmpeg` (audio processing, required by Whisper)

**Recommended model for this hardware:**

| Model     | RAM usage   | Quality   | Speed (Ryzen 5 CPU) |
| --------- | ----------- | --------- | ------------------- |
| tiny      | ~500 MB     | Average   | ~0.5 sec            |
| base      | ~700 MB     | Decent    | ~1 sec              |
| **small** | **~1.5 GB** | **Good**  | **~2-3 sec**        |
| medium    | ~4.5 GB     | Very good | ~8-12 sec           |

The `small` model is the best trade-off for this project given the available hardware (Ryzen 5 PRO 5650U, 11 GB RAM, integrated AMD GPU without CUDA support).

**How it works internally:**

1. The server starts and loads the Whisper `small` model into RAM (a one-time operation, taking ~5 seconds)
2. For each request, it receives the audio file, passes it to Whisper, and returns the text
3. The language is forced to French to improve accuracy and avoid English transcriptions

**What this component does NOT do:**

- It does not understand the meaning of the command
- It has no knowledge of what a "bedroom" or a "light" is
- It returns raw text with no interpretation

**Key points:**

- The model is downloaded only once (~460 MB for `small`)
- The server must be restarted if the model is changed
- Disk space is currently at 87% — free up space before installation

---

### 3. n8n — Automation and AI

**Role:** The brain of the system. Receives the text, understands the intent, decides the action.

**Responsibilities:**

- Expose an HTTP webhook that receives the transcribed text
- Call a language model (LLM) with the text and a well-defined system prompt
- Extract from the LLM response: the target room, the action to perform (on / off), and the corresponding relay
- Call the Flask bridge with this information formatted as JSON
- Handle errors (incomprehensible text, unrecognized room, etc.)

**Technologies:**

- n8n (no-code / low-code automation tool, self-hosted)
- LLM of your choice (see dedicated section below)

**LLM options:**

| Option              | Hosting | Cost         | Quality    | Latency  |
| ------------------- | ------- | ------------ | ---------- | -------- |
| Ollama + llama3 3B  | Local   | Free         | Sufficient | ~1-2 sec |
| Ollama + mistral 7B | Local   | Free         | Good       | ~3-5 sec |
| GPT-4o mini (API)   | Cloud   | ~$0.0001/req | Excellent  | ~1 sec   |
| Claude Haiku (API)  | Cloud   | ~$0.0001/req | Excellent  | ~1 sec   |

**Recommendation:** Start with Ollama + llama3 3B to stay 100% local and free. Switch to a cloud API if interpretation quality is insufficient.

**System prompt used by the LLM:**
The LLM must receive a prompt explaining:

- The available rooms in the house and their identifiers
- The expected response format (strict JSON)
- The possible actions (on, off, no action)
- How to handle ambiguous or unrecognized commands

**Expected LLM output format:**

```JSON
{
  "room": "pauls_bedroom",
  "action": "on",
  "relay_id": 2,
  "confidence": "high"
}
```

**What this component does NOT do:**

- It does not transcribe audio
- It does not communicate directly with the Arduino
- It does not store history (each command is processed independently)

**Key points:**

- n8n must be configured with a dedicated workflow
- The webhook must be reachable from the Python server
- The list of rooms and their relay ID mapping must be clearly defined from the start

---

### 4. Flask Bridge — Serial Communication

**Role:** Gateway between the HTTP world (network) and the serial world (USB/Arduino).

**Responsibilities:**

- Expose an HTTP endpoint that receives JSON commands from n8n
- Validate that the received command is correct (known room, valid action)
- Open a USB serial connection with the Arduino
- Send the formatted command over the serial port
- Return a confirmation to n8n

**Technologies:**

- Python 3.10+
- `Flask` or `FastAPI`
- `pyserial` (USB serial communication)

**Format of the received command:**

```JSON
{
  "relay_id": 2,
  "action": "on"
}
```

**Format sent to the Arduino over serial:**
A simple, robust string, for example: `R2:ON` or `R2:OFF`

**What this component does NOT do:**

- It makes no decision about which light to turn on
- It does not understand natural language
- It does not transcribe audio

**Key points:**

- The Arduino serial port must be correctly identified (usually `/dev/ttyUSB0` or `/dev/ttyACM0` on Linux)
- The Linux user must be in the `dialout` group to access the serial port without `sudo`
- The serial connection should either be properly opened and closed for each command, or kept permanently open (the latter is more reliable)

---

### 5. Arduino Uno — Physical Control

**Role:** Physical execution of commands. The last link in the chain.

**Responsibilities:**

- Listen for commands arriving on the USB serial port
- Parse the received command (e.g. `R2:ON`)
- Activate or deactivate the corresponding relay
- Handle multiple relays simultaneously (one per room / light)

**Technologies:**

- Arduino Uno (ATmega328P microcontroller)
- Relay module (1, 2, 4, or 8 channels depending on the number of lights)
- Arduino language (C++)

**Relay module wiring:**

- The relay module connects to the Arduino's digital pins
- Each relay channel controls one light
- The relay is wired in series between the power supply and the light (caution: high voltage)

**Room / relay mapping:**

| Room           | Relay ID | Arduino Pin |
| -------------- | -------- | ----------- |
| Living room    | 1        | D2          |
| Paul's bedroom | 2        | D3          |
| Kitchen        | 3        | D4          |
| Main bedroom   | 4        | D5          |

(to be adjusted based on the actual rooms)\_

**What this component does NOT do:**

- It understands no natural language
- It does not communicate with the internet
- It makes no decisions — it only executes

**Key points:**

- Relay modules often work with inverted logic (LOW = activated, HIGH = deactivated) — check your specific module
- High voltage (220V) is dangerous: properly insulate all wires and use a relay module rated for domestic use
- The Arduino must remain powered at all times via USB or a dedicated power supply

---

## Complete Data Flow

Here is the full journey of a command, step by step:

**Step 1 — Audio capture**
The user taps the record button in the Flutter app. The microphone activates. The user speaks.

**Step 2 — Audio upload**
When the user stops recording, the app sends the audio file to the Python server via an HTTP POST request to `/transcribe`.

**Step 3 — Transcription**
The Python server receives the file, passes it to Whisper, and returns the transcribed text (e.g. `"turn on the light in Paul's bedroom"`).

**Step 4 — Forwarding to n8n**
The transcribed text is sent to the n8n webhook via an HTTP POST request.

**Step 5 — LLM interpretation**
n8n sends the text to the LLM with a structured prompt. The LLM returns a JSON object with the room, the action, and the relay ID.

**Step 6 — Forwarding to the bridge**
n8n sends the JSON to the Flask bridge via an HTTP POST request to `/command`.

**Step 7 — Serial communication**
The Flask bridge sends the command `R2:ON` to the Arduino over the USB serial port.

**Step 8 — Physical action**
The Arduino receives the command, activates relay 2, and the light in Paul's bedroom turns on.

**Estimated total duration:** 3 to 6 seconds depending on the Whisper model and LLM used.

---

## Hardware Configuration

### PC (local server)

| Component | Detail                                                  |
| --------- | ------------------------------------------------------- |
| Model     | HP EliteBook 845 G8                                     |
| OS        | Debian GNU/Linux 13 (trixie)                            |
| CPU       | AMD Ryzen 5 PRO 5650U — 6 cores / 12 threads @ 4.29 GHz |
| RAM       | 11 GB                                                   |
| GPU       | AMD Radeon Vega (integrated) — no CUDA support          |
| Disk      | 221 GB (87% used — free up space before installation)   |

### Required electronic hardware

| Component              | Quantity | Estimated cost | Role                    |
| ---------------------- | -------- | -------------- | ----------------------- |
| Arduino Uno            | 1        | ~€15           | Main controller         |
| 4-channel relay module | 1        | ~€5            | Light switching         |
| USB A/B cable          | 1        | ~€3            | PC ↔ Arduino connection |
| Dupont cables          | ~10      | ~€2            | Relay ↔ Arduino wiring  |
| Junction box           | per room | ~€5            | Electrical integration  |

**Estimated hardware total:** €25 to €40 depending on quantities

---

## Software Configuration

### System dependencies (Debian)

- Python 3.10 or higher
- ffmpeg (audio processing)
- pip (Python package manager)
- n8n (self-hosted via npm or Docker)
- Ollama (if local LLM is desired)
- Flutter SDK (to compile the application)

### Python dependencies

- `openai-whisper` — audio transcription
- `fastapi` — web server for Whisper
- `flask` — serial bridge
- `pyserial` — USB/serial communication with Arduino
- `uvicorn` — ASGI server for FastAPI

### Flutter dependencies (Dart packages)

- `record` or `flutter_sound` — microphone audio capture
- `http` or `dio` — sending the audio file to the Python server
- `permission_handler` — microphone permission management (Android/Linux)
- `path_provider` — file system access for the temporary audio file

### Network ports used

| Service                  | Port  |
| ------------------------ | ----- |
| Whisper server (FastAPI) | 8000  |
| Flask bridge             | 5000  |
| n8n                      | 5678  |
| Ollama (if local)        | 11434 |

---

## Technical Choices and Rationale

### Why Flutter and not a React web frontend?

Modern browsers require microphone access to be served over HTTPS or from `localhost`. Configuring an HTTPS certificate on a local home network is unnecessary complexity. Flutter compiles a real native application (Linux Desktop or Android) that accesses operating system permissions directly, with no network constraints. Additionally, a Flutter app can be used from a smartphone on the local Wi-Fi network, which is more convenient than opening a browser on the server PC.

### Why Whisper and not a cloud API?

Running Whisper locally guarantees that voice data never leaves the PC. For a personal project that could capture conversations, privacy matters. The `small` model offers sufficient quality for French with acceptable latency on the Ryzen 5 PRO 5650U.

### Why n8n for automation?

n8n allows visually building the processing pipeline (webhook → LLM → action), making changes easy without touching code. It can also be extended to integrate other services (home automation, notifications, etc.). It is a robust, self-hostable tool.

### Why separate the Flask bridge from the Whisper server?

These two components have very different responsibilities: one handles audio transcription (CPU-intensive), the other handles serial communication (simple I/O). Keeping them separate allows restarting each independently, testing them individually, and prevents an error in one from affecting the other.

### Why an Arduino Uno and not a Raspberry Pi?

The Arduino is simpler, more reliable, and sufficient for driving relays. It requires no OS, cannot "crash", and consumes very little power. All decision logic lives on the PC, not on the Arduino, so its simplicity is an advantage.

### Why the Whisper `small` model?

- `tiny` and `base`: too many errors on complex sentences
- `small`: good trade-off, ~460 MB, ~2-3 seconds latency on CPU
- `medium`: too slow on CPU (8-12 seconds), latency too long for a smooth experience
- `large`: impossible to use without a dedicated GPU in any reasonable time

---

## Known Limitations and Constraints

### Total latency

The system is not instant. The delay between the end of a voice command and the physical execution is approximately 3 to 6 seconds. This delay is mainly due to Whisper (2-3 sec) and the LLM (1-2 sec). This is acceptable for personal use but not for commercial deployment.

### No real-time recognition

The system works in "push-to-talk" mode (the user must press a button). It does not listen continuously. This avoids false triggers but requires manual interaction.

### Sensitivity to background noise

Whisper may struggle to transcribe correctly if audio quality is poor (background noise, distant microphone, reverberant environment). A good directional microphone significantly improves results.

### Dependency on Ollama if using a local LLM

If Ollama is used, it must run continuously and consumes RAM (3 to 5 GB depending on the model). With 11 GB of total RAM, this is worth monitoring if other applications are open.

### Electrical safety

Relay modules switch 220V mains current. Incorrect wiring can be dangerous. It is strongly recommended to have the installation checked by someone with knowledge of domestic electrical wiring before putting it into service.

### Disk space

The disk is currently at 87% capacity. The project requires approximately 1 GB of additional space (Whisper model + dependencies). Space must be freed before starting.

---

## Possible Improvements

### Short term

- Add a voice response (text-to-speech) to confirm the executed command
- Add a web interface to display the current state of each light
- Support combined commands ("turn on the living room and the kitchen")

### Medium term

- Replace the button with a wake word ("Hey house") using a model like Porcupine or openWakeWord
- Add other types of devices (fans, blinds, smart plugs)
- Store command history in a local database

### Long term

- Integrate with Home Assistant for full home automation
- Add multiple Arduinos to cover more rooms
- Switch to an ESP32 (with built-in Wi-Fi) to remove the USB cable dependency

---

## Setup Checklist

### Preparation

- [ ] Free up disk space (target: below 80% usage)
- [ ] Purchase the Arduino hardware and relay modules
- [ ] Install ffmpeg on Debian (`sudo apt install ffmpeg`)
- [ ] Add the user to the `dialout` group (`sudo usermod -aG dialout $USER`)

### Software installation

- [ ] Install Python 3.10+, pip, and the Python dependencies
- [ ] Download the Whisper `small` model (happens automatically on first run)
- [ ] Install the Flutter SDK on Debian (via snap or manual installation)
- [ ] Install Flutter Linux Desktop dependencies if needed (`sudo apt install libgtk-3-dev libblkid-dev liblzma-dev`)
- [ ] Install n8n (via npm or Docker)
- [ ] Install Ollama and download the llama3 model (if using a local LLM)

### Wiring

- [ ] Connect the relay module to the Arduino according to the planned mapping
- [ ] Identify the Arduino serial port on Debian (`ls /dev/tty*`)
- [ ] Test serial communication before integrating with Flask
- [ ] Wire the lights through the relay module (pay attention to electrical safety)

### Progressive testing

- [ ] Test Whisper alone with a test audio file
- [ ] Test the FastAPI server with Postman or curl
- [ ] Test audio capture from the Flutter app and upload to the server
- [ ] Test the LLM alone with sample phrases
- [ ] Test the Flask bridge and Arduino communication
- [ ] Test the complete end-to-end chain

### Production deployment

- [ ] Configure services to start automatically on boot
- [ ] Test multiple voice commands under real conditions
- [ ] Document the room / relay ID mapping for future reference
