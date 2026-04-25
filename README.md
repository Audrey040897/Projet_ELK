# 🎬 Projet ELK — Movies Data Platform

# 📝 À propos du projet
Ce projet construit une plateforme d'analyse de films avec la stack ELK à partir d'un dataset de ~700 000 films issu de TMDB via Kaggle. L'objectif est d'ingérer, nettoyer et indexer les données dans Elasticsearch via Logstash, puis de produire des visualisations métier dans Kibana et un moteur de recherche full-text connecté à Elasticsearch.
Le pipeline traite automatiquement les anomalies détectées lors de l'analyse exploratoire : normalisation des champs multi-valués, correction des types, suppression des faux zéros et enrichissement des données avec des champs calculés. L'ensemble est reproductible en une commande sur toute machine disposant de Docker Desktop.

---

## 🏗️ Architecture

```
movies.csv
    │
    ▼
┌─────────────┐
│   Logstash  │  ← parse, nettoie, type, enrichit les données
└─────────────┘
    │
    ├──────────────────────┐
    ▼                      ▼
┌───────────┐       ┌─────────────┐
│movies_raw │       │movies_clean │
│ (brut)    │       │ (nettoyé)   │
│ 297 469   │       │ 300 092     │
│ documents │       │ documents   │
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
```

---

## 🛠️ Stack technique

| Service | Version | Port | URL |
|---|---|---|---|
| Elasticsearch | 8.10.2 | 9200 | http://localhost:9200 |
| Kibana | 8.10.2 | 5601 | http://localhost:5601 |
| Logstash | 8.10.2 | 9600 | http://localhost:9600 |
| PostgreSQL | 16 | 5432 | — |
| Jupyter | python-3.11 | 8888 | http://localhost:8888 |

---

## 📋 Prérequis

- Docker Desktop >= 4.x
- Docker Compose >= 2.x
- 4 Go de RAM minimum alloués à Docker
- Git

 ## ⚠️ Dataset

Le fichier `DATA/movies.csv` n'est pas versionné (trop volumineux pour GitHub).

Téléchargez-le depuis Kaggle :
👉 https://www.kaggle.com/datasets/akshaypawar7/millions-of-movies/versions/67

Puis placez-le dans le dossier `DATA/` :
```bash
cp /chemin/vers/movies.csv DATA/
```
---

## 🚀 Lancement rapide

### 1. Cloner le dépôt
```bash
git clone <url-du-repo>
cd Projet_ELK
```

### 2. Placer le dataset
```bash
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

---

## 📁 Structure du projet

```
Projet_ELK/
│
├── docker-compose.yml              ← orchestration des services
├── start.sh                        ← lancement de la stack
├── stop.sh                         ← arrêt de la stack
├── healthcheck.sh                  ← vérification santé des services
│
├── logstash/
│   └── pipeline/
│       └── logstash.conf           ← pipeline d'ingestion et nettoyage
│
├── DATA/
│   └── movies.csv                  ← dataset films (373 Mo, ~700k lignes)
│
├── logs/                           ← logs Logstash
│
├── notebooks/                      ← notebooks Jupyter d'exploration
│   └── Data_mining.ipynb           ← analyse exploratoire ydata-profiling
│
└── docs/
    ├── runbook.md  
    ├── requetes.md                   ← guide de lancement technique
    ├── data_dictionary.md          ← dictionnaire des 20 champs
    ├── data_cleaning.md            ← règles de nettoyage + impact avant/après
    ├── planning_poker.md           ← estimation des features
    └── project_management.md      ← organisation et répartition
```

---

## 📊 Index Elasticsearch

| Index | Description | Documents | Taille |
|---|---|---|---|
| `movies_raw` | Données brutes parsées depuis movies.csv | 297 469 | 423 MB |
| `movies_clean` | Données nettoyées, typées et enrichies | 300 092 | 419 MB |

### Vérification des index
```bash
# Lister tous les index
curl "http://localhost:9200/_cat/indices?v"

# Compter les documents
curl "http://localhost:9200/movies_raw/_count"
curl "http://localhost:9200/movies_clean/_count"

# Voir un document nettoyé
curl -s "http://localhost:9200/movies_clean/_search?size=1&pretty"
```

---

## 🧹 Pipeline de nettoyage (Logstash)

Le fichier `logstash/pipeline/logstash.conf` applique les transformations suivantes :

### Conversions de types
| Champ | Avant | Après |
|---|---|---|
| `runtime` | float (`137.0`) | integer (`137`) |
| `vote_count` | float (`1478.0`) | integer (`1478`) |
| `release_date` | string (`2022-04-07`) | date ISO8601 |
| `budget` | float avec faux zéros | float ou supprimé si = 0 |
| `revenue` | float avec faux zéros | float ou supprimé si = 0 |

### Normalisation des champs multi-valués
Les champs suivants sont splitées sur `-` et transformés en arrays :
- `genres` → `["Action", "Adventure", "Fantasy"]`
- `credits` → `["Actor 1", "Actor 2", ...]`
- `keywords` → `["sword", "revenge", ...]`
- `production_companies` → `["Warner Bros.", ...]`
- `recommendations` → `["123", "456", ...]`

### Champs enrichis
| Champ | Description | Exemple |
|---|---|---|
| `title_length` | Longueur du titre | `8` |
| `release_year` | Année de sortie | `2022` |
| `decade` | Décennie de sortie | `2020` |
| `era` | Époque du film | `2020s` / `classic` |
| `vote_band` | Catégorie de note | `excellent` / `good` / `average` / `poor` |
| `popularity_band` | Catégorie de popularité | `viral` / `high` / `medium` / `low` |

## A retenir: Forcer la réingestion des données

Si vous souhaitez réingérer le dataset depuis zéro :

```bash
# 1. Supprimer le sincedb pour forcer la relecture du CSV
docker compose exec logstash rm -f /tmp/movies_csv.sincedb

# 2. Relancer Logstash
docker compose restart logstash

# 3. Surveiller les logs en temps réel
docker logs -f logstash

# 4. Vérifier que les documents sont bien réingérés
curl "http://localhost:9200/movies_raw/_count"
curl "http://localhost:9200/movies_clean/_count"
```
---
 ----------------------------------------
la documentation des taches 4 5 6  ici 
----------------------------------------
## F4 - Mapping et qualité des données

### 1. Objectif

L’objectif de cette étape est d’améliorer la structure et la qualité des données dans Elasticsearch afin de :

- optimiser la recherche full-text
- améliorer les performances des filtres et agrégations
- structurer les données pour Kibana

Cette étape repose sur trois éléments :
- un mapping explicite
- un analyzer personnalisé
- un contrôle qualité avant et après optimisation

---

## 2. Mapping explicite

Un nouvel index a été créé pour remplacer le mapping automatique d’Elasticsearch.

```bash
PUT movies_clean_v2
```
Mapping utilisé

```json
{
  "settings": {
    "analysis": {
      "analyzer": {
        "custom_english": {
          "type": "standard",
          "stopwords": "_english_"
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "id": { "type": "integer" },
      "title": {
        "type": "text",
        "analyzer": "custom_english"
      },
      "overview": {
        "type": "text",
        "analyzer": "custom_english"
      },
      "genres": { "type": "keyword" },
      "original_language": { "type": "keyword" },
      "production_companies": { "type": "keyword" },
      "release_date": { "type": "date" },
      "budget": { "type": "float" },
      "revenue": { "type": "float" },
      "runtime": { "type": "integer" },
      "vote_average": { "type": "float" },
      "vote_count": { "type": "integer" },
      "credits": { "type": "keyword" },
      "keywords": { "type": "keyword" },
      "popularity": { "type": "float" }
    }
  }
}
```

Améliorations apportées : 
- suppression du mapping automatique
- définition explicite des types de champs
- séparation claire des usages : ```text``` pour la recherche full-text
```keyword``` pour filtres et agrégations, 
```types numériques``` pour l’analyse statistique
- meilleure compatibilité avec Kibana

## 3. Analyzer personnalisé

Un analyzer personnalisé a été ajouté pour améliorer la qualité de la recherche textuelle.

```json
"custom_english": {
  "type": "standard",
  "stopwords": "_english_"
}
```
Objectif : 
- suppression des mots vides (stopwords)
- amélioration de la pertinence des recherches sur les champs textuels : `title`, `overview`

## 4. Contrôle qualité avant et après
### 4.1 Avant optimisation (mapping automatique)

Le contrôle qualité a été effectué sur l’index initial `movies_clean`.

#### Vérification du mapping
```bash
GET movies_clean/_mapping
```
Résultats observés avant optimisation : 
- mapping automatique Elasticsearch
- types parfois incohérents
- duplication de champs (`text` et `keyword`)
- qualité de recherche limitée

### 4.2 Après optimisation (mapping explicite)

Le nouvel index `movies_clean_v2` a été utilisé pour validation.

#### Vérification du mapping

```bash
GET movies_clean_v2/_mapping
GET movies_clean_v2/_search?size=1
```

Résultats obsevés après optimisation :  
- mapping structuré et maîtrisé
- types de données cohérents
- amélioration de la qualité des recherches
- index adapté à l’analyse et à Kibana

------------------------------------
## F5 — Requêtes analytiques Elasticsearch (DSL)
- [Documentation tache 5](docs/requetes.md)
------------------------------------

## 📚 Documentation

- [Runbook technique](docs/runbook.md)
- [Dictionnaire de données](docs/data_dictionary.md)
- [Documentation nettoyage](docs/data_cleaning.md)
- [Planning Poker](docs/planning_poker.md)
- [Gestion de projet](docs/project_management.md)

---

## 🔍 Moteur de recherche

Un mini moteur de recherche connecté à Elasticsearch permet de :
- Rechercher un film par titre ou description (full-text)
- Filtrer par langue, genre ou année de sortie

---

## 🎯 Démo

![Démo](docs/demo.gif)

> Voir aussi : [Script de démo](docs/demo_script.md)


------------------------------------
## 📊 Dashboard Kibana — F6
------------------------------------

Le dashboard **Movies Data Platform** est disponible dans `docs/kibana/dashboard_export.ndjson`.

### Visualisations créées
1. **Films par décennie** — Bar chart : évolution de la production par décennie
2. **Répartition des notes** — Donut : distribution des vote_band (poor/average/good/excellent)
3. **Top genres les plus populaires** — Bar horizontal : les genres les plus représentés
4. **Évolution du nombre de films par année** — Line chart : tendance de production depuis 1900
5. **Répartition par popularité** — Pie : distribution des popularity_band
6. **Budget moyen par décennie** — Bar chart : évolution des budgets dans le temps
7. **Note moyenne par genre** — Bar horizontal : genres les mieux notés
8. **Durée moyenne par genre** — Bar horizontal : genres les plus longs

### Importer le dashboard
1. Ouvrir Kibana : http://localhost:5601
2. Menu → Stack Management → Saved Objects
3. Cliquer Import
4. Sélectionner `docs/kibana/dashboard_export.ndjson`
5. Accéder au dashboard via Analytics → Dashboard → Movies Data Platform