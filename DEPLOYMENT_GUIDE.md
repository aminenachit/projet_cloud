# Guide de Déploiement Rapide

## Option 1: Test Local avec Docker Compose (Recommandé pour débuter)

### Prérequis
- Docker Desktop installé et lancé

### Commandes

```bash
# 1. Démarrer tous les services
docker-compose up -d

# 2. Vérifier que tout fonctionne
docker-compose ps

# 3. Voir les logs
docker-compose logs -f

# 4. Accéder à l'application
# Frontend: http://localhost
# Product API: http://localhost:8000/docs
# Order API: http://localhost:8001/docs

# 5. Arrêter les services
docker-compose down

# 6. Arrêter et supprimer les volumes
docker-compose down -v
```

---

## Option 2: Déploiement Kubernetes (Production)

### Prérequis
- Kubernetes activé (Docker Desktop ou Minikube)
- kubectl installé
- Compte Docker Hub

### Étape 1: Construire et publier les images

```bash
# Remplacer 'your-dockerhub-username' par votre nom d'utilisateur

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

cd ..
```

### Étape 2: Mettre à jour les manifests

Éditer les fichiers suivants et remplacer `your-dockerhub-username`:
- `kubernetes/product-deployment.yaml` ligne 18
- `kubernetes/order-deployment.yaml` ligne 18
- `kubernetes/frontend-deployment.yaml` ligne 18

```yaml
# Exemple:
image: votre-username/product-service:latest
```

### Étape 3: Installer Nginx Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Attendre que l'ingress soit prêt
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### Étape 4: Déployer la base de données

```bash
cd kubernetes

kubectl apply -f postgres-configmap.yaml
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

# Attendre que PostgreSQL soit prêt
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s
```

### Étape 5: Déployer les services backend

```bash
kubectl apply -f product-deployment.yaml
kubectl apply -f product-service.yaml

kubectl apply -f order-deployment.yaml
kubectl apply -f order-service.yaml

# Attendre que les services soient prêts
kubectl wait --for=condition=ready pod -l app=product-service --timeout=120s
kubectl wait --for=condition=ready pod -l app=order-service --timeout=120s
```

### Étape 6: Déployer le frontend

```bash
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml

# Attendre que le frontend soit prêt
kubectl wait --for=condition=ready pod -l app=frontend --timeout=120s
```

### Étape 7: Déployer l'Ingress

```bash
kubectl apply -f ingress.yaml

# Vérifier l'Ingress
kubectl get ingress
```

### Étape 8: Configurer le fichier hosts

**Windows:**
```bash
# Ouvrir en administrateur: C:\Windows\System32\drivers\etc\hosts
# Ajouter la ligne:
127.0.0.1 ecommerce.local
```

**Linux/Mac:**
```bash
echo "127.0.0.1 ecommerce.local" | sudo tee -a /etc/hosts
```

### Étape 9: Accéder à l'application

Ouvrir le navigateur: `http://ecommerce.local`

---

## Commandes Utiles

### Vérifier l'état

```bash
# Tous les pods
kubectl get pods

# Tous les services
kubectl get services

# Tous les déploiements
kubectl get deployments

# L'Ingress
kubectl get ingress

# Tout
kubectl get all
```

### Voir les logs

```bash
# Logs d'un pod spécifique
kubectl logs <pod-name>

# Logs en temps réel
kubectl logs -f <pod-name>

# Logs des dernières lignes
kubectl logs --tail=50 <pod-name>
```

### Déboguer

```bash
# Décrire un pod
kubectl describe pod <pod-name>

# Entrer dans un pod
kubectl exec -it <pod-name> -- /bin/sh

# Tester la base de données
kubectl exec -it <postgres-pod> -- psql -U ecommerce_user -d ecommerce_db
```

### Port forwarding (pour tester les services directement)

```bash
# Product Service
kubectl port-forward service/product-service 8000:8000

# Order Service
kubectl port-forward service/order-service 8001:8001

# Frontend
kubectl port-forward service/frontend-service 8080:80
```

### Scaling

```bash
# Augmenter le nombre de réplicas
kubectl scale deployment product-deployment --replicas=3
kubectl scale deployment order-deployment --replicas=3
kubectl scale deployment frontend-deployment --replicas=3

# Vérifier
kubectl get pods
```

### Redémarrer un déploiement

```bash
kubectl rollout restart deployment product-deployment
kubectl rollout restart deployment order-deployment
kubectl rollout restart deployment frontend-deployment
```

### Supprimer tous les déploiements

```bash
kubectl delete -f kubernetes/

# Ou supprimer individuellement
kubectl delete deployment product-deployment
kubectl delete service product-service
# etc...
```

---

## Troubleshooting

### Problème: Les pods ne démarrent pas

```bash
# Voir les détails
kubectl describe pod <pod-name>

# Voir les logs
kubectl logs <pod-name>

# Vérifier les events
kubectl get events --sort-by='.lastTimestamp'
```

### Problème: La base de données n'est pas accessible

```bash
# Vérifier que PostgreSQL tourne
kubectl get pods -l app=postgres

# Vérifier les logs PostgreSQL
kubectl logs <postgres-pod>

# Tester la connexion
kubectl exec -it <postgres-pod> -- psql -U ecommerce_user -d ecommerce_db -c "\dt"
```

### Problème: L'Ingress ne fonctionne pas

```bash
# Vérifier l'Ingress Controller
kubectl get pods -n ingress-nginx

# Vérifier l'Ingress
kubectl describe ingress ecommerce-ingress

# Vérifier les logs de l'Ingress Controller
kubectl logs -n ingress-nginx <ingress-nginx-controller-pod>
```

### Problème: Les services ne se communiquent pas

```bash
# Vérifier les services
kubectl get services

# Tester depuis un pod
kubectl exec -it <order-service-pod> -- wget -O- http://product-service:8000/health
```

---

## Tests des APIs

### Product Service

```bash
# Liste des produits
curl http://ecommerce.local/api/products/products/

# Créer un produit
curl -X POST http://ecommerce.local/api/products/products/ \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "description": "Description du produit",
    "price": 99.99,
    "stock": 10
  }'

# Récupérer un produit
curl http://ecommerce.local/api/products/products/1
```

### Order Service

```bash
# Liste des commandes
curl http://ecommerce.local/api/orders/orders/

# Créer une commande
curl -X POST http://ecommerce.local/api/orders/orders/ \
  -H "Content-Type: application/json" \
  -d '{
    "customer_name": "John Doe",
    "customer_email": "john@example.com",
    "items": [
      {"product_id": 1, "quantity": 2}
    ]
  }'
```

---

## Checklist de Déploiement

- [ ] Docker Desktop installé et lancé
- [ ] kubectl installé
- [ ] Compte Docker Hub créé
- [ ] Images Docker construites
- [ ] Images Docker publiées
- [ ] Manifests Kubernetes mis à jour avec votre username
- [ ] Nginx Ingress Controller installé
- [ ] Base de données PostgreSQL déployée
- [ ] Services backend déployés
- [ ] Frontend déployé
- [ ] Ingress configuré
- [ ] Fichier hosts modifié
- [ ] Application accessible sur http://ecommerce.local
- [ ] Tous les pods sont en status Running
- [ ] Tests des APIs effectués
- [ ] Interface web testée

---

## Captures d'écran à Prendre

Pour le rapport RAPPORT.md:

1. Construction des images Docker
2. Publication sur Docker Hub
3. Images sur Docker Hub
4. Installation Nginx Ingress
5. Déploiement PostgreSQL
6. Déploiement des services
7. `kubectl get all`
8. `kubectl get ingress`
9. Interface - Liste des produits
10. Interface - Ajout de produit
11. Interface - Panier
12. Interface - Commande
13. Interface - Historique
14. Test API Product Service
15. Test API Order Service
16. Réplication des services
17. Scaling manuel
18. Base de données
19. Logs communication inter-services
20. DevTools montrant les requêtes

---

Bonne chance avec votre déploiement!
