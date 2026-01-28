@echo off
REM Script de déploiement pour Windows
REM Usage: deploy.bat [action]

setlocal enabledelayedexpansion

REM Configuration
set "DOCKER_USERNAME=your-dockerhub-username"
if not "%DOCKER_USERNAME_ENV%"=="" set "DOCKER_USERNAME=%DOCKER_USERNAME_ENV%"

if "%1"=="" (
    goto :usage
)

if "%1"=="build" goto :build
if "%1"=="push" goto :push
if "%1"=="deploy" goto :deploy
if "%1"=="all" goto :all
if "%1"=="status" goto :status
if "%1"=="clean" goto :clean
goto :usage

:build
echo [INFO] Construction des images Docker...
docker build -t %DOCKER_USERNAME%/product-service:latest .\product-service
docker build -t %DOCKER_USERNAME%/order-service:latest .\order-service
docker build -t %DOCKER_USERNAME%/ecommerce-frontend:latest .\frontend
echo [SUCCESS] Images construites
goto :end

:push
echo [INFO] Publication des images sur Docker Hub...
if "%DOCKER_USERNAME%"=="your-dockerhub-username" (
    echo [ERROR] Veuillez définir DOCKER_USERNAME
    echo Exemple: set DOCKER_USERNAME_ENV=votre-username
    exit /b 1
)
docker login
docker push %DOCKER_USERNAME%/product-service:latest
docker push %DOCKER_USERNAME%/order-service:latest
docker push %DOCKER_USERNAME%/ecommerce-frontend:latest
echo [SUCCESS] Images publiées
goto :end

:deploy
echo [INFO] Installation de Nginx Ingress...
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

echo [INFO] Déploiement de PostgreSQL...
cd kubernetes
kubectl apply -f postgres-configmap.yaml
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

timeout /t 15 /nobreak

echo [INFO] Déploiement des services...
kubectl apply -f product-deployment.yaml
kubectl apply -f product-service.yaml
kubectl apply -f order-deployment.yaml
kubectl apply -f order-service.yaml

timeout /t 20 /nobreak

echo [INFO] Déploiement du frontend...
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml
kubectl apply -f ingress.yaml
cd ..

echo [SUCCESS] Déploiement terminé
goto :status

:all
call :build
call :push
call :deploy
goto :end

:status
echo [INFO] Statut du déploiement
echo.
echo === PODS ===
kubectl get pods
echo.
echo === SERVICES ===
kubectl get services
echo.
echo === DEPLOYMENTS ===
kubectl get deployments
echo.
echo === INGRESS ===
kubectl get ingress
echo.
echo [SUCCESS] Vérifiez que tous les pods sont Running
echo [WARNING] Ajoutez "127.0.0.1 ecommerce.local" à C:\Windows\System32\drivers\etc\hosts
echo [INFO] Accédez à http://ecommerce.local
goto :end

:clean
echo [WARNING] Suppression de tous les déploiements...
set /p confirm="Êtes-vous sûr? (y/N) "
if /i "%confirm%"=="y" (
    kubectl delete -f kubernetes\ --ignore-not-found=true
    echo [SUCCESS] Déploiement nettoyé
) else (
    echo [INFO] Nettoyage annulé
)
goto :end

:usage
echo Usage: %0 [action]
echo.
echo Actions disponibles:
echo   build   - Construire les images Docker
echo   push    - Publier les images sur Docker Hub
echo   deploy  - Déployer sur Kubernetes
echo   all     - Build + Push + Deploy
echo   status  - Afficher le statut
echo   clean   - Supprimer le déploiement
echo.
echo Exemple:
echo   set DOCKER_USERNAME_ENV=votre-username
echo   %0 all
exit /b 1

:end
endlocal
