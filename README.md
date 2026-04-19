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

### Objectif

Cette étape vise à exploiter les données de l’index `movies_clean_v2` afin de :

- tester le moteur de recherche Elasticsearch ;
- analyser les tendances cinéma ;
- alimenter les visualisations Kibana ;
- segmenter les films selon des critères métier.

Les 12 requêtes sont classées en trois catégories :
1. Requêtes de recherche (utilisables dans le moteur de recherche et Kibana Discover)
2. Requêtes booléennes (au moins 5, pour la segmentation métier)
3. Requêtes analytiques avec agrégations (pour les visualisations Kibana)

---

### 1. Requêtes de recherche (moteur de recherche / Discover Kibana)

**1- Recherche full-text sur le titre**

```json
GET movies_clean_v2/_search
{
  "query": {
    "match": {
      "title": "Batman"
    }
  }
}
```

**Utilisation** : moteur de recherche type Netflix ou Discover dans Kibana.
Permet de tester la recherche textuelle sur les titres avec l’analyzer personnalisé `custom_english`.

**2- Recherche dans le synopsis**
```json
GET movies_clean_v2/_search
{
  "query": {
    "match": {
      "overview": "space exploration mission"
    }
  }
}
```
**Utilisation** : moteur de recommandation basé sur le contenu ou Discover Kibana.
Permet une recherche sémantique sur les descriptions de films.

**3- Filtre par langue originale**
```json
GET movies_clean_v2/_search
{
  "query": {
    "term": {
      "original_language": "en"
    }
  }
}
```
**Utilisation** : filtrage dans le dashboard Kibana ou segmentation par marché linguistique.

**4- Filtre par année de sortie**
```json
GET movies_clean_v2/_search
{
  "query": {
    "term": {
      "release_year": 2020
    }
  }
}
```
**Utilisation** : analyse temporelle et timelines dans Kibana.

### 2. Requêtes booléennes (segmentation métier)

**5- Films d’action récents et bien notés**
```json
GET movies_clean_v2/_search
{
  "query": {
    "bool": {
      "must": [
        { "term": { "genres": "Action" } },
        { "range": { "release_year": { "gte": 2015 } } },
        { "range": { "vote_average": { "gte": 7.0 } } }
      ]
    }
  }
}
```

**Utilisation** : Combine genre, temporalité et qualité pour isoler les meilleurs films d’action récents.

**6- Films populaires mais anciens**
```json
GET movies_clean_v2/_search
{
  "query": {
    "bool": {
      "must": [
        { "range": { "popularity": { "gte": 50 } } }
      ],
      "must_not": [
        { "range": { "release_year": { "gte": 2020 } } }
      ]
    }
  }
}
```
**Utilité** : Permet d’identifier les classiques populaires qui ne sont plus récents.

**7. Films en anglais ou en français** : 
```json
GET movies_clean_v2/_search
{
  "query": {
    "bool": {
      "should": [
        { "term": { "original_language": "en" } },
        { "term": { "original_language": "fr" } }
      ],
      "minimum_should_match": 1
    }
  }
}
```

**Utilité** : Analyse de la distribution linguistique des films.

**8- Films à gros budget et gros revenus (blockbusters rentables)**
```json
GET movies_clean_v2/_search
{
  "query": {
    "bool": {
      "must": [
        { "range": { "budget": { "gte": 100000000 } } },
        { "range": { "revenue": { "gte": 300000000 } } }
      ]
    }
  }
}
```

**Utilisation** : analyse du retour sur investissement (ROI).

**9. Exclusion des films mal notés** : 
```json
GET movies_clean_v2/_search
{
  "query": {
    "bool": {
      "must_not": [
        { "range": { "vote_average": { "lt": 5.0 } } }
      ]
    }
  }
}
```

**Utilité** : Permet de filtrer les films de faible qualité dans les recommandations ou dashboards.

### 3. Requêtes analytiques avec agrégations (visualisations Kibana) : 

**10- Répartition des genres**
```json
GET movies_clean_v2/_search
{
  "size": 0,
  "aggs": {
    "genres_distribution": {
      "terms": {
        "field": "genres"
      }
    }
  }
}
```

**Utilisation dans Kibana** : Pie chart ou Bar chart (genres dominants).

**11. Note moyenne par décennie** : 
```json
GET movies_clean_v2/_search
{
  "size": 0,
  "aggs": {
    "by_decade": {
      "terms": {
        "field": "decade"
      },
      "aggs": {
        "avg_rating": {
          "avg": {
            "field": "vote_average"
          }
        }
      }
    }
  }
}
```

**Utilisation dans Kibana** : Line chart ou Bar chart (évolution de la qualité des films dans le temps).

**12. Budget et revenus moyens par genre**
```json
GET movies_clean_v2/_search
{
  "size": 0,
  "aggs": {
    "by_genre": {
      "terms": {
        "field": "genres"
      },
      "aggs": {
        "avg_budget": {
          "avg": { "field": "budget" }
        },
        "avg_revenue": {
          "avg": { "field": "revenue" }
        }
      }
    }
  }
}
```
**Utilisation dans Kibana** : analyse de la rentabilité par genre.

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