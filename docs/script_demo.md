# 🎬 Script de Démonstration — Movies Data Platform

## Informations générales

| Propriété | Valeur |
|---|---|
| Durée estimée | ~3-5 minutes |
| Prérequis | Stack ELK lancée via `./start.sh` |
| Dataset | `movies.csv` (~300 000 films) |

---

## 🏗️ Étape 1 — Vérification de la stack

**Ce qu'on montre :** Les 5 services actifs et healthy.

```bash
./healthcheck.sh
```

**Résultat attendu :**
```
✅ Elasticsearch est UP — cluster: docker-cluster / version: 8.10.2
✅ Kibana est UP — level: available
✅ Logstash est UP
✅ PostgreSQL est UP
✅ Jupyter est UP
```

---

## 📥 Étape 2 — Ingestion des données (F2 & F3)

**Ce qu'on montre :** Les index créés avec leurs documents.

```bash
curl "http://localhost:9200/_cat/indices?v"
```

**Résultat attendu :**
```
yellow open movies_raw      — 297 469 docs — 423 MB
yellow open movies_clean    — 300 092 docs — 419 MB
yellow open movies_clean_v2 — 300 092 docs — mapping explicite
```

```bash
curl "http://localhost:9200/movies_raw/_count"
curl "http://localhost:9200/movies_clean/_count"
curl "http://localhost:9200/movies_clean_v2/_count"
```

**Narration :**
> Le pipeline Logstash a ingéré ~300 000 films depuis le CSV.
> movies_raw contient les données brutes parsées.
> movies_clean contient les données nettoyées et enrichies.
> movies_clean_v2 est l'index final avec le mapping explicite.

---

## 🗺️ Étape 3 — Mapping explicite & Analyzer personnalisé (F4)

**Ce qu'on montre :** Le mapping structuré de movies_clean_v2.

```bash
curl -s "http://localhost:9200/movies_clean_v2/_mapping?pretty"
```

**Points clés :**

| Champ | Type | Justification |
|---|---|---|
| `title` | text + `custom_english` | Recherche full-text |
| `overview` | text + `custom_english` | Recherche sémantique |
| `genres` | keyword | Agrégation Kibana |
| `release_date` | date | Timeline Kibana |
| `vote_average` | float | Statistiques |
| `runtime` | integer | Calculs |

```bash
# Tester l'analyzer custom_english
curl -s -X POST "http://localhost:9200/movies_clean_v2/_analyze?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "analyzer": "custom_english",
    "text": "The dark knight rises from the shadows"
  }'
```

**Narration :**
> Le mapping explicite garantit des types cohérents sur tous les champs.
> L'analyzer custom_english supprime les stopwords anglais pour améliorer
> la pertinence des recherches sur title et overview.

---

## 🔍 Étape 4 — Requêtes Elasticsearch (F5)

### Requête 1 — Recherche full-text sur le titre
```bash
curl -s -X GET "http://localhost:9200/movies_clean_v2/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": { "match": { "title": "Batman" } },
    "_source": ["title", "release_year", "vote_average"],
    "size": 3
  }'
```

### Requête 2 — Recherche dans le synopsis
```bash
curl -s -X GET "http://localhost:9200/movies_clean_v2/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": { "match": { "overview": "space exploration mission" } },
    "_source": ["title", "overview"],
    "size": 3
  }'
```

### Requête 3 — Bool : films d'action récents et bien notés
```bash
curl -s -X GET "http://localhost:9200/movies_clean_v2/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "bool": {
        "must": [
          { "term": { "genres": "Action" } },
          { "range": { "release_year": { "gte": 2015 } } },
          { "range": { "vote_average": { "gte": 7.0 } } }
        ]
      }
    },
    "_source": ["title", "release_year", "vote_average", "genres"],
    "size": 3
  }'
```

### Requête 4 — Bool : classiques populaires
```bash
curl -s -X GET "http://localhost:9200/movies_clean_v2/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "bool": {
        "must": [{ "range": { "popularity": { "gte": 50 } } }],
        "must_not": [{ "range": { "release_year": { "gte": 2020 } } }]
      }
    },
    "_source": ["title", "release_year", "popularity"],
    "size": 3
  }'
```

### Requête 5 — Bool : blockbusters rentables
```bash
curl -s -X GET "http://localhost:9200/movies_clean_v2/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "bool": {
        "must": [
          { "range": { "budget": { "gte": 100000000 } } },
          { "range": { "revenue": { "gte": 300000000 } } }
        ]
      }
    },
    "_source": ["title", "budget", "revenue", "release_year"],
    "size": 3
  }'
```

### Requête 6 — Agrégation : répartition des genres
```bash
curl -s -X GET "http://localhost:9200/movies_clean_v2/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 0,
    "aggs": {
      "genres_distribution": {
        "terms": { "field": "genres", "size": 10 }
      }
    }
  }'
```

### Requête 7 — Agrégation : note moyenne par décennie
```bash
curl -s -X GET "http://localhost:9200/movies_clean_v2/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 0,
    "aggs": {
      "by_decade": {
        "terms": { "field": "decade" },
        "aggs": {
          "avg_rating": { "avg": { "field": "vote_average" } }
        }
      }
    }
  }'
```

**Narration :**
> Les bool queries combinent plusieurs critères métier en une seule requête.
> Les agrégations alimentent directement les visualisations Kibana.

---

## 📊 Étape 5 — Dashboard Kibana (F6)

**URL :** http://localhost:5601

**Parcours du dashboard Movies Data Platform :**

| # | Visualisation | Type | Question métier |
|---|---|---|---|
| 1 | Films par décennie | Bar chart | Comment a évolué la production ? |
| 2 | Répartition des notes | Donut | Quelle est la qualité globale ? |
| 3 | Top genres les plus populaires | Bar horizontal | Quels genres dominent ? |
| 4 | Évolution du nombre de films par année | Line chart | Tendance depuis 1900 ? |
| 5 | Répartition par popularité | Pie chart | Distribution des popularity_band ? |
| 6 | Budget moyen par décennie | Bar chart | Les budgets ont-ils augmenté ? |
| 7 | Note moyenne par genre | Bar horizontal | Quels genres sont les mieux notés ? |
| 8 | Durée moyenne par genre | Bar horizontal | Quels genres sont les plus longs ? |

**Pour importer le dashboard :**
```
Kibana → Stack Management → Saved Objects → Import
→ Sélectionner docs/kibana/dashboard_export.ndjson
→ Analytics → Dashboard → Movies Data Platform
```

**Narration :**
> Le dashboard répond à des questions métier concrètes sur l'industrie cinématographique.
> Chaque visualisation exploite les champs enrichis créés par Logstash :
> decade, vote_band, popularity_band.

---

## 🔎 Étape 6 — Moteur de recherche (F8)
```bash
Prérequis : Stack lancée via ./start.sh
```
## Lancement du serveur
```bash
bash 
cd search
python3 -m http.server 3000
Ouvre http://localhost:3000 dans le navigateur.
```
### Scénario de démonstration

```bash
Scène 1 — Recherche simple

Taper "Batman" dans la barre de recherche
Cliquer RECHERCHER
Résultat : 777 films trouvés en ~98ms
Montrer les cartes : titre, note, année, era, genres, synopsis
```
```bash
Scène 2 — Recherche dans le synopsis

Taper "space exploration"
Cliquer RECHERCHER
Montrer que la recherche fonctionne sur l'overview
```
```bash
Scène 3 — Combinaison recherche + filtres

Taper "Batman"
Sélectionner Genre : Action
Sélectionner Langue : Anglais
Sélectionner Note minimum : 7+
Cliquer RECHERCHER
Montrer les résultats filtrés et précis
```
```bash
Scène 4 — Réinitialisation

Cliquer Réinitialiser
Montrer que tous les filtres sont remis à zéro
```
### Points techniques à mentionner

Connecté à movies_clean_v2 avec mapping explicite
Utilise l'analyzer custom_english pour la recherche full-text
Fuzzy matching activé (tolère les fautes de frappe)
Tri par score de pertinence si recherche textuelle
Tri par popularité si filtres seuls

---

## ✅ Bilan — Ce qu'on a livré

| Feature | Description | Statut |
|---|---|---|
| F1 | Bootstrap stack Docker | ✅ |
| F2 | Ingestion brute → `movies_raw` | ✅ 297 469 docs |
| F3 | Nettoyage → `movies_clean` | ✅ 300 092 docs |
| F4 | Mapping explicite → `movies_clean_v2` | ✅ analyzer `custom_english` |
| F5 | 12 requêtes DSL dont 5 bool | ✅ |
| F6 | Dashboard Kibana 8 visualisations | ✅ |
| F7 | Documentation complète | ✅ |
| F8 | Moteur de recherche full-text | ✅ |

```bash
# Reproductibilité — relancer depuis zéro sur une machine vierge
git clone <url-du-repo>
cd Projet_ELK
cp /chemin/vers/movies.csv DATA/
./start.sh
# → Stack opérationnelle en ~40 secondes
# → Ingestion automatique au démarrage de Logstash
```