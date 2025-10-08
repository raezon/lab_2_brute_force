#!/bin/bash
PORT=8000
echo "🚀 Lancement du serveur local sur http://127.0.0.1:$PORT"
echo "Appuyez sur CTRL+C pour arrêter."
python -m http.server $PORT
