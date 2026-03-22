# INFINITY ERP - Foundation

ERP modulaire pour PME développé par TOURNESOL1 - Équipe TMUX

## Architecture

- **Backend**: FastAPI + PostgreSQL
- **Frontend**: Next.js + React + Material-UI
- **Containerisation**: Docker + Docker Compose

## Fonctionnalités Implémentées

### ✅ Task 282: Setup Architecture
- Docker Compose avec PostgreSQL, FastAPI et React
- Base de données avec schéma utilisateurs, clients, fournisseurs
- API REST complète avec authentification JWT

### ✅ Task 283: Système d'Authentification Multi-rôles
- JWT avec rôles: admin, manager, employee, accountant
- Middleware d'autorisation FastAPI
- Interface de connexion React avec gestion des sessions

### ✅ Task 284: CRUD Clients/Fournisseurs + Import CSV
- CRUD complet clients et fournisseurs
- Import CSV avec validation et traitement par lots
- Interface React avec tableaux et formulaires

## Démarrage Rapide

```bash
# Lancer l'environnement complet
cd infinity_erp
docker-compose up --build

# URLs d'accès
Frontend: http://localhost:3000
Backend API: http://localhost:8000
Database: postgresql://localhost:5432/infinity_erp
```

## Comptes de Test

- **Admin**: admin@infinity-erp.com / password
- **Manager**: manager@infinity-erp.com / password
- **Employee**: employee@infinity-erp.com / password

## API Endpoints

### Authentification
- POST `/auth/login` - Connexion
- POST `/auth/register` - Inscription
- GET `/auth/me` - Profil utilisateur

### Clients
- GET `/clients` - Liste des clients
- POST `/clients` - Créer un client
- PUT `/clients/{id}` - Modifier un client
- DELETE `/clients/{id}` - Supprimer un client
- POST `/clients/import-csv` - Import CSV

### Fournisseurs
- GET `/suppliers` - Liste des fournisseurs
- POST `/suppliers` - Créer un fournisseur
- POST `/suppliers/import-csv` - Import CSV

## Stack Technique

- **FastAPI 0.104** - Framework API moderne
- **PostgreSQL 15** - Base de données relationnelle
- **SQLAlchemy 2.0** - ORM Python
- **Next.js 14** - Framework React
- **Material-UI 5** - Composants UI
- **React Query** - Gestion d'état serveur
- **Docker** - Containerisation

## Sécurité

- Hachage des mots de passe avec bcrypt
- JWT avec expiration
- CORS configuré
- Validation des données Pydantic
- Rôles et permissions

## Prochaines Étapes

1. Module Facturation
2. Gestion des stocks
3. Rapports et analytics
4. Module comptabilité
5. API mobile

---

**Développé par TOURNESOL1 - Équipe TMUX**
Foundation ERP prête pour extensions modulaires