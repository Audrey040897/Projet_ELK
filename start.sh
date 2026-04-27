#!/bin/bash
echo "🚀 Démarrage de la stack ELK..."
docker compose up -d

echo "⏳ Attente que les services soient healthy..."
sleep 10

echo "✅ Vérification de l'état des services..."
docker compose ps
