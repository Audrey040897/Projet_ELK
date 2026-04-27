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
