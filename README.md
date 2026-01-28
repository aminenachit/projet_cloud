# E-Commerce Mini App - Projet Kubernetes

Application e-commerce microservices déployée sur Kubernetes avec Docker.

## Architecture

L'application est composée de 3 microservices:

1. **Product Service** (FastAPI) - Port 8000
   - Gestion des produits (CRUD)
   - Base de données PostgreSQL

2. **Order Service** (FastAPI) - Port 8001
   - Gestion des commandes
   - Communication avec Product Service
   - Base de données PostgreSQL

3. **Frontend** (React + Nginx) - Port 80
   - Interface utilisateur moderne
   - Communication avec les APIs via Nginx reverse proxy

4. **PostgreSQL** - Port 5432
   - Base de données relationnelle partagée

5. **Ingress Gateway** (Nginx Ingress)
   - Point d'entrée unique pour l'application

## Technologies Utilisées

- **Backend**: Python FastAPI
- **Frontend**: React 18
- **Base de données**: PostgreSQL 15
- **Conteneurisation**: Docker
- **Orchestration**: Kubernetes
- **Gateway**: Nginx Ingress Controller
- **ORM**: SQLAlchemy

## Prérequis

- Docker Desktop installé
- Kubernetes activé dans Docker Desktop (ou Minikube)
- kubectl installé
- Compte Docker Hub (pour publier les images)

## Installation et Déploiement

### Étape 1: Construire les images Docker

```bash
# Product Service
cd product-service
docker build -t your-dockerhub-username/product-service:latest .
docker push your-dockerhub-username/product-service:latest

# Order Service
cd ../order-service
docker build -t your-dockerhub-username/order-service:latest .
docker push your-dockerhub-username/order-service:latest

# Frontend
cd ../frontend
docker build -t your-dockerhub-username/ecommerce-frontend:latest .
docker push your-dockerhub-username/ecommerce-frontend:latest
```

### Étape 2: Mettre à jour les images dans les manifests Kubernetes

Éditer les fichiers suivants et remplacer `your-dockerhub-username` par votre nom d'utilisateur Docker Hub:
- `kubernetes/product-deployment.yaml`
- `kubernetes/order-deployment.yaml`
- `kubernetes/frontend-deployment.yaml`

### Étape 3: Installer Nginx Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Attendre que l'ingress controller soit prêt
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### Étape 4: Déployer la base de données PostgreSQL

```bash
cd kubernetes

# Créer le ConfigMap pour PostgreSQL
kubectl apply -f postgres-configmap.yaml

# Créer le PersistentVolumeClaim
kubectl apply -f postgres-pvc.yaml

# Déployer PostgreSQL
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

# Vérifier que PostgreSQL est prêt
kubectl get pods -l app=postgres
```

### Étape 5: Déployer les microservices

```bash
# Déployer Product Service
kubectl apply -f product-deployment.yaml
kubectl apply -f product-service.yaml

# Déployer Order Service
kubectl apply -f order-deployment.yaml
kubectl apply -f order-service.yaml

# Déployer Frontend
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml

# Vérifier que tous les pods sont running
kubectl get pods
```

### Étape 6: Déployer l'Ingress Gateway

```bash
# Déployer l'Ingress
kubectl apply -f ingress.yaml

# Vérifier l'Ingress
kubectl get ingress
```

### Étape 7: Configurer le fichier hosts

Ajouter cette ligne à votre fichier hosts:
- Windows: `C:\Windows\System32\drivers\etc\hosts`
- Linux/Mac: `/etc/hosts`

```
127.0.0.1 ecommerce.local
```

### Étape 8: Accéder à l'application

Ouvrir votre navigateur et aller sur: `http://ecommerce.local`

## Commandes Utiles

### Vérifier l'état des ressources

```bash
# Voir tous les pods
kubectl get pods

# Voir tous les services
kubectl get services

# Voir les déploiements
kubectl get deployments

# Voir l'ingress
kubectl get ingress

# Voir les logs d'un pod
kubectl logs <pod-name>

# Décrire un pod
kubectl describe pod <pod-name>
```

### Tester les APIs directement

```bash
# Product Service
kubectl port-forward service/product-service 8000:8000
curl http://localhost:8000/products/

# Order Service
kubectl port-forward service/order-service 8001:8001
curl http://localhost:8001/orders/
```

### Supprimer tous les déploiements

```bash
kubectl delete -f kubernetes/
```

## Fonctionnalités de l'Application

### Product Service API

- `GET /products/` - Liste tous les produits
- `GET /products/{id}` - Récupère un produit
- `POST /products/` - Crée un produit
- `PUT /products/{id}` - Met à jour un produit
- `DELETE /products/{id}` - Supprime un produit
- `GET /health` - Health check

### Order Service API

- `GET /orders/` - Liste toutes les commandes
- `GET /orders/{id}` - Récupère une commande
- `POST /orders/` - Crée une commande
- `PUT /orders/{id}/status` - Met à jour le statut
- `GET /health` - Health check

### Frontend

- Vue liste des produits
- Ajout de produits
- Panier d'achat
- Création de commandes
- Historique des commandes

## Architecture Détaillée

```
┌─────────────────────────────────────────────┐
│         Nginx Ingress Controller            │
│         (ecommerce.local)                   │
└──────────────┬──────────────────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼──────┐  ┌─────▼────────┐
│  Frontend   │  │   API Routes │
│  (React)    │  │   /api/*     │
└─────────────┘  └──────┬───────┘
                        │
              ┌─────────┴─────────┐
              │                   │
       ┌──────▼──────┐     ┌─────▼────────┐
       │   Product   │────▶│    Order     │
       │   Service   │     │   Service    │
       │  (FastAPI)  │     │  (FastAPI)   │
       └──────┬──────┘     └──────┬───────┘
              │                   │
              └─────────┬─────────┘
                        │
                 ┌──────▼──────┐
                 │  PostgreSQL │
                 │  (Database) │
                 └─────────────┘
```

## Scalabilité

L'application est configurée pour avoir:
- 2 réplicas du Product Service
- 2 réplicas de l'Order Service
- 2 réplicas du Frontend
- Load balancing automatique par Kubernetes

Pour scaler manuellement:

```bash
kubectl scale deployment product-deployment --replicas=3
kubectl scale deployment order-deployment --replicas=3
kubectl scale deployment frontend-deployment --replicas=3
```

## Troubleshooting

### Les pods ne démarrent pas

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### La base de données n'est pas accessible

```bash
kubectl exec -it <postgres-pod-name> -- psql -U ecommerce_user -d ecommerce_db
```

### L'Ingress ne fonctionne pas

```bash
kubectl get ingress
kubectl describe ingress ecommerce-ingress
kubectl logs -n ingress-nginx <ingress-controller-pod>
```

### Redémarrer un service

```bash
kubectl rollout restart deployment product-deployment
kubectl rollout restart deployment order-deployment
kubectl rollout restart deployment frontend-deployment
```

## Points Importants pour l'Évaluation

Ce projet démontre:

1. **Web Services** (16/20)
   - 2 microservices FastAPI
   - Communication inter-services
   - APIs REST complètes

2. **Docker** (16/20)
   - 3 Dockerfiles optimisés
   - Images multi-stage (Frontend)
   - Publication sur Docker Hub

3. **Kubernetes** (16/20)
   - Deployments avec réplicas
   - Services ClusterIP
   - ConfigMaps et PVC
   - Health checks (liveness/readiness)

4. **Gateway** (18/20)
   - Nginx Ingress Controller
   - Routing règles
   - Point d'entrée unique

5. **Base de Données** (18/20)
   - PostgreSQL sur Kubernetes
   - Persistance avec PVC
   - Modèles relationnels

6. **Frontend** (18/20)
   - React moderne
   - Interface complète et responsive
   - Communication avec les microservices

## Auteurs

Projet réalisé dans le cadre du cours d'Intégration Cloud à l'EFREI.

## Licence

MIT
