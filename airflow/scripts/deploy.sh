#!/bin/bash

set -e  # Salir si hay error

ENVIRONMENT=$1
if [ -z "$ENVIRONMENT" ]; then
    echo "Uso: $0 <environment>"
    echo "Environment: dev, staging, prod"
    exit 1
fi

echo "🚀 Deploying Airflow to $ENVIRONMENT environment"

# Verificar tests pasaron
echo "📋 Running tests..."
python -m pytest tests/dags/ -v

# Build imagen si es necesario
if [ "$ENVIRONMENT" = "prod" ]; then
    echo "🏗️  Building production image..."
    docker build -t airflow-prod:$GITHUB_SHA .
fi

# Deploy según environment
case $ENVIRONMENT in
    dev)
        echo "🔧 Deploying to development..."
        docker-compose -f docker-compose.dev.yml up -d
        ;;
    staging)
        echo "🧪 Deploying to staging..."
        kubectl apply -f k8s/staging/
        ;;
    prod)
        echo "🎯 Deploying to production..."
        kubectl apply -f k8s/prod/
        # Health checks
        sleep 30
        curl -f http://airflow-prod/health || exit 1
        ;;
esac

echo "✅ Deployment to $ENVIRONMENT completed successfully"