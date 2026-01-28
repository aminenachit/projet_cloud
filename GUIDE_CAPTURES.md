# Guide des Captures d'Écran - 12 Captures

## Docker (2 captures)

### CAPTURE 1: Construction et Publication
**Terminal montrant:**
```bash
docker build -t username/product-service:latest ./product-service
docker push username/product-service:latest
# (répéter pour les 3 services)
```

### CAPTURE 2: Docker Hub
**Navigateur sur Docker Hub montrant les 3 images publiées**

---

## Kubernetes (3 captures)

### CAPTURE 3: Installation Ingress
**Terminal:**
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

### CAPTURE 4: Vue d'ensemble
**Terminal montrant tous les pods running:**
```bash
kubectl get all
# Doit montrer:
# - 2 pods product-service
# - 2 pods order-service
# - 2 pods frontend
# - 1 pod postgres
# - Tous les services
```

### CAPTURE 5: Ingress Configuré
**Terminal:**
```bash
kubectl get ingress
kubectl describe ingress ecommerce-ingress
```

---

## Application Frontend (5 captures)

### CAPTURE 6: Page d'Accueil
**Navigateur sur http://localhost:3000 ou http://ecommerce.local**
- Liste des 5 produits avec prix et stocks
- Interface complète visible

### CAPTURE 7: Ajout de Produit
**Onglet "Ajouter Produit"**
- Formulaire rempli avec:
  - Nom: "Nouveau Produit"
  - Description: "Description test"
  - Prix: 149.99
  - Stock: 20

### CAPTURE 8: Panier
**Onglet "Panier" avec des articles**
- Au moins 2 produits dans le panier
- Quantités visibles
- Total calculé

### CAPTURE 9: Création Commande
**Formulaire de commande rempli:**
- Nom client: "Test User"
- Email: "test@example.com"
- Articles dans le panier visibles

### CAPTURE 10: Historique Commandes
**Onglet "Commandes"**
- Au moins 1 commande visible
- Détails de la commande (items, total, statut)

---

## Tests APIs et Communication (2 captures)

### CAPTURE 11: Tests APIs
**Postman ou Terminal avec curl:**

**Partie 1 - GET Products:**
```bash
curl http://localhost:3000/api/products/products/
# ou
curl http://ecommerce.local/api/products/products/
```
Réponse JSON avec liste des produits

**Partie 2 - POST Order:**
```bash
curl -X POST http://localhost:3000/api/orders/orders/ \
  -H "Content-Type: application/json" \
  -d '{"customer_name":"Test","customer_email":"test@test.com","items":[{"product_id":1,"quantity":2}]}'
```
Réponse JSON avec commande créée

### CAPTURE 12: Réplication et Communication
**Terminal - Split screen ou 2 commandes:**

**Partie 1 - Réplication:**
```bash
kubectl get pods -o wide
# Montre les 2 réplicas de chaque service
```

**Partie 2 - Logs Communication:**
```bash
kubectl logs <order-service-pod> --tail=20
# Montre les requêtes HTTP vers product-service
```

---

## Conseils

1. **Qualité:** Captures en pleine résolution, texte lisible
2. **Contenu:** Montrez les informations importantes (pas de zones vides)
3. **Organisation:** Nommez vos fichiers: `capture-01.png`, `capture-02.png`, etc.
4. **Annotations:** Vous pouvez ajouter des flèches/textes pour mettre en évidence des éléments importants

---

## Commandes de Test Rapides

### Test Local (Docker Compose)
```bash
# Démarrer
docker-compose up -d

# Vérifier
docker-compose ps

# URLs
# Frontend: http://localhost:3000
# Product API: http://localhost:8000/docs
# Order API: http://localhost:8001/docs
```

### Test Kubernetes
```bash
# Déployer
kubectl apply -f kubernetes/

# Vérifier
kubectl get all
kubectl get ingress

# URL
# http://ecommerce.local (après ajout au fichier hosts)
```

---

## Ordre Recommandé

1. Commencez par **Docker** (captures 1-2)
2. Puis **Kubernetes** (captures 3-5)
3. Ensuite **Frontend** (captures 6-10)
4. Enfin **APIs/Communication** (captures 11-12)

Cela suit l'ordre logique du déploiement et du test de l'application.
