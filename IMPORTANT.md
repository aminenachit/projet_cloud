# Important - Configuration Locale

## Problème de Port Résolu

Le port 80 était déjà utilisé par un autre service sur votre système Windows (Apache2/IIS).

**Solution appliquée:** Le frontend a été déplacé sur le port 3000.

---

## Accès à l'Application (Docker Compose)

### Frontend
**URL:** http://localhost:3000

### APIs
- **Product Service:** http://localhost:8000
- **Product API Docs:** http://localhost:8000/docs
- **Order Service:** http://localhost:8001
- **Order API Docs:** http://localhost:8001/docs

### Base de données
- **PostgreSQL:** localhost:5432
  - Database: ecommerce_db
  - User: ecommerce_user
  - Password: ecommerce_pass

---

## Test Rapide

```bash
# Frontend React
curl http://localhost:3000

# Product Service
curl http://localhost:8000/products/

# Order Service
curl http://localhost:8001/orders/
```

---

## Captures d'écran pour le Rapport

Lors de vos captures d'écran, utilisez:
- **Frontend:** http://localhost:3000
- **APIs:** http://localhost:8000 et http://localhost:8001

---

## Déploiement Kubernetes

Pour le déploiement Kubernetes, le port 80 sera utilisé via l'Ingress (pas de conflit car isolé dans le cluster).

URL finale Kubernetes: http://ecommerce.local

---

## Commandes Utiles

```bash
# Démarrer
docker-compose up -d

# Arrêter
docker-compose down

# Voir les logs
docker-compose logs -f

# Statut
docker-compose ps

# Reconstruire une image
docker-compose build --no-cache frontend
```

---

## Note

Ce changement de port est uniquement pour le test local avec Docker Compose.
Le déploiement Kubernetes utilisera le port 80 normalement via l'Ingress.
