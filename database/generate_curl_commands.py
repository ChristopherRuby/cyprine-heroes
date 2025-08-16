#!/usr/bin/env python3
"""
Script pour parser l'API backend des héros et générer des commandes curl
pour recréer les héros dans une nouvelle base de données.
"""

import os
import sys
import json
import requests
import time
from datetime import datetime
from typing import List, Dict, Any, Optional
from pathlib import Path

# Chargement du fichier .env s'il existe
def load_env_file():
    """Charge le fichier .env dans l'environnement"""
    env_file = Path(__file__).parent / '.env'
    if env_file.exists():
        with open(env_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key.strip()] = value.strip()

# Charger les variables d'environnement
load_env_file()

# Configuration
API_BASE = "http://127.0.0.1:8000/api"
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD")

if not ADMIN_PASSWORD:
    print("❌ ERREUR: Variable d'environnement ADMIN_PASSWORD non définie")
    print("💡 Veuillez définir ADMIN_PASSWORD dans votre fichier .env")
    sys.exit(1)

class HerosCurlGenerator:
    def __init__(self, api_base: str, password: str):
        self.api_base = api_base
        self.password = password
        self.token = None
        self.session = requests.Session()
        
    def wait_for_api(self, max_attempts: int = 30) -> bool:
        """Attend que l'API soit disponible"""
        print("🔍 Vérification de la disponibilité de l'API...")
        
        for attempt in range(max_attempts):
            try:
                response = self.session.get(f"{self.api_base}/heroes/", timeout=5)
                if response.status_code in [200, 401]:  # 401 = pas authentifié mais API OK
                    print("✅ API disponible")
                    return True
            except requests.exceptions.RequestException:
                if attempt < max_attempts - 1:
                    print(f"⏳ Tentative {attempt + 1}/{max_attempts}...")
                    time.sleep(1)
                    continue
                
        print("❌ API non disponible")
        return False
    
    def authenticate(self) -> bool:
        """S'authentifie auprès de l'API"""
        try:
            response = self.session.post(
                f"{self.api_base}/auth/login",
                json={"password": self.password},
                timeout=10
            )
            
            if response.status_code == 200:
                self.token = response.json()["access_token"]
                self.session.headers.update({"Authorization": f"Bearer {self.token}"})
                return True
            else:
                print(f"❌ Échec authentification: {response.status_code}")
                return False
                
        except requests.exceptions.RequestException as e:
            print(f"❌ Erreur authentification: {e}")
            return False
    
    def get_heroes(self) -> Optional[List[Dict[str, Any]]]:
        """Récupère la liste des héros depuis l'API"""
        try:
            response = self.session.get(f"{self.api_base}/heroes/", timeout=10)
            
            if response.status_code == 200:
                heroes = response.json()
                print(f"📋 {len(heroes)} héros récupérés depuis l'API")
                return heroes
            else:
                print(f"❌ Erreur récupération héros: {response.status_code}")
                return None
                
        except requests.exceptions.RequestException as e:
            print(f"❌ Erreur réseau: {e}")
            return None
    
    def filter_test_heroes(self, heroes: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Filtre les héros de test"""
        filtered_heroes = []
        test_keywords = ['test', 'demo', 'example', 'sample']
        
        for hero in heroes:
            nickname = hero.get('nickname', '').lower()
            description = hero.get('description', '')
            
            # Exclure si le nickname contient des mots-clés de test
            if any(keyword in nickname for keyword in test_keywords):
                print(f"🗑️  Exclu (test): {hero.get('nickname')}")
                continue
            
            # Exclure si la description est très courte (probablement un test)
            if len(description) < 50:
                print(f"🗑️  Exclu (description courte): {hero.get('nickname')}")
                continue
            
            print(f"✅ Inclus: {hero.get('nickname')} ({hero.get('real_name', 'N/A')})")
            filtered_heroes.append(hero)
        
        print(f"📊 {len(filtered_heroes)} héros conservés, {len(heroes) - len(filtered_heroes)} exclus")
        return filtered_heroes
    
    def escape_json_for_bash(self, data: Dict[str, Any]) -> str:
        """Échappe correctement le JSON pour bash"""
        json_str = json.dumps(data, ensure_ascii=False, separators=(',', ':'))
        # Échapper les caractères spéciaux pour bash
        json_str = json_str.replace("'", "'\"'\"'")  # Échapper les apostrophes
        json_str = json_str.replace('"', '\\"')      # Échapper les guillemets
        return json_str
    
    def generate_curl_commands(self, heroes: List[Dict[str, Any]]) -> str:
        """Génère un fichier avec les commandes curl pour recréer les héros"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_filename = f"hero_curl_commands_{timestamp}.sh"
        
        # En-tête du fichier
        curl_commands = [
            "#!/bin/bash",
            "# Commandes curl pour recréer les héros",
            f"# Généré automatiquement le {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            f"# Contient {len(heroes)} héros",
            "",
            "# Configuration",
            f'API_BASE="{self.api_base}"',
            "",
            "# Chargement du fichier .env s'il existe",
            "if [ -f .env ]; then",
            "    export $(cat .env | grep -v '^#' | xargs)",
            "fi",
            "",
            f'ADMIN_PASSWORD="${{ADMIN_PASSWORD}}"',
            "",
            "# Vérification des variables d'environnement",
            "if [ -z \"$ADMIN_PASSWORD\" ]; then",
            "    echo \"❌ ERREUR: Variable d'environnement ADMIN_PASSWORD non définie\"",
            "    echo \"💡 Veuillez définir ADMIN_PASSWORD dans votre fichier .env\"",
            "    exit 1",
            "fi",
            "",
            "# Fonction d'authentification",
            "authenticate() {",
            "    echo \"🔑 Authentification...\"",
            "    TOKEN=$(curl -s -X POST \"$API_BASE/auth/login\" \\",
            "        -H \"Content-Type: application/json\" \\",
            "        -d '{\"password\": \"'$ADMIN_PASSWORD'\"}' | \\",
            "        python3 -c \"import sys, json; print(json.load(sys.stdin)['access_token'])\" 2>/dev/null)",
            "    ",
            "    if [ -z \"$TOKEN\" ]; then",
            "        echo \"❌ Échec de l'authentification\"",
            "        exit 1",
            "    fi",
            "    ",
            "    echo \"✅ Token obtenu\"",
            "}",
            "",
            "# Authentification",
            "authenticate",
            "",
            "echo \"🦸‍♂️ CRÉATION DES HÉROS\"",
            "echo \"========================\"",
            ""
        ]
        
        # Génération des commandes pour chaque héros
        for i, hero in enumerate(heroes, 1):
            nickname = hero.get('nickname', f'Hero_{i}')
            
            # Préparer les données du héros (sans l'ID)
            hero_data = {k: v for k, v in hero.items() if k not in ['id', 'created_at', 'updated_at']}
            
            # Créer un fichier JSON temporaire pour ce héros
            json_filename = f"hero_{i}_{timestamp}.json"
            
            curl_commands.extend([
                f"# Héros {i}: {nickname}",
                f"echo \"📝 Création de: {nickname}\"",
                f"cat > {json_filename} << 'EOF'",
                json.dumps(hero_data, ensure_ascii=False, indent=2),
                "EOF",
                "",
                f"curl -s -X POST \"$API_BASE/heroes/\" \\",
                f"    -H \"Authorization: Bearer $TOKEN\" \\",
                f"    -H \"Content-Type: application/json\" \\",
                f"    -d @{json_filename} | \\",
                f"    python3 -c \"import sys, json; data=json.load(sys.stdin); print('✅ Créé: ' + data.get('nickname', 'N/A'))\" 2>/dev/null || echo \"❌ Erreur pour {nickname}\"",
                "",
                f"rm -f {json_filename}",
                "sleep 0.5",
                ""
            ])
        
        # Pied de fichier
        curl_commands.extend([
            "echo \"🎉 Création terminée!\"",
            "",
            "# Vérification finale",
            "echo \"📊 Vérification...\"",
            "curl -s \"$API_BASE/heroes/\" | python3 -c \"import sys, json; heroes = json.load(sys.stdin); print('Total: ' + str(len(heroes)) + ' héros dans la base')\""
        ])
        
        # Écriture du fichier
        with open(output_filename, 'w', encoding='utf-8') as f:
            f.write('\n'.join(curl_commands))
        
        # Rendre le fichier exécutable
        os.chmod(output_filename, 0o755)
        
        print(f"🐚 Fichier curl généré: {output_filename}")
        return output_filename
    
    def show_summary(self, heroes: List[Dict[str, Any]]):
        """Affiche un résumé des héros qui seront recréés"""
        print(f"\n{'='*60}")
        print(f"📊 RÉSUMÉ DES HÉROS À RECRÉER ({len(heroes)} héros)")
        print(f"{'='*60}")
        
        for i, hero in enumerate(heroes, 1):
            skills_count = len(hero.get('skills', {}))
            desc_length = len(hero.get('description', ''))
            
            print(f"\n{i}. {hero.get('nickname', 'N/A')}")
            print(f"   👤 {hero.get('real_name', 'N/A')}")
            print(f"   📝 Description: {desc_length} caractères")
            print(f"   🎯 Compétences: {skills_count}")
            
            if hero.get('skills'):
                skills_str = ', '.join([f"{k}:{v}" for k, v in hero['skills'].items()])
                print(f"      {skills_str}")

def main():
    """Fonction principale"""
    print("🦸‍♂️ GÉNÉRATEUR DE COMMANDES CURL POUR HÉROS")
    print("=" * 50)
    
    generator = HerosCurlGenerator(API_BASE, ADMIN_PASSWORD)
    
    # Vérifier l'API
    if not generator.wait_for_api():
        sys.exit(1)
    
    # S'authentifier
    if not generator.authenticate():
        sys.exit(1)
    print("✅ Authentification réussie")
    
    # Récupérer les héros
    all_heroes = generator.get_heroes()
    if not all_heroes:
        print("❌ Aucun héros trouvé")
        sys.exit(1)
    
    # Filtrer les héros de test
    heroes = generator.filter_test_heroes(all_heroes)
    if not heroes:
        print("❌ Aucun héros valide après filtrage")
        sys.exit(1)
    
    # Générer le fichier de commandes curl
    curl_file = generator.generate_curl_commands(heroes)
    
    # Afficher le résumé
    generator.show_summary(heroes)
    
    print(f"\n✨ Génération terminée avec succès!")
    print(f"📄 Fichier curl: {curl_file}")
    print(f"\n💡 Pour recréer les héros:")
    print(f"   ./{curl_file}")

if __name__ == "__main__":
    main()
