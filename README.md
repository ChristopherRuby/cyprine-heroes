# Les héros de la Cyprine

Application web (FastAPI + React) pour visualiser et administrer des héros, avec authentification et upload d’images.

## 🧭 Aperçu

```
cyprine-heroes/
├── backend/          # API FastAPI + SQLAlchemy + Alembic
├── frontend/         # React (CRA) + TypeScript
└── uploads/          # (optionnel) Dossier d'images si vous le placez à la racine
```

Backend expose: `/api/auth/login`, `/api/heroes` (+ upload d’image). Frontend consomme l’API via `REACT_APP_API_URL`.

## 🧱 Prérequis

- Python 3.11+
- Node.js 16+ et npm
- PostgreSQL 13+

## ⚙️ Configuration des environnements

Des exemples sont fournis:
- `backend/.env.example` ➜ copiez-le en `backend/.env` et adaptez les valeurs
- `frontend/.env.example` ➜ copiez-le en `frontend/.env`

Variables côté backend (Pydantic Settings):
- `DATABASE_URL` (ex: `postgresql://user:password@localhost:5432/cyprine_heroes`)
- `SECRET_KEY` (clé aléatoire pour signer les JWT)
- `ALGORITHM` (par défaut `HS256`)
- `ACCESS_TOKEN_EXPIRE_MINUTES` (par défaut `30`)
- `ADMIN_PASSWORD` (mot de passe admin pour le login)
- `UPLOAD_DIR` (ex: `./uploads`)

Variables côté frontend:
- `REACT_APP_API_URL` (par défaut `http://localhost:8000/api`)

💡 CORS: l’API autorise `http://localhost:3000` dans `app.main`. Modifiez si nécessaire.

## 🚀 Installation & lancement

### 1) Backend (FastAPI)

Depuis la racine du projet:

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Créez le fichier d'env à partir de l'exemple
cp .env.example .env

# Créez le dossier d’uploads AVANT de démarrer (pour monter /uploads)
mkdir -p uploads

# Appliquez les migrations
alembic upgrade head

# Démarrez l’API (http://localhost:8000)
uvicorn app.main:app --reload
```

Notes:
- Alembic lit `DATABASE_URL` via `backend/.env` (voir `alembic/env.py`).
- Le montage `/uploads` n’est activé qu’au démarrage si le dossier existe; d’où le `mkdir -p uploads` avant `uvicorn`.

### 2) Frontend (React, Vite)

Dans un second terminal:

```bash
cd frontend
cp .env.example .env  # facultatif, si vous voulez surcharger l'URL API (VITE_API_URL)
npm install
npm run dev
```

L’application sera disponible sur http://localhost:5173.

## 🗄️ Base de données

Exemple rapide avec psql:

```bash
createdb cyprine_heroes
# ou
psql -c 'CREATE DATABASE cyprine_heroes;'
```

Assurez-vous que `DATABASE_URL` pointe vers cette base.

## 🔐 Authentification

- Endpoint: `POST /api/auth/login` avec `{ "password": "<ADMIN_PASSWORD>" }`
- Réponse: `{ access_token, token_type }`
- Le token (Bearer) est requis pour créer/modifier/supprimer un héros et uploader une image.

## 🖼️ Upload d’images

- Endpoint: `POST /api/heroes/upload-image/{hero_id}` (multipart/form-data, champ `file`)
- Types acceptés: jpeg, png, gif, webp
- Les fichiers sont enregistrés dans `UPLOAD_DIR` (par défaut `./uploads`).

## 🔌 Endpoints principaux

- `GET /api/heroes` — liste des héros
- `GET /api/heroes/{id}` — détail
- `POST /api/heroes` — création (auth requise, nickname unique)
- `PUT /api/heroes/{id}` — mise à jour (auth requise)
- `DELETE /api/heroes/{id}` — suppression (auth requise)
- `POST /api/heroes/upload-image/{id}` — upload d’image (auth requise)

## 🧪 Dépannage

- Les fichiers sous `/uploads` ne sont pas servis: créez le dossier avant de démarrer l’API (`mkdir -p backend/uploads`) ou définissez `UPLOAD_DIR` vers un dossier existant.
- Erreur de connexion PostgreSQL: vérifiez `DATABASE_URL` et que la DB existe et est accessible.
- CORS en développement: si votre frontend n’est pas sur `http://localhost:5173`, mettez à jour `allow_origins` dans `backend/app/main.py`.
- Variables d’env côté frontend: avec Vite, utilisez `VITE_API_URL` et accédez-y via `import.meta.env.VITE_API_URL`.

## ✅ État des fonctionnalités

- ✅ Backend FastAPI avec SQLAlchemy, Alembic, JWT
- ✅ Endpoints CRUD Héros + upload d’images
- ✅ Frontend React/TS avec appels API
- ⏳ UI avancée (drag & drop, sélection visuelle) à finaliser selon besoins