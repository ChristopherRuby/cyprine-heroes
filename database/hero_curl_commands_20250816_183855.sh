#!/bin/bash
# Commandes curl pour recréer les héros
# Généré automatiquement le 2025-08-16 18:38:55
# Contient 2 héros

# Configuration
API_BASE="http://127.0.0.1:8000/api"

# Chargement du fichier .env s'il existe
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

ADMIN_PASSWORD="${ADMIN_PASSWORD}"

# Vérification des variables d'environnement
if [ -z "$ADMIN_PASSWORD" ]; then
    echo "❌ ERREUR: Variable d'environnement ADMIN_PASSWORD non définie"
    echo "💡 Veuillez définir ADMIN_PASSWORD dans votre fichier .env"
    exit 1
fi

# Fonction d'authentification
authenticate() {
    echo "🔑 Authentification..."
    TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"password": "'$ADMIN_PASSWORD'"}' | \
        python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])" 2>/dev/null)
    
    if [ -z "$TOKEN" ]; then
        echo "❌ Échec de l'authentification"
        exit 1
    fi
    
    echo "✅ Token obtenu"
}

# Authentification
authenticate

echo "🦸‍♂️ CRÉATION DES HÉROS"
echo "========================"

# Héros 1: Dobronx
echo "📝 Création de: Dobronx"
cat > hero_1_20250816_183855.json << 'EOF'
{
  "firstname": "Sebastien",
  "lastname": "Berrini",
  "nickname": "Dobronx",
  "description": "un lutteur professionnel, prêt pour la bagarre, on le surnomme le loser du nexus",
  "profile_picture": "/uploads/525db640-72d5-4851-879a-28c4d1c547fa.jpg",
  "skills": {}
}
EOF

curl -s -X POST "$API_BASE/heroes/" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d @hero_1_20250816_183855.json | \
    python3 -c "import sys, json; data=json.load(sys.stdin); print('✅ Créé: ' + data.get('nickname', 'N/A'))" 2>/dev/null || echo "❌ Erreur pour Dobronx"

rm -f hero_1_20250816_183855.json
sleep 0.5

# Héros 2: Hylia, MichMouch
echo "📝 Création de: Hylia, MichMouch"
cat > hero_2_20250816_183855.json << 'EOF'
{
  "firstname": "Michael",
  "lastname": "Pleskof",
  "nickname": "Hylia, MichMouch",
  "description": "Mika, alias MichMouch, est quelqu'un de très intelligent, très bon et drôle. sa confiance en lui peut même parfois gêner les autres inconsciemment en les renvoyant à leur insécurités ou faiblesses. C'est quelqu'un avec un bon mental. Il s'exprime bien. C'est aussi quelqu'un d'un peu assisté, dans le sens où il se sert de son argent pour éviter les tâches primaires, tel que faire sa lessive, cuisiner. Il a quelque part raison, il gagne du temps important. En tant de guerre il serait le premier à mourir au front. En générale il serait assez intelligent pour ne pas s'y retrouver. C'est aussi un porc misogyne, parfois il rote et dit des trucs sales lorsqu'il a besoin de décompresser. Ses amis l'adore pour sa vivacité d'esprit, son humour et toute sa personne attachante. Sa reflexion l'amène à se poser beaucoup de questions sur tout et n'est pas qu'une force mais aussi quelque chose de pas simple à porter parfois, faire de choix peut devenir compliqué.\nDans le monde du jeux vidéo, il joue en générale seulement que quelques personnages ou classes. Il pousse son expertise haut sur ces personnage. Il aime Donkey Kong, les singes en générale, Ragnaros dans world of warcraft, les pandas, les mages et les chamans. \nDans le Nexus, c'est un excellent combattant étant excellent sur le très peu de personnages qu'il utilise. il a pour habitude de récupérer les points d'expériences sur les trois lanes parce que ces compagnons ne font pas leur boulot.",
  "profile_picture": "/uploads/7389a5e8-88fe-4eba-8d64-feea56e6ac3a.webp",
  "skills": {}
}
EOF

curl -s -X POST "$API_BASE/heroes/" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d @hero_2_20250816_183855.json | \
    python3 -c "import sys, json; data=json.load(sys.stdin); print('✅ Créé: ' + data.get('nickname', 'N/A'))" 2>/dev/null || echo "❌ Erreur pour Hylia, MichMouch"

rm -f hero_2_20250816_183855.json
sleep 0.5

echo "🎉 Création terminée!"

# Vérification finale
echo "📊 Vérification..."
curl -s "$API_BASE/heroes/" | python3 -c "import sys, json; heroes = json.load(sys.stdin); print('Total: ' + str(len(heroes)) + ' héros dans la base')"