# Runbook technique — Stack ELK Movies

## Prérequis

- Docker Desktop installé et lancé
- Au moins 4 Go de RAM alloués à Docker
- Git installé

## 1. Installation

```bash
git clone <url-du-repo>
cd Projet_ELK
```

## 2. Démarrage de la stack

```bash
./start.sh
```

Temps de démarrage estimé : ~30-40 secondes

## 3. Vérification santé

```bash
./healthcheck.sh
```

Résultat attendu : tous les services ✅

## 4. Arrêt de la stack

```bash
./stop.sh
```

## 5. Vérification des index

```bash
# Lister tous les index
curl "http://localhost:9200/_cat/indices?v"

# Vérifier movies_raw
curl "http://localhost:9200/movies_raw/_count"

# Vérifier movies_clean
curl "http://localhost:9200/movies_clean/_count"
```

## 6. Logs Logstash

```bash
docker logs logstash --tail 50
docker logs logstash -f  # en temps réel
```

## 7. Problèmes fréquents

### Logstash ne démarre pas
```bash
# Vérifier les logs
docker logs logstash --tail 30

# Vérifier que logstash.conf existe
ls -la logstash/pipeline/
```

### Elasticsearch ne répond pas
```bash
# Vérifier les logs
docker logs elasticsearch --tail 30

# Augmenter la mémoire virtuelle
sudo sysctl -w vm.max_map_count=262144
```

### Kibana ne démarre pas
```bash
# Attendre 30-40 secondes après le lancement
# Vérifier les logs
docker logs kibana --tail 30
```

## 8. Réinitialisation complète

```bash
./stop.sh
docker volume rm projet_elk_es_data projet_elk_postgres_data
./start.sh
```
