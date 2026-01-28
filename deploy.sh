#!/bin/bash

# Script de déploiement automatique pour l'application E-Commerce
# Usage: ./deploy.sh [action]
# Actions: build, push, deploy, all, status, clean

set -e

# Couleurs pour les messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOCKER_USERNAME="${DOCKER_USERNAME:-your-dockerhub-username}"
PROJECT_NAME="ecommerce"

# Fonction pour afficher un message
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Vérifier les prérequis
check_prerequisites() {
    log "Vérification des prérequis..."

    if ! command -v docker &> /dev/null; then
        error "Docker n'est pas installé"
        exit 1
    fi

    if ! command -v kubectl &> /dev/null; then
        error "kubectl n'est pas installé"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        error "Docker n'est pas lancé"
        exit 1
    fi

    success "Tous les prérequis sont satisfaits"
}

# Construire les images Docker
build_images() {
    log "Construction des images Docker..."

    log "Construction de product-service..."
    docker build -t ${DOCKER_USERNAME}/product-service:latest ./product-service

    log "Construction de order-service..."
    docker build -t ${DOCKER_USERNAME}/order-service:latest ./order-service

    log "Construction du frontend..."
    docker build -t ${DOCKER_USERNAME}/ecommerce-frontend:latest ./frontend

    success "Toutes les images sont construites"
}

# Publier les images sur Docker Hub
push_images() {
    log "Publication des images sur Docker Hub..."

    if [ "$DOCKER_USERNAME" = "your-dockerhub-username" ]; then
        error "Veuillez définir DOCKER_USERNAME avec votre nom d'utilisateur Docker Hub"
        error "Exemple: export DOCKER_USERNAME=votre-username"
        exit 1
    fi

    log "Connexion à Docker Hub..."
    docker login

    log "Push de product-service..."
    docker push ${DOCKER_USERNAME}/product-service:latest

    log "Push de order-service..."
    docker push ${DOCKER_USERNAME}/order-service:latest

    log "Push du frontend..."
    docker push ${DOCKER_USERNAME}/ecommerce-frontend:latest

    success "Toutes les images sont publiées"
}

# Installer Nginx Ingress Controller
install_ingress() {
    log "Installation de Nginx Ingress Controller..."

    if kubectl get namespace ingress-nginx &> /dev/null; then
        warning "Nginx Ingress Controller est déjà installé"
    else
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

        log "Attente que l'Ingress Controller soit prêt..."
        kubectl wait --namespace ingress-nginx \
            --for=condition=ready pod \
            --selector=app.kubernetes.io/component=controller \
            --timeout=120s

        success "Nginx Ingress Controller installé"
    fi
}

# Déployer sur Kubernetes
deploy_kubernetes() {
    log "Déploiement sur Kubernetes..."

    cd kubernetes

    log "Déploiement de PostgreSQL..."
    kubectl apply -f postgres-configmap.yaml
    kubectl apply -f postgres-pvc.yaml
    kubectl apply -f postgres-deployment.yaml
    kubectl apply -f postgres-service.yaml

    log "Attente que PostgreSQL soit prêt..."
    kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s || true

    sleep 10

    log "Déploiement du Product Service..."
    kubectl apply -f product-deployment.yaml
    kubectl apply -f product-service.yaml

    log "Déploiement de l'Order Service..."
    kubectl apply -f order-deployment.yaml
    kubectl apply -f order-service.yaml

    log "Attente que les services backend soient prêts..."
    sleep 20

    log "Déploiement du Frontend..."
    kubectl apply -f frontend-deployment.yaml
    kubectl apply -f frontend-service.yaml

    log "Déploiement de l'Ingress..."
    kubectl apply -f ingress.yaml

    cd ..

    success "Déploiement terminé"
}

# Afficher le statut
show_status() {
    log "Statut du déploiement..."

    echo ""
    log "=== PODS ==="
    kubectl get pods

    echo ""
    log "=== SERVICES ==="
    kubectl get services

    echo ""
    log "=== DEPLOYMENTS ==="
    kubectl get deployments

    echo ""
    log "=== INGRESS ==="
    kubectl get ingress

    echo ""
    log "=== PVC ==="
    kubectl get pvc

    echo ""
    success "Vérifiez que tous les pods sont en status Running"
    warning "N'oubliez pas d'ajouter '127.0.0.1 ecommerce.local' à votre fichier hosts"
    success "Accédez à l'application sur: http://ecommerce.local"
}

# Nettoyer le déploiement
clean_deployment() {
    warning "Suppression de tous les déploiements..."
    read -p "Êtes-vous sûr? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete -f kubernetes/ --ignore-not-found=true
        success "Déploiement nettoyé"
    else
        log "Nettoyage annulé"
    fi
}

# Menu principal
case "${1:-all}" in
    build)
        check_prerequisites
        build_images
        ;;
    push)
        check_prerequisites
        push_images
        ;;
    deploy)
        check_prerequisites
        install_ingress
        deploy_kubernetes
        show_status
        ;;
    all)
        check_prerequisites
        build_images
        push_images
        install_ingress
        deploy_kubernetes
        show_status
        ;;
    status)
        show_status
        ;;
    clean)
        clean_deployment
        ;;
    *)
        echo "Usage: $0 {build|push|deploy|all|status|clean}"
        echo ""
        echo "  build   - Construire les images Docker"
        echo "  push    - Publier les images sur Docker Hub"
        echo "  deploy  - Déployer sur Kubernetes"
        echo "  all     - Build + Push + Deploy (défaut)"
        echo "  status  - Afficher le statut du déploiement"
        echo "  clean   - Supprimer le déploiement"
        echo ""
        echo "Exemple:"
        echo "  export DOCKER_USERNAME=votre-username"
        echo "  $0 all"
        exit 1
        ;;
esac
