#!/bin/bash

echo "========================================="
echo "   VÉRIFICATION SANTÉ DE LA STACK ELK   "
echo "========================================="

# Elasticsearch
echo ""
echo "🔍 Elasticsearch (port 9200)..."
ES_RESPONSE=$(curl -s http://localhost:9200)
if echo "$ES_RESPONSE" | grep -q "cluster_name"; then
  echo "✅ Elasticsearch est UP"
  echo "$ES_RESPONSE" | grep -E '"number"|"cluster_name"'
else
  echo "❌ Elasticsearch ne répond pas"
fi

# Kibana
echo ""
echo "🔍 Kibana (port 5601)..."
KIBANA_STATUS=$(curl -s http://localhost:5601/api/status | grep -o '"level":"[^"]*"' | head -1)
if curl -fsS http://localhost:5601/api/status > /dev/null 2>&1; then
  echo "✅ Kibana est UP — $KIBANA_STATUS"
else
  echo "❌ Kibana ne répond pas"
fi

# Logstash
echo ""
echo "🔍 Logstash (port 9600)..."
if curl -fsS http://localhost:9600 > /dev/null 2>&1; then
  echo "✅ Logstash est UP"
else
  echo "❌ Logstash ne répond pas"
fi

# Postgres
echo ""
echo "🔍 PostgreSQL (port 5432)..."
if docker exec postgres pg_isready -U elk -d elk_course > /dev/null 2>&1; then
  echo "✅ PostgreSQL est UP"
else
  echo "❌ PostgreSQL ne répond pas"
fi

# Jupyter
echo ""
echo "🔍 Jupyter (port 8888)..."
if curl -fsS http://localhost:8888/lab > /dev/null 2>&1; then
  echo "✅ Jupyter est UP"
else
  echo "❌ Jupyter ne répond pas"
fi

# Index Elasticsearch
echo ""
echo "📦 Index Elasticsearch existants :"
curl -s "http://localhost:9200/_cat/indices?v&h=health,status,index,docs.count,store.size"

echo ""
echo "========================================="
echo "   FIN DE LA VÉRIFICATION"
echo "========================================="
