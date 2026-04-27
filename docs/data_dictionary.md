# 📖 Dictionnaire de données — Movies Dataset

## Informations générales

| Propriété | Valeur |
|---|---|
| Source | Kaggle — Millions of Movies |
| Fichier | `movies.csv` |
| Séparateur | `,` |
| Encodage | UTF-8 |
| Index brut | `movies_raw` |
| Index nettoyé | `movies_clean` |

---

## Description des champs

| Champ | Type CSV | Type ES (`movies_raw`) | Type ES (`movies_clean`) | Description | Nettoyage requis |
|---|---|---|---|---|---|
| `id` | integer | integer | integer | Identifiant unique du film (TMDB) | Aucun |
| `title` | string | text | text | Titre du film | Aucun |
| `genres` | string | text | keyword (array) | Genres du film séparés par `-` | Split `-` → array |
| `original_language` | string | keyword | keyword | Langue originale (code ISO, ex: `en`) | Aucun |
| `overview` | string | text | text | Synopsis du film | Supprimer si vide |
| `popularity` | float | float | float | Score de popularité TMDB | Aucun |
| `production_companies` | string | text | keyword (array) | Sociétés de production séparées par `-` | Split `-` → array |
| `release_date` | string | keyword | date (ISO8601) | Date de sortie du film | Conversion date |
| `budget` | float | float | float | Budget du film en USD | Supprimer si = 0 |
| `revenue` | float | float | float | Recettes du film en USD | Supprimer si = 0 |
| `runtime` | float | float | integer | Durée du film en minutes | Convertir en integer |
| `status` | string | keyword | keyword | Statut du film (Released, etc.) | Aucun |
| `tagline` | string | text | text | Slogan du film | Supprimer si vide |
| `vote_average` | float | float | float | Note moyenne des utilisateurs (0-10) | Aucun |
| `vote_count` | float | float | integer | Nombre de votes | Convertir en integer |
| `credits` | string | text | keyword (array) | Acteurs séparés par `-` | Split `-` → array |
| `keywords` | string | text | keyword (array) | Mots-clés séparés par `-` | Split `-` → array |
| `poster_path` | string | keyword | keyword | Chemin relatif de l'affiche | Aucun |
| `backdrop_path` | string | keyword | keyword | Chemin relatif de l'image de fond | Aucun |
| `recommendations` | string | text | keyword (array) | IDs de films recommandés séparés par `-` | Split `-` → array |

---

## Choix de typage — Justification

### `text` vs `keyword`

| Type | Usage | Champs concernés |
|---|---|---|
| `text` | Recherche full-text, analysé, tokenisé | `title`, `overview`, `tagline` |
| `keyword` | Filtre exact, agrégation, tri, Kibana | `genres`, `original_language`, `status`, `credits`, `keywords`, `production_companies` |
| `date` | Timeline Kibana, tri temporel | `release_date` |
| `float` | Calculs statistiques | `popularity`, `vote_average`, `budget`, `revenue` |
| `integer` | Comptage, agrégation | `id`, `runtime`, `vote_count` |

### Champs multi-valués (arrays)

Les champs `genres`, `credits`, `keywords`, `production_companies` et `recommendations` sont stockés dans le CSV sous forme de chaîne avec `-` comme séparateur.

**Exemple brut :**
```
Action-Adventure-Fantasy
```

**Après nettoyage (Logstash) :**
```json
["Action", "Adventure", "Fantasy"]
```

> ⚠️ Sans ce split, Kibana ne peut pas produire de Pie Chart par genre ni d'agrégation par acteur.

---

## Anomalies identifiées (rapport ydata-profiling)

| Champ | Anomalie | Impact | Traitement |
|---|---|---|---|
| `budget` | Pic de valeurs à 0 (données manquantes masquées) | Fausse la moyenne dans Kibana | Supprimer le champ si = 0 |
| `revenue` | Pic de valeurs à 0 (données manquantes masquées) | Fausse les agrégations financières | Supprimer le champ si = 0 |
| `runtime` | Stocké en float dans le CSV | Type incohérent | Convertir en integer |
| `vote_count` | Stocké en float dans le CSV | Type incohérent | Convertir en integer |
| `release_date` | Quelques dates manquantes ou mal formatées | Film absent des timelines | Tag `_dateparsefailure` si échec |
| `overview` | Valeurs vides possibles | Champ vide inutile | Supprimer si vide |
| `tagline` | Valeurs vides fréquentes | Champ vide inutile | Supprimer si vide |
| `genres` | Chaîne brute non splitée | Agrégation impossible dans Kibana | Split `-` → array |
| `credits` | Chaîne brute non splitée | Agrégation impossible par acteur | Split `-` → array |