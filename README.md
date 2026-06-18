# UGF Industrie - Plateforme E-commerce B2B

Plateforme e-commerce B2B complète pour UGF Industrie, spécialisée dans la vente de pièces industrielles et équipements.

## Stack Technique

- **Frontend**: Next.js 14 (App Router), TypeScript, Tailwind CSS
- **Backend**: Next.js API Routes, Supabase (PostgreSQL)
- **Paiement**: Stripe (paiement immédiat + devis)
- **Auth**: Supabase Auth (clients B2B avec validation)
- **Déploiement**: Vercel

## Fonctionnalités

- Catalogue produits avec filtres avancés (référence, catégorie, marque)
- Gestion des comptes clients B2B (validation manuelle)
- Panier et commandes avec historique
- Système de devis pour grandes quantités
- Interface admin pour gestion produits/commandes
- Import CSV/Excel pour catalogue produits

## Installation

```bash
# Cloner le repo
git clone https://github.com/jrmysalmon-coder/ugf-industrie-ecommerce.git
cd ugf-industrie-ecommerce

# Installer les dépendances
npm install

# Configurer les variables d'environnement
cp .env.example .env.local

# Lancer en développement
npm run dev
```

## Structure du Projet

```
ugf-industrie-ecommerce/
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── (auth)/             # Pages auth (login, register)
│   │   ├── (shop)/             # Pages boutique
│   │   ├── admin/              # Interface admin
│   │   └── api/                # API Routes
│   ├── components/             # Composants React
│   │   ├── ui/                 # Composants UI génériques
│   │   ├── products/           # Composants produits
│   │   ├── cart/               # Composants panier
│   │   └── admin/              # Composants admin
│   ├── lib/                    # Utilitaires et configs
│   │   ├── supabase/           # Client Supabase
│   │   ├── stripe/             # Config Stripe
│   │   └── utils/              # Fonctions utilitaires
│   ├── types/                  # Types TypeScript
│   └── styles/                 # Styles globaux
├── public/                     # Assets statiques
├── docs/                       # Documentation
└── scripts/                    # Scripts utilitaires
```

## Variables d'Environnement

Voir `.env.example` pour la liste complète des variables requises.

## Déploiement

Le projet est configuré pour Vercel. Voir `vercel.json` pour la configuration.

## Licence

Propriétaire - UGF Industrie © 2024
