# Configuration des Environnements

## 🏠 Développement Local

### Frontend
Copiez le fichier d'environnement local :
```bash
cp frontend/.env.local frontend/.env
```

### Backend
Copiez et adaptez le fichier d'environnement local :
```bash
cp backend/.env.local backend/.env
# Puis éditez backend/.env avec vos valeurs locales
```

Variables à configurer :
- `DATABASE_URL` : URL de votre base PostgreSQL locale
- `SECRET_KEY` : Clé secrète pour les tokens JWT
- `ADMIN_PASSWORD` : Mot de passe admin
- `CORS_ORIGINS` : URLs autorisées (ex: http://localhost:5173)

## 🚀 Déploiement Production

### Automatique via Terraform
Le déploiement sur EC2 configure automatiquement les variables :
- **HTTP** : Utilise l'IP publique initialement
- **HTTPS** : Bascule vers le domaine une fois SSL configuré

### Configuration des variables
Les variables sont définies dans :
- `deploy/terraform/environments/prod/terraform.tfvars`

## 📁 Structure des fichiers d'environnement

```
frontend/
├── .env.local      # Développement local
├── .env.production # Production (auto-généré)
└── .env           # Fichier actif (copié depuis l'un des précédents)

backend/
├── .env.local      # Développement local
├── .env.production # Production (auto-généré)
└── .env           # Fichier actif (copié depuis l'un des précédents)
```

## 🔧 Commandes de déploiement

### Local
```bash
# Frontend
cd frontend
npm install
npm run dev

# Backend
cd backend
python -m venv venv
source venv/bin/activate  # Linux/Mac
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Production
```bash
cd deploy/terraform/environments/prod
terraform apply
```

## 🌐 URLs selon l'environnement

- **Local** : http://localhost:5173 → http://localhost:8000/api
- **Staging** : http://13.37.51.212 → http://13.37.51.212/api  
- **Production** : https://heroes.cyprinade.com → https://heroes.cyprinade.com/api