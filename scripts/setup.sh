#!/bin/bash
# Script setup UGF Industrie

mkdir -p src/app/\(auth\)/login src/app/\(auth\)/register
mkdir -p src/app/\(shop\)/catalogue src/app/\(shop\)/panier src/app/\(shop\)/checkout
mkdir -p src/app/admin/produits src/app/admin/commandes src/app/admin/clients
mkdir -p src/app/compte/commandes src/app/compte/profil
mkdir -p src/app/api/stripe src/app/api/products src/app/api/orders
mkdir -p src/components/ui src/components/products src/components/cart src/components/admin
mkdir -p public/images docs

echo "Structure OK!"
