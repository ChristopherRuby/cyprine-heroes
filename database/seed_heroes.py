#!/usr/bin/env python3
"""
Script pour initialiser la base de données avec des héros de test
"""

import os
import sys
import requests
import json

# Configuration API
API_BASE = "http://127.0.0.1:8000/api"
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "cyprine2025")

# Faux héros à créer
HEROES_DATA = [
    {
        "firstname": "Tony",
        "lastname": "Stark",
        "nickname": "Iron Man",
        "description": "Milliardaire philanthrope inventeur de génie avec une armure technologique ultra-perfectionnée",
        "is_villain": False
    },
    {
        "firstname": "Natasha",
        "lastname": "Romanoff", 
        "nickname": "Black Widow",
        "description": "Espionne et assassin de légende, experte en combat rapproché et infiltration",
        "is_villain": False
    },
    {
        "firstname": "Loki",
        "lastname": "Laufeyson",
        "nickname": "God of Mischief", 
        "description": "Dieu nordique du mensonge et des tours, maître des illusions et de la magie",
        "is_villain": True
    },
    {
        "firstname": "Steve",
        "lastname": "Rogers",
        "nickname": "Captain America",
        "description": "Super-soldat patriote avec un bouclier en vibranium et des valeurs inébranlables",
        "is_villain": False
    },
    {
        "firstname": "Bruce",
        "lastname": "Banner",
        "nickname": "The Hulk",
        "description": "Scientifique brillant qui se transforme en géant vert incontrôlable sous la colère",
        "is_villain": False
    }
]

def get_auth_token():
    """Récupère un token d'authentification admin"""
    try:
        response = requests.post(
            f"{API_BASE}/auth/login",
            json={"username": "admin", "password": ADMIN_PASSWORD},
            timeout=10
        )
        if response.status_code == 200:
            return response.json()["access_token"]
        else:
            print(f"Erreur d'authentification: {response.status_code}")
            return None
    except Exception as e:
        print(f"Impossible de se connecter à l'API: {e}")
        return None

def create_hero(token, hero_data):
    """Crée un héros via l'API"""
    try:
        response = requests.post(
            f"{API_BASE}/heroes/",
            json=hero_data,
            headers={"Authorization": f"Bearer {token}"},
            timeout=10
        )
        if response.status_code == 200:
            hero = response.json()
            print(f"✅ Héros créé: {hero['nickname']} ({hero['firstname']} {hero['lastname']})")
            return True
        else:
            print(f"❌ Erreur création {hero_data['nickname']}: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Erreur réseau pour {hero_data['nickname']}: {e}")
        return False

def main():
    """Fonction principale"""
    print("🚀 Initialisation de la base avec des héros de test...")
    
    # Attendre que l'API soit disponible
    import time
    for attempt in range(30):  # 30 secondes max
        try:
            response = requests.get(f"{API_BASE}/heroes/", timeout=5)
            if response.status_code in [200, 401]:  # 401 = non authentifié mais API active
                break
        except:
            pass
        print(f"⏳ Attente de l'API... ({attempt + 1}/30)")
        time.sleep(1)
    else:
        print("❌ L'API n'est pas disponible après 30 secondes")
        sys.exit(1)
    
    # Authentification
    token = get_auth_token()
    if not token:
        print("❌ Impossible de s'authentifier")
        sys.exit(1)
    
    print("✅ Authentification réussie")
    
    # Création des héros
    created = 0
    for hero_data in HEROES_DATA:
        if create_hero(token, hero_data):
            created += 1
        time.sleep(0.5)  # Petit délai entre les créations
    
    print(f"🎉 {created}/{len(HEROES_DATA)} héros créés avec succès!")

if __name__ == "__main__":
    main()