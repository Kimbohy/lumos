# Lumos

Système de Contrôle Vocal des Lumières

> Projet personnel — Contrôle de lumières par commande vocale via reconnaissance speech-to-text, traitement IA, et Arduino

---

## Table des matières

- [Lumos](#lumos)
  - [Table des matières](#table-des-matières)
  - [Vue d'ensemble](#vue-densemble)
  - [Architecture globale](#architecture-globale)
  - [Composants du système](#composants-du-système)
    - [1. Application Flutter](#1-application-flutter)
    - [2. Serveur Python — Whisper](#2-serveur-python--whisper)
    - [3. n8n — Automatisation et IA](#3-n8n--automatisation-et-ia)
    - [4. Bridge Flask — Communication série](#4-bridge-flask--communication-série)
    - [5. Arduino Uno — Contrôle physique](#5-arduino-uno--contrôle-physique)
  - [Flux de données complet](#flux-de-données-complet)
  - [Configuration matérielle](#configuration-matérielle)
    - [PC (serveur local)](#pc-serveur-local)
    - [Matériel électronique requis](#matériel-électronique-requis)
  - [Configuration logicielle](#configuration-logicielle)
    - [Dépendances système (Debian)](#dépendances-système-debian)
    - [Dépendances Python](#dépendances-python)
    - [Dépendances Flutter (packages Dart)](#dépendances-flutter-packages-dart)
    - [Ports réseau utilisés](#ports-réseau-utilisés)
  - [Choix techniques et justifications](#choix-techniques-et-justifications)
    - [Pourquoi Flutter et pas un frontend web React ?](#pourquoi-flutter-et-pas-un-frontend-web-react-)
    - [Pourquoi Whisper et pas une API cloud ?](#pourquoi-whisper-et-pas-une-api-cloud-)
    - [Pourquoi n8n pour l'automatisation ?](#pourquoi-n8n-pour-lautomatisation-)
    - [Pourquoi séparer le bridge Flask du serveur Whisper ?](#pourquoi-séparer-le-bridge-flask-du-serveur-whisper-)
    - [Pourquoi un Arduino Uno et pas un Raspberry Pi ?](#pourquoi-un-arduino-uno-et-pas-un-raspberry-pi-)
    - [Pourquoi le modèle `small` de Whisper ?](#pourquoi-le-modèle-small-de-whisper-)
  - [Limitations connues et contraintes](#limitations-connues-et-contraintes)
    - [Latence totale](#latence-totale)
    - [Pas de reconnaissance en temps réel](#pas-de-reconnaissance-en-temps-réel)
    - [Sensibilité au bruit ambiant](#sensibilité-au-bruit-ambiant)
    - [Dépendance à Ollama si LLM local](#dépendance-à-ollama-si-llm-local)
    - [Gestion de l'électricité](#gestion-de-lélectricité)
    - [Espace disque](#espace-disque)
  - [Évolutions possibles](#évolutions-possibles)
    - [Court terme](#court-terme)
    - [Moyen terme](#moyen-terme)
    - [Long terme](#long-terme)
  - [Checklist de mise en place](#checklist-de-mise-en-place)
    - [Préparation](#préparation)
    - [Installation logicielle](#installation-logicielle)
    - [Câblage](#câblage)
    - [Tests progressifs](#tests-progressifs)
    - [Mise en production](#mise-en-production)

---

## Vue d'ensemble

L'objectif est de créer un système permettant de contrôler des lumières dans des pièces précises à l'aide de la voix, en langage naturel. L'utilisateur parle dans un micro, la commande est transcrite, interprétée par un modèle de langage, et l'action correspondante est exécutée sur un Arduino qui pilote un module relay physique.

**Exemple d'usage :**

- L'utilisateur dit : _"allume la lumière dans la chambre de Paul"_
- Le système identifie : action = allumer, pièce = chambre Paul
- L'Arduino active le relay correspondant à cette pièce

**Caractéristiques principales :**

- 100% local — aucune donnée vocale envoyée à un service externe
- Langage naturel — pas de mots-clés fixes à mémoriser
- Extensible — on peut ajouter des pièces ou des actions sans tout reécrire
- Bas coût matériel — un Arduino Uno et des modules relay suffisent

---

## Architecture globale

Le système est composé de cinq couches distinctes qui communiquent entre elles de façon séquentielle :

```text
[Micro] → [App Flutter] → [Python / Whisper] → [n8n] → [LLM] → [Flask Bridge] → [Arduino] → [Lumière]
```

Chaque couche a une responsabilité unique et bien délimitée. Aucun composant ne fait plus d'une chose à la fois, ce qui facilite le débogage et les évolutions futures.

---

## Composants du système

### 1. Application Flutter

**Rôle :** Interface utilisateur. Point d'entrée de la chaîne. C'est ici que l'utilisateur interagit avec le système.

**Pourquoi Flutter plutôt qu'un frontend web ?**
Les navigateurs modernes imposent que l'accès au microphone soit fait depuis une page servie en HTTPS ou depuis `localhost`. Cela complique le déploiement dans un réseau local domestique. Une application Flutter compilée (desktop Linux ou Android) accède directement aux permissions du système d'exploitation sans cette contrainte, ce qui est bien plus adapté à un projet local.

**Responsabilités :**

- Afficher un bouton permettant de démarrer et arrêter l'enregistrement audio
- Accéder au microphone via les permissions système (pas de dépendance HTTPS)
- Capturer le son et encoder l'audio en format WAV ou PCM
- Envoyer le fichier audio au serveur Python via une requête HTTP POST
- Afficher la transcription retournée et la réponse du système (succès / erreur)
- Indiquer visuellement l'état du système (en écoute, en traitement, commande exécutée)

**Technologies :**

- Flutter (framework Dart — Google)
- Package `record` ou `flutter_sound` pour la capture audio
- Package `http` ou `dio` pour les requêtes HTTP vers le serveur Python

**Plateformes cibles possibles :**

| Plateforme        | Avantages                                                       | Inconvénients                                           |
| ----------------- | --------------------------------------------------------------- | ------------------------------------------------------- |
| **Linux Desktop** | Tourne directement sur le PC serveur, pas d'installation mobile | Interface moins naturelle à utiliser                    |
| **Android**       | Pratique, téléphone toujours à portée de main                   | Nécessite un téléphone Android sur le même réseau Wi-Fi |
| iOS               | Compatible iPhone                                               | Nécessite un Mac pour compiler                          |

**Recommandation :** Compiler pour Android si tu as un smartphone sous la main, ou Linux Desktop si tu préfères tout garder sur le PC.

**Ce que ce composant ne fait pas :**

- Il ne fait aucune transcription lui-même
- Il ne prend aucune décision sur l'action à effectuer
- Il ne communique pas directement avec n8n ou l'Arduino

**Points d'attention :**

- Sur Android, il faut accorder la permission microphone au premier lancement
- Sur Linux Desktop, Flutter nécessite l'installation du SDK Flutter et des dépendances GTK
- La durée d'enregistrement doit être limitée pour éviter des fichiers audio trop lourds (recommandation : 10 secondes maximum)
- L'application doit connaître l'adresse IP locale du PC qui fait tourner le serveur Python (ex: `192.168.88.20:8000`)
- Un indicateur visuel clair est important pour que l'utilisateur sache quand parler

---

### 2. Serveur Python — Whisper

**Rôle :** Transcription audio vers texte. C'est le cœur du traitement vocal.

**Responsabilités :**

- Recevoir le fichier audio depuis le frontend
- Charger le modèle Whisper en mémoire au démarrage du serveur
- Transcrire l'audio en texte en français
- Retourner le texte transcrit au frontend et/ou le transmettre à n8n

**Technologies :**

- Python 3.10+
- `openai-whisper` (modèle local, aucun appel API externe)
- `FastAPI` (serveur web léger et rapide)
- `ffmpeg` (traitement audio, requis par Whisper)

**Modèle recommandé pour ce matériel :**

| Modèle    | RAM utilisée | Qualité français | Vitesse (CPU Ryzen 5) |
| --------- | ------------ | ---------------- | --------------------- |
| tiny      | ~500 MB      | Moyenne          | ~0.5 sec              |
| base      | ~700 MB      | Correcte         | ~1 sec                |
| **small** | **~1.5 GB**  | **Bonne**        | **~2-3 sec**          |
| medium    | ~4.5 GB      | Très bonne       | ~8-12 sec             |

Le modèle `small` est le meilleur compromis pour ce projet sur le matériel disponible (Ryzen 5 PRO 5650U, 11 GB RAM, GPU intégré AMD sans support CUDA).

**Fonctionnement interne :**

1. Le serveur démarre et charge le modèle Whisper `small` en RAM (opération longue, ~5 secondes, faite une seule fois)
2. Pour chaque requête, il reçoit le fichier audio, le passe à Whisper, et retourne le texte
3. La langue est forcée en français pour améliorer la précision et éviter des transcriptions en anglais

**Ce que ce composant ne fait pas :**

- Il ne comprend pas le sens de la commande
- Il ne sait pas ce qu'est une "chambre" ou une "lumière"
- Il envoie le texte brut sans interprétation

**Points d'attention :**

- Le modèle doit être téléchargé une seule fois (~460 MB pour `small`)
- Le serveur doit être relancé si le modèle est changé
- L'espace disque est actuellement à 87% d'occupation — libérer de la place avant installation

---

### 3. n8n — Automatisation et IA

**Rôle :** Cerveau du système. Reçoit le texte, comprend l'intention, décide l'action.

**Responsabilités :**

- Exposer un webhook HTTP qui reçoit le texte transcrit
- Appeler un modèle de langage (LLM) avec le texte et un prompt système bien défini
- Extraire de la réponse du LLM : la pièce concernée, l'action à effectuer (allumer / éteindre), et le relay correspondant
- Appeler le bridge Flask avec ces informations formatées en JSON
- Gérer les erreurs (texte incompréhensible, pièce non reconnue, etc.)

**Technologies :**

- n8n (outil d'automatisation no-code / low-code, auto-hébergé)
- LLM au choix (voir section dédiée ci-dessous)

**Choix du LLM :**

| Option              | Hébergement | Coût         | Qualité    | Latence  |
| ------------------- | ----------- | ------------ | ---------- | -------- |
| Ollama + llama3 3B  | Local       | Gratuit      | Suffisante | ~1-2 sec |
| Ollama + mistral 7B | Local       | Gratuit      | Bonne      | ~3-5 sec |
| GPT-4o mini (API)   | Cloud       | ~$0.0001/req | Excellente | ~1 sec   |
| Claude Haiku (API)  | Cloud       | ~$0.0001/req | Excellente | ~1 sec   |

**Recommandation :** Commencer avec Ollama + llama3 3B pour rester 100% local et gratuit. Passer à une API cloud si la qualité d'interprétation est insuffisante.

**Prompt système utilisé par le LLM :**
Le LLM doit recevoir un prompt qui lui explique :

- Les pièces disponibles dans la maison et leurs identifiants
- Le format de réponse attendu (JSON strict)
- Les actions possibles (allumer, éteindre, pas d'action)
- Comment gérer les commandes ambiguës ou non reconnues

**Format de sortie attendu du LLM :**

```JSON
{
  "room": "chambre_paul",
  "action": "on",
  "relay_id": 2,
  "confidence": "high"
}
```

**Ce que ce composant ne fait pas :**

- Il ne transcrit pas l'audio
- Il ne communique pas directement avec l'Arduino
- Il ne stocke pas d'historique (chaque commande est traitée indépendamment)

**Points d'attention :**

- n8n doit être configuré avec un workflow dédié
- Le webhook doit être accessible depuis le serveur Python
- Il faut définir clairement la liste des pièces et leur mapping vers les relay IDs dès le départ

---

### 4. Bridge Flask — Communication série

**Rôle :** Passerelle entre le monde HTTP (réseau) et le monde série (USB/Arduino).

**Responsabilités :**

- Exposer un endpoint HTTP qui reçoit les commandes JSON de n8n
- Valider que la commande reçue est correcte (pièce connue, action valide)
- Ouvrir une connexion série USB avec l'Arduino
- Envoyer la commande formatée via le port série
- Retourner une confirmation à n8n

**Technologies :**

- Python 3.10+
- `Flask` ou `FastAPI`
- `pyserial` (communication série USB)

**Format de la commande reçue :**

```JSON
{
  "relay_id": 2,
  "action": "on"
}
```

**Format envoyé à l'Arduino via le port série :**
Une chaîne simple et robuste, par exemple : `R2:ON` ou `R2:OFF`

**Ce que ce composant ne fait pas :**

- Il ne prend aucune décision sur quelle lumière allumer
- Il ne comprend pas le langage naturel
- Il ne transcrit pas l'audio

**Points d'attention :**

- Le port série de l'Arduino doit être identifié correctement (souvent `/dev/ttyUSB0` ou `/dev/ttyACM0` sur Linux)
- L'utilisateur Linux doit être dans le groupe `dialout` pour accéder au port série sans `sudo`
- La connexion série doit être ouverte et fermée proprement à chaque commande, ou maintenue ouverte en permanence (second choix plus fiable)

---

### 5. Arduino Uno — Contrôle physique

**Rôle :** Exécution physique des commandes. Dernier maillon de la chaîne.

**Responsabilités :**

- Écouter les commandes arrivant sur le port série USB
- Parser la commande reçue (ex: `R2:ON`)
- Activer ou désactiver le relay correspondant
- Gérer plusieurs relays simultanément (un par pièce / lumière)

**Technologies :**

- Arduino Uno (microcontrôleur ATmega328P)
- Module relay (1, 2, 4 ou 8 canaux selon le nombre de lumières)
- Langage Arduino (C++)

**Câblage du module relay :**

- Le module relay se branche sur les pins numériques de l'Arduino
- Chaque canal du relay contrôle une lumière
- Le relay s'intercale entre l'alimentation électrique et la lumière (attention à la haute tension)

**Mapping pièces / relays :**

| Pièce              | Relay ID | Pin Arduino |
| ------------------ | -------- | ----------- |
| Salon              | 1        | D2          |
| Chambre Paul       | 2        | D3          |
| Cuisine            | 3        | D4          |
| Chambre principale | 4        | D5          |

(à adapter selon les pièces réelles)\_

**Ce que ce composant ne fait pas :**

- Il ne comprend aucun langage naturel
- Il ne communique pas avec Internet
- Il ne prend aucune décision : il exécute uniquement

**Points d'attention :**

- Les modules relay fonctionnent souvent en logique inversée (LOW = activé, HIGH = désactivé) — à vérifier selon le module
- La haute tension (220V) est dangereuse : bien isoler tous les câbles et utiliser un module relay adapté à l'usage domestique
- L'Arduino doit rester alimenté en permanence via USB ou une alimentation dédiée

---

## Flux de données complet

Voici le parcours complet d'une commande, étape par étape :

**Étape 1 — Capture audio**
L'utilisateur clique sur le bouton d'enregistrement dans le navigateur. Le microphone s'active. L'utilisateur parle.

**Étape 2 — Envoi de l'audio**
Quand l'utilisateur arrête l'enregistrement, le frontend envoie le fichier audio au serveur Python via une requête HTTP POST vers `/transcribe`.

**Étape 3 — Transcription**
Le serveur Python reçoit le fichier, le passe à Whisper, et retourne le texte transcrit (ex: `"allume la lumière dans la chambre de Paul"`).

**Étape 4 — Envoi à n8n**
Le texte transcrit est envoyé au webhook n8n via une requête HTTP POST.

**Étape 5 — Interprétation par le LLM**
n8n envoie le texte au LLM avec un prompt structuré. Le LLM retourne un JSON avec la pièce, l'action, et l'ID du relay.

**Étape 6 — Transmission au bridge**
n8n envoie le JSON au bridge Flask via une requête HTTP POST vers `/command`.

**Étape 7 — Communication série**
Le bridge Flask envoie la commande `R2:ON` à l'Arduino via le port série USB.

**Étape 8 — Action physique**
L'Arduino reçoit la commande, active le relay 2, et la lumière de la chambre de Paul s'allume.

**Durée totale estimée :** 3 à 6 secondes selon le modèle Whisper choisi et le LLM utilisé.

---

## Configuration matérielle

### PC (serveur local)

| Composant | Détail                                                        |
| --------- | ------------------------------------------------------------- |
| Modèle    | HP EliteBook 845 G8                                           |
| OS        | Debian GNU/Linux 13 (trixie)                                  |
| CPU       | AMD Ryzen 5 PRO 5650U — 6 cœurs / 12 threads @ 4.29 GHz       |
| RAM       | 11 GB                                                         |
| GPU       | AMD Radeon Vega (intégré) — pas de support CUDA               |
| Disque    | 221 GB (87% utilisé — libérer de l'espace avant installation) |

### Matériel électronique requis

| Composant             | Quantité  | Coût estimé | Rôle                     |
| --------------------- | --------- | ----------- | ------------------------ |
| Arduino Uno           | 1         | ~15€        | Contrôleur principal     |
| Module relay 4 canaux | 1         | ~5€         | Commutation des lumières |
| Câble USB A/B         | 1         | ~3€         | Connexion PC ↔ Arduino   |
| Câbles Dupont         | ~10       | ~2€         | Câblage relay ↔ Arduino  |
| Boîtier de dérivation | par pièce | ~5€         | Intégration électrique   |

**Total matériel estimé :** 25 à 40€ selon les quantités

---

## Configuration logicielle

### Dépendances système (Debian)

- Python 3.10 ou supérieur
- ffmpeg (traitement audio)
- pip (gestionnaire de paquets Python)
- Node.js 18+ et npm (pour le frontend React)
- n8n (auto-hébergé via npm ou Docker)
- Ollama (si LLM local souhaité)
- Flutter SDK (pour compiler l'application)

### Dépendances Python

- `openai-whisper` — transcription audio
- `fastapi` — serveur web pour Whisper
- `flask` — bridge série
- `pyserial` — communication USB/série avec Arduino
- `uvicorn` — serveur ASGI pour FastAPI

### Dépendances Flutter (packages Dart)

- `record` ou `flutter_sound` — capture audio depuis le microphone
- `http` ou `dio` — envoi du fichier audio au serveur Python
- `permission_handler` — gestion des permissions microphone (Android/Linux)
- `path_provider` — accès au système de fichiers pour le fichier audio temporaire

### Ports réseau utilisés

| Service                   | Port  |
| ------------------------- | ----- |
| Serveur Whisper (FastAPI) | 8000  |
| Bridge Flask              | 5000  |
| n8n                       | 5678  |
| Ollama (si local)         | 11434 |

---

## Choix techniques et justifications

### Pourquoi Flutter et pas un frontend web React ?

Les navigateurs modernes imposent que l'accès au microphone soit fait depuis une page servie en HTTPS ou depuis `localhost`. Dans un réseau domestique local, configurer un certificat HTTPS est une complexité inutile. Flutter compile une vraie application native (Linux Desktop ou Android) qui accède directement aux permissions du système d'exploitation, sans aucune contrainte réseau. De plus, une application Flutter peut être utilisée depuis un smartphone sur le réseau Wi-Fi local, ce qui est plus pratique que d'ouvrir un navigateur sur le PC serveur.

### Pourquoi Whisper et pas une API cloud ?

Whisper en local garantit que les données vocales ne quittent jamais le PC. Pour un projet personnel qui pourrait capter des conversations, la confidentialité est importante. Le modèle `small` offre une qualité suffisante pour le français avec une latence acceptable sur le Ryzen 5 PRO 5650U.

### Pourquoi n8n pour l'automatisation ?

n8n permet de construire visuellement le flux de traitement (webhook → LLM → action), ce qui facilite les modifications sans toucher au code. Il peut aussi être étendu facilement pour intégrer d'autres services (domotique, notifications, etc.). C'est un outil robuste et auto-hébergeable.

### Pourquoi séparer le bridge Flask du serveur Whisper ?

Ces deux composants ont des responsabilités très différentes : l'un fait de la transcription audio (CPU-intensif), l'autre fait de la communication série (I/O simple). Les séparer permet de les redémarrer indépendamment, de les tester séparément, et d'éviter qu'une erreur dans l'un n'affecte l'autre.

### Pourquoi un Arduino Uno et pas un Raspberry Pi ?

L'Arduino est plus simple, plus fiable, et suffisant pour piloter des relays. Il n'a pas besoin d'OS, ne peut pas "planter", et consomme très peu d'énergie. La logique de décision est entièrement sur le PC, pas sur l'Arduino, donc sa simplicité est un avantage.

### Pourquoi le modèle `small` de Whisper ?

- `tiny` et `base` : trop d'erreurs sur les phrases complexes en français
- `small` : bon compromis, ~460 MB, ~2-3 secondes de latence sur CPU
- `medium` : trop lent sur CPU (8-12 secondes), latence trop longue pour une expérience fluide
- `large` : impossible à utiliser sans GPU dédié dans des délais raisonnables

---

## Limitations connues et contraintes

### Latence totale

Le système n'est pas instantané. Le délai entre la fin de la commande vocale et l'exécution physique est d'environ 3 à 6 secondes. Ce délai est principalement dû à Whisper (2-3 sec) et au LLM (1-2 sec). C'est acceptable pour un usage personnel mais pas pour un usage commercial.

### Pas de reconnaissance en temps réel

Le système fonctionne en mode "push-to-talk" (l'utilisateur doit appuyer sur un bouton). Il n'écoute pas en permanence. Cela évite les faux déclenchements mais impose une interaction manuelle.

### Sensibilité au bruit ambiant

Whisper peut avoir du mal à transcrire correctement si la qualité audio est mauvaise (bruit de fond, micro éloigné, environnement réverbérant). Un bon micro directif améliore significativement les résultats.

### Dépendance à Ollama si LLM local

Si Ollama est utilisé, il doit tourner en permanence et consomme de la RAM (3 à 5 GB selon le modèle choisi). Sur 11 GB de RAM totaux, c'est un point à surveiller si d'autres applications sont ouvertes.

### Gestion de l'électricité

Les modules relay commutent du courant 220V. Un câblage incorrect peut être dangereux. Il est fortement recommandé de faire vérifier l'installation par quelqu'un qui s'y connaît en électricité domestique avant mise en service.

### Espace disque

Le disque est actuellement à 87% de capacité. Le projet nécessite ~1 GB supplémentaire (modèle Whisper + dépendances). Il faut libérer de l'espace avant de commencer.

---

## Évolutions possibles

### Court terme

- Ajouter un retour vocal (text-to-speech) pour confirmer la commande exécutée
- Ajouter une interface web pour voir l'état actuel de chaque lumière
- Supporter des commandes combinées ("allume le salon et la cuisine")

### Moyen terme

- Remplacer le bouton par un mot d'activation ("Hey maison") avec un modèle de wake word comme Porcupine ou openWakeWord
- Ajouter d'autres types d'appareils (ventilateurs, stores, prises connectées)
- Enregistrer l'historique des commandes dans une base de données locale

### Long terme

- Intégrer avec Home Assistant pour une domotique complète
- Ajouter plusieurs Arduino pour couvrir plus de pièces
- Passer à un ESP32 (avec WiFi intégré) pour s'affranchir du câble USB

---

## Checklist de mise en place

### Préparation

- [ ] Libérer de l'espace disque (objectif : moins de 80% d'occupation)
- [ ] Acheter le matériel Arduino et les modules relay
- [x] Installer ffmpeg sur Debian (`sudo apt install ffmpeg`)
- [x] Ajouter l'utilisateur au groupe `dialout` (`sudo usermod -aG dialout $USER`)

### Installation logicielle

- [x] Installer Python 3.10+, pip, et les dépendances Python
- [x] Télécharger le modèle Whisper `small` (premier lancement automatique)
- [x] Installer le SDK Flutter sur Debian (via snap ou installation manuelle)
- [x] Installer les dépendances Flutter pour Linux Desktop si nécessaire (`sudo apt install libgtk-3-dev libblkid-dev liblzma-dev`)
- [x] Installer n8n (via npm ou Docker)
- [ ] Installer Ollama et télécharger le modèle llama3 (si LLM local)

### Câblage

- [ ] Relier le module relay à l'Arduino selon le mapping prévu
- [ ] Identifier le port série de l'Arduino sur Debian (`ls /dev/tty*`)
- [ ] Tester la communication série avant d'intégrer avec Flask
- [ ] Câbler les lumières via le module relay (attention à la sécurité électrique)

### Tests progressifs

- [ ] Tester Whisper seul avec un fichier audio de test
- [ ] Tester le serveur FastAPI avec Postman ou curl
- [ ] Tester la capture audio depuis l'app Flutter et l'envoi au serveur
- [ ] Tester le LLM seul avec des phrases types
- [ ] Tester le bridge Flask et la communication Arduino
- [ ] Tester la chaîne complète de bout en bout

### Mise en production

- [ ] Configurer les services pour démarrer automatiquement au boot
- [ ] Tester plusieurs commandes vocales dans les conditions réelles
- [ ] Documenter le mapping pièces / relay IDs pour référence future
