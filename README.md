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
    ├── runbook.md  ← guide de lancement technique
    ├── requetes.md   
    ├── script_demo.md 
    ├── demo_gif.md 
    ├── kibana 
    ├    └── dashboard_export.ndjson                
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
      "filter": {
        "film_elision_fr": {
          "type": "elision",
          "articles_case": true,
          "articles": ["l", "d", "c", "j", "m", "n", "s", "t", "qu"]
        },
        "film_stop_fr": {
          "type": "stop",
          "stopwords": ["le", "la", "les", "de", "du", "des"]
        },
        "film_synonyms": {
          "type": "synonym",
          "synonyms": [
            "sci fi, science fiction",
            "sf, science fiction",
            "heroic fantasy, fantasy",
            "romcom, comedie romantique"
          ]
        }
      },
      "tokenizer": {
        "film_autocomplete_tokenizer": {
          "type": "edge_ngram",
          "min_gram": 2,
          "max_gram": 15,
          "token_chars": ["letter", "digit"]
        }
      },
      "analyzer": {
        "custom_english": {
          "type": "standard",
          "stopwords": "_english_"
        },
        "film_text_analyzer": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": [
            "lowercase",
            "film_elision_fr",
            "asciifolding",
            "film_stop_fr",
            "film_synonyms"
          ]
        },
        "film_autocomplete": {
          "type": "custom",
          "tokenizer": "film_autocomplete_tokenizer",
          "filter": ["lowercase", "asciifolding"]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "id":                   { "type": "integer" },
      "title": {
        "type": "text",
        "analyzer": "film_text_analyzer",
        "fields": {
          "english":       { "type": "text", "analyzer": "custom_english" },
          "autocomplete":  { "type": "text", "analyzer": "film_autocomplete", "search_analyzer": "standard" },
          "keyword":       { "type": "keyword" }
        }
      },
      "overview": {
        "type": "text",
        "analyzer": "film_text_analyzer",
        "fields": {
          "english": { "type": "text", "analyzer": "custom_english" }
        }
      },
      "tagline":              { "type": "text", "analyzer": "film_text_analyzer" },
      "genres":               { "type": "keyword" },
      "original_language":    { "type": "keyword" },
      "production_companies": { "type": "keyword" },
      "credits":              { "type": "keyword" },
      "keywords":             { "type": "keyword" },
      "status":               { "type": "keyword" },
      "poster_path":          { "type": "keyword" },
      "backdrop_path":        { "type": "keyword" },
      "recommendations":      { "type": "keyword" },
      "release_date":         { "type": "date" },
      "release_year":         { "type": "integer" },
      "decade":               { "type": "integer" },
      "budget":               { "type": "float" },
      "revenue":              { "type": "float" },
      "runtime":              { "type": "integer" },
      "vote_average":         { "type": "float" },
      "vote_count":           { "type": "integer" },
      "popularity":           { "type": "float" },
      "title_length":         { "type": "integer" },
      "era":                  { "type": "keyword" },
      "vote_band":            { "type": "keyword" },
      "popularity_band":      { "type": "keyword" }
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

Des analyzer personnalisé a été ajouté pour améliorer la qualité de la recherche textuelle.

```json
"custom_english": {
  "type": "standard",
  "stopwords": "_english_"
}

"film_text_analyzer": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": [
            "lowercase",
            "film_elision_fr",
            "asciifolding",
            "film_stop_fr",
            "film_synonyms"
          ]
        }

 "film_autocomplete": {
          "type": "custom",
          "tokenizer": "film_autocomplete_tokenizer",
          "filter": ["lowercase", "asciifolding"]
        }

```

Objectif : 
- suppression des mots vides (stopwords)
- amélioration de la pertinence des recherches sur les champs textuels : `title`, `overview`

- **Pour tester l'analyseur** 
```bash
  GET movies_clean_v2/_analyze
{
  "analyzer": "custom_english",
  "text": "The Fabulous Destiny of Amélie Poulain"
}
```
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


## 📊 Dashboard Kibana — F6


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

## 📚 Documentation-F7

- [Runbook technique](docs/runbook.md)
- [Dictionnaire de données](docs/data_dictionary.md)
- [Documentation nettoyage](docs/data_cleaning.md)
- [Planning Poker](docs/planning_poker.md)
- [Gestion de projet](docs/project_management.md)

---

## 🔍 Moteur de recherche — Movies Search Engine-F8

Un mini moteur de recherche connecté à Elasticsearch permet de :
- Rechercher un film par titre ou description (full-text)
- Filtrer par langue, genre ou année de sortie


## 1. Présentation

Le moteur de recherche est une interface web connectée directement à Elasticsearch.
Il permet de rechercher parmi **662 083 films** via une interface intuitive et responsive.

---

## 2. Architecture

```
Navigateur (http://localhost:3000)
        │
        ▼
┌──────────────────┐
│  search/index.html│  ← Interface HTML/CSS/JS
└──────────────────┘
        │
        │ fetch API (HTTP)
        ▼
┌──────────────────┐
│  Elasticsearch   │  ← Index movies_clean_v2
│  localhost:9200  │  ← Analyzer custom_english
└──────────────────┘
```

---

## 3. Lancement

### Prérequis
- Stack ELK démarrée via `./start.sh`
- Index `movies_clean_v2` présent avec 662 083 documents

### Démarrage du serveur

```bash
# Depuis la racine du projet
cd search
python3 -m http.server 3000
```

### Accès
Ouvre dans le navigateur : **http://localhost:3000**

---

## 4. Fonctionnalités

### 4.1 Recherche full-text

| Champ | Type | Description |
|---|---|---|
| `title` | text | Recherche sur le titre du film (poids x3) |
| `overview` | text | Recherche dans le synopsis |

La recherche utilise :
- **multi_match** sur `title` (x3) et `overview`
- **fuzzy matching** activé (`fuzziness: AUTO`) pour tolérer les fautes de frappe
- **Analyzer `custom_english`** — supprime les stopwords anglais
- **Analyseur `film_text_analyzer`**  — élision française + synonymes + asciifolding
- **Analyseur `film_autocomplete`**  — edge_ngram pour l'autocomplétion

### 4.2 Filtres disponibles

| Filtre | Champ ES | Type | Exemples |
|---|---|---|---|
| Genre | `genres` | keyword | Action, Drama, Comedy... |
| Langue | `original_language` | keyword | en, fr, es, de, ja... |
| Année | `release_year` | integer | 1900 → 2024 |
| Note minimum | `vote_average` | float | 5+, 6+, 7+, 8+ |

### 4.3 Tri des résultats

| Condition | Tri appliqué |
|---|---|
| Avec texte | Par score de pertinence (`_score`) |
| Sans texte (filtres seuls) | Par popularité décroissante |

---

## 5. Index utilisé

| Propriété | Valeur |
|---|---|
| Index | `movies_clean_v2` |
| Documents | 662 083 |
| Mapping | Explicite |
| Analyzer | `custom_english` |

### Champs affichés dans les cartes résultats

| Champ | Description |
|---|---|
| `title` | Titre du film |
| `vote_average` | Note moyenne |
| `original_language` | Langue avec drapeau |
| `release_year` | Année de sortie |
| `era` | Époque (classic, 1990s, 2000s...) |
| `genres` | Genres (array) |
| `overview` | Synopsis (3 lignes) |
| `runtime` | Durée en minutes |
| `vote_count` | Nombre de votes |

---

## 6. Exemple de requête générée

Recherche **"Batman"** avec filtre **Action** et note **7+** :

```json
POST movies_clean_v2/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "multi_match": {
            "query": "Batman",
            "fields": ["title^3", "overview"],
            "type": "best_fields",
            "fuzziness": "AUTO"
          }
        }
      ],
      "filter": [
        { "term": { "genres": "Action" } },
        { "range": { "vote_average": { "gte": 7.0 } } }
      ]
    }
  },
  "size": 24,
  "sort": ["_score"]
}
```

---

## 7. Performances observées

| Requête | Résultats | Temps |
|---|---|---|
| "Batman" (sans filtre) | 777 films | ~98ms |
| "Batman" + Action + 7+ | ~50 films | ~45ms |
| "space exploration" | ~200 films | ~120ms |

---

## 8. Limitations connues

- Maximum **24 résultats** par recherche (pas de pagination)
- Nécessite que la stack soit démarrée localement
- Pas de recherche par acteur (champ `credits` non exposé dans l'UI)
- L'interface est en anglais/français mixte

---

## 9. Améliorations possibles

- Pagination des résultats
- Recherche par acteur (`credits`)
- Affichage des affiches de films via TMDB API
- Scoring personnalisé (boost par popularité)
- Comparaison de plusieurs analyzers
---

## 🎯 Démo

![Démo](./docs/Pipeline_ELK_Complet.gif)

> Voir aussi : [Script de démo](docs/script_demo.md)

> Voir aussi : [GIF Pipeline Projet ELK](/docs/Pipeline_ELK_Complet.gif)


