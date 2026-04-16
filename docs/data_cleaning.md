# 🧹 Documentation du nettoyage des données — Movies Dataset

## 1. Contexte

Le dataset `movies.csv` contient des données brutes issues de TMDB (The Movie Database) via Kaggle.
L'analyse exploratoire réalisée avec `sweetviz` a permis d'identifier plusieurs anomalies
nécessitant un nettoyage avant indexation dans `movies_clean`.

---

## 2. Anomalies détectées (avant nettoyage)

### 2.1 Champs multi-valués non normalisés

**Champs concernés :** `genres`, `production_companies`, `credits`, `keywords`, `recommendations`

**Constat :** Ces champs sont stockés comme des chaînes de caractères avec `-` comme séparateur.

**Exemple brut :**
```
genres: "Action-Adventure-Fantasy"
credits: "Alexander Skarsgård-Nicole Kidman-Claes Bang"
```

**Impact :** Impossible de faire des agrégations ou des Pie Charts dans Kibana sur ces champs.

---

### 2.2 Faux zéros dans `budget` et `revenue`

**Constat :** Un pic massif de valeurs à `0` dans les champs `budget` et `revenue`.

**Impact :** La moyenne du budget calculée dans Kibana est faussée vers le bas par ces zéros qui représentent des données manquantes et non de vrais budgets nuls.

---

### 2.3 Types incohérents

| Champ | Type CSV | Type attendu |
|---|---|---|
| `runtime` | float (ex: `137.0`) | integer (`137`) |
| `vote_count` | float (ex: `1478.0`) | integer (`1478`) |
| `release_date` | string (ex: `2022-04-07`) | date ISO8601 |

---

### 2.4 Valeurs manquantes

| Champ | Estimation % manquant | Impact |
|---|---|---|
| `overview` | ~1-2% | Synopsis vide inutile |
| `tagline` | ~30-40% | Slogan vide inutile |
| `release_date` | ~1-2% | Film absent des timelines Kibana |
| `budget` | ~70% (masqués en 0) | Fausse les agrégations financières |
| `revenue` | ~60% (masqués en 0) | Fausse les agrégations financières |

---

## 3. Règles de nettoyage appliquées (Logstash)

### Règle 1 — Split des champs multi-valués

```ruby
mutate {
  split => {
    "genres" => "-"
    "production_companies" => "-"
    "credits" => "-"
    "keywords" => "-"
    "recommendations" => "-"
  }
}
```

**Résultat :**
```json
{ "genres": ["Action", "Adventure", "Fantasy"] }
```

---

### Règle 2 — Suppression des faux zéros

```ruby
if [budget] == 0 or [budget] == "0" or [budget] == "0.0" {
  mutate { remove_field => ["budget"] }
}
if [revenue] == 0 or [revenue] == "0" or [revenue] == "0.0" {
  mutate { remove_field => ["revenue"] }
}
```

---

### Règle 3 — Conversion des types

```ruby
mutate {
  convert => {
    "runtime"    => "integer"
    "vote_count" => "integer"
    "popularity" => "float"
    "vote_average" => "float"
    "budget"     => "float"
    "revenue"    => "float"
  }
}
```

---

### Règle 4 — Parsing de la date

```ruby
date {
  match => ["release_date", "yyyy-MM-dd"]
  target => "release_date"
  tag_on_failure => ["_dateparsefailure"]
}
```

> ⚠️ En cas d'échec de parsing, Logstash ajoute le tag `_dateparsefailure`. Ces films sont documentés mais conservés dans l'index.

---

### Règle 5 — Suppression des champs vides

```ruby
if ![overview] or [overview] == "" {
  mutate { remove_field => ["overview"] }
}
if ![tagline] or [tagline] == "" {
  mutate { remove_field => ["tagline"] }
}
```

---

### Règle 6 — Suppression des champs inutiles pour l'analyse

```ruby
mutate {
  remove_field => ["@version", "host", "log", "event"]
}
```

---

## 4. Mesure d'impact avant/après nettoyage

| Métrique | `movies_raw` (avant) | `movies_clean` (après) |
|---|---|---|
| Nombre de documents | ~700 000 | ~700 000 |
| `genres` agrégeable dans Kibana | ❌ Non | ✅ Oui |
| `credits` agrégeable dans Kibana | ❌ Non | ✅ Oui |
| Moyenne `budget` fiable | ❌ Non (faussée par les 0) | ✅ Oui (0 supprimés) |
| Moyenne `revenue` fiable | ❌ Non (faussée par les 0) | ✅ Oui (0 supprimés) |
| `release_date` utilisable en timeline | ❌ Non (string) | ✅ Oui (date ISO8601) |
| `runtime` type correct | ❌ Non (float) | ✅ Oui (integer) |
| `vote_count` type correct | ❌ Non (float) | ✅ Oui (integer) |
| Champs vides présents | ✅ Oui | ❌ Non (supprimés) |

---

## 5. Tags de contrôle qualité

Logstash ajoute automatiquement des tags en cas d'anomalie :

| Tag | Signification |
|---|---|
| `_dateparsefailure` | La date `release_date` n'a pas pu être parsée |
| `_grokparsefailure` | Échec de parsing général |

Ces documents taggés peuvent être retrouvés via :
```json
GET movies_clean/_search
{
  "query": {
    "term": { "tags": "_dateparsefailure" }
  }
}
```
