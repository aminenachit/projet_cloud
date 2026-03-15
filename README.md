# E-Commerce Microservices - Projet Intégration Cloud

Application e-commerce microservices déployée sur Kubernetes avec Docker, sécurisée et provisionnée via Terraform.

## Architecture

```
        Nginx Ingress (Gateway)
        TLS + Rate Limiting
                 │
    ┌────────────┼────────────┐
    │            │            │
Frontend    Product     Order
(React)     Service    Service
             │            │
             └─────┬──────┘
                   │
              PostgreSQL
```

| Service | Technologie | Port |
|---------|------------|------|
| Product Service | FastAPI + SQLAlchemy | 8000 |
| Order Service | FastAPI + SQLAlchemy | 8001 |
| Frontend | React 18 + Nginx | 80 |
| Base de données | PostgreSQL 15 | 5432 |
| Gateway | Nginx Ingress Controller | 80/443 |

## Technologies

- **Backend**: Python FastAPI + SQLAlchemy
- **Frontend**: React 18 + Nginx
- **Base de données**: PostgreSQL 15
- **Conteneurisation**: Docker
- **Orchestration**: Kubernetes (Minikube)
- **Gateway**: Nginx Ingress Controller
- **Infrastructure as Code**: Terraform (GCP/GKE)
- **Sécurité**: NetworkPolicies, RBAC, Secrets, TLS, Rate Limiting

## Structure du projet

```
projet_cloud/
├── product-service/              # Microservice produits (FastAPI)
├── order-service/                # Microservice commandes (FastAPI)
├── frontend/                     # Interface React
├── kubernetes/                   # Manifests Kubernetes
│   ├── *-deployment.yaml         # Deployments avec resource limits
│   ├── *-service.yaml            # Services ClusterIP
│   ├── ingress.yaml              # Ingress avec TLS + rate limiting
│   ├── postgres-secret.yaml      # Credentials sécurisés
│   ├── postgres-pvc.yaml         # Persistance
│   └── security/                 # Sécurisation cluster
│       ├── network-policies.yaml # Isolation réseau
│       └── rbac.yaml             # Rôles et permissions
├── terraform/                    # Infrastructure as Code (GCP)
│   ├── main.tf                   # Cluster GKE, VPC, Firewall
│   ├── variables.tf              # Variables paramétrables
│   ├── outputs.tf                # Sorties Terraform
│   └── terraform.tfvars.example  # Exemple de config
├── database/init.sql             # Script d'initialisation DB
├── docker-compose.yml            # Déploiement local
└── RAPPORT.md                    # Rapport du projet
```

## Prérequis

- Docker Desktop
- Minikube + kubectl
- Compte Docker Hub

## Déploiement rapide

### Option 1 : Docker Compose (local)

```bash
docker compose up --build
```
Application accessible sur http://localhost:3000

### Option 2 : Kubernetes (Minikube)

```bash
# 1. Démarrer Minikube
minikube start
minikube addons enable ingress

# 2. Builder les images dans Minikube
eval $(minikube docker-env)
docker build -t aminenachit/product-service:latest ./product-service
docker build -t aminenachit/order-service:latest ./order-service
docker build -t aminenachit/ecommerce-frontend:latest ./frontend

# 3. Déployer
kubectl apply -f kubernetes/postgres-secret.yaml
kubectl apply -f kubernetes/
kubectl apply -f kubernetes/security/

# 4. Configurer le hosts (127.0.0.1 ecommerce.local)
# Windows: C:\Windows\System32\drivers\etc\hosts
# Linux/Mac: /etc/hosts

# 5. Ouvrir le tunnel
minikube tunnel
```
Application accessible sur http://ecommerce.local

### Option 3 : Cloud (GKE via Terraform)

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars avec votre project_id GCP

terraform init
terraform plan
terraform apply

# Configurer kubectl
gcloud container clusters get-credentials ecommerce-cluster \
  --zone europe-west1-b --project mon-projet-gcp

# Déployer les manifests
kubectl apply -f ../kubernetes/
kubectl apply -f ../kubernetes/security/
```

## APIs

### Product Service

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/products/` | Liste tous les produits |
| GET | `/products/{id}` | Récupère un produit |
| POST | `/products/` | Crée un produit |
| PUT | `/products/{id}` | Met à jour un produit |
| DELETE | `/products/{id}` | Supprime un produit |
| GET | `/health` | Health check |

### Order Service

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/orders/` | Liste toutes les commandes |
| GET | `/orders/{id}` | Récupère une commande |
| POST | `/orders/` | Crée une commande |
| PUT | `/orders/{id}/status` | Met à jour le statut |
| GET | `/health` | Health check |

## Sécurisation du cluster

| Mesure | Description |
|--------|-------------|
| **NetworkPolicies** | Isolation réseau : chaque service ne communique qu'avec les services autorisés |
| **RBAC** | Namespace dédié, ServiceAccount avec permissions minimales |
| **Secrets** | Credentials PostgreSQL encodés base64 (remplace le ConfigMap en clair) |
| **Resource Limits** | CPU et mémoire limités par pod |
| **Rate Limiting** | 20 req/s max par IP sur l'Ingress |
| **TLS** | HTTPS activé sur l'Ingress |

## Terraform (GKE)

Infrastructure provisionnée sur Google Cloud :
- VPC dédié avec sous-réseaux (pods, services)
- Cluster GKE avec Network Policy activé
- Node pool avec autoscaling (1-4 nœuds e2-medium)
- Firewall restrictif (HTTP/HTTPS uniquement)
- IP statique pour l'Ingress

## Commandes utiles

```bash
# État des ressources
kubectl get all
kubectl get ingress
kubectl get networkpolicies

# Logs
kubectl logs deployment/product-deployment
kubectl logs deployment/order-deployment

# Scaler
kubectl scale deployment product-deployment --replicas=3

# Supprimer tout
kubectl delete -f kubernetes/security/
kubectl delete -f kubernetes/
```

## Auteurs

Projet réalisé dans le cadre du cours d'Intégration Cloud - EFREI.
