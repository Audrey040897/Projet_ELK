# 🎬 Projet ELK — Movies Data Platform

Plateforme d'analyse de films construite avec la stack ELK (Elasticsearch, Logstash, Kibana).

## 🏗️ Architecture

movies.csv
│
▼
┌─────────────┐
│   Logstash  │  ← parse, nettoie, type les données
└─────────────┘
│
├──────────────────────┐
▼                      ▼
┌───────────┐       ┌─────────────┐
│movies_raw │       │movies_clean │
│ (brut)    │       │ (nettoyé)   │
└───────────┘       └─────────────┘
\               /
\             /
▼           ▼
┌───────────────┐
│ Elasticsearch │
└───────────────┘
│
▼
┌────────┐
│ Kibana │  ← Dashboard & Visualisations
└────────┘

## 🛠️ Stack technique

| Service | Version | Port |
|---|---|---|
| Elasticsearch | 8.10.2 | 9200 |
| Kibana | 8.10.2 | 5601 |
| Logstash | 8.10.2 | 9600 |
| PostgreSQL | 16 | 5432 |
| Jupyter | python-3.11 | 8888 |

## 📋 Prérequis

- Docker Desktop >= 4.x
- Docker Compose >= 2.x
- 4 Go de RAM minimum alloués à Docker
- Git

## 🚀 Lancement rapide

### 1. Cloner le dépôt
```bash
git clone <url-du-repo>
cd Projet_ELK
```

### 2. Placer le dataset
```bash
# Copier le fichier movies.csv dans le dossier DATA/
cp /chemin/vers/movies.csv DATA/
```

### 3. Démarrer la stack
```bash
./start.sh
```

### 4. Vérifier que tout est UP
```bash
./healthcheck.sh
```

### 5. Arrêter la stack
```bash
./stop.sh
```

## 🌐 Accès aux services

| Service | URL |
|---|---|
| Elasticsearch | http://localhost:9200 |
| Kibana | http://localhost:5601 |
| Logstash API | http://localhost:9600 |
| Jupyter | http://localhost:8888 (token: `elasticlab`) |

## 📁 Structure du projet

Projet_ELK/
├── docker-compose.yml        # Stack ELK
├── start.sh                  # Lancement de la stack
├── stop.sh                   # Arrêt de la stack
├── healthcheck.sh            # Vérification santé des services
├── logstash/
│   └── pipeline/
│       └── logstash.conf     # Pipeline d'ingestion
├── DATA/
│   └── movies.csv            # Dataset films
├── logs/                     # Logs Logstash
├── notebooks/                # Notebooks Jupyter
└── docs/
├── runbook.md            # Guide technique
├── data_dictionary.md    # Dictionnaire de données
├── data_cleaning.md      # Documentation nettoyage
├── planning_poker.md     # Planning poker
└── project_management.md # Gestion de projet


## 📊 Index Elasticsearch

| Index | Description |
|---|---|
| `movies_raw` | Données brutes ingérées depuis movies.csv |
| `movies_clean` | Données nettoyées et typées |

## 📚 Documentation

- [Runbook](docs/runbook.md)
- [Dictionnaire de données](docs/data_dictionary.md)
- [Documentation nettoyage](docs/data_cleaning.md)
- [Planning Poker](docs/planning_poker.md)
- [Gestion de projet](docs/project_management.md)

## ✅ Vérification des index

```bash
# Vérifier que les index existent
curl "http://localhost:9200/_cat/indices?v"

# Compter les documents dans movies_raw
curl "http://localhost:9200/movies_raw/_count"

# Compter les documents dans movies_clean
curl "http://localhost:9200/movies_clean/_count"
```