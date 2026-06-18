-- ============================================================
-- UGF Industrie - Schema PostgreSQL
-- Version: 1.0.0
-- Description: Schema complet pour la plateforme e-commerce B2B
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- ============================================================
-- TYPES ENUMERES
-- ============================================================

CREATE TYPE user_status AS ENUM ('pending', 'active', 'suspended', 'deleted');
CREATE TYPE order_status AS ENUM ('pending', 'paid', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded');
CREATE TYPE quote_status AS ENUM ('draft', 'pending', 'sent', 'accepted', 'refused', 'expired');
CREATE TYPE payment_method AS ENUM ('card', 'bank_transfer', 'check');

-- ============================================================
-- TABLE: users (Clients B2B)
-- ============================================================

CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name    VARCHAR(100) NOT NULL,
    last_name     VARCHAR(100) NOT NULL,
    phone         VARCHAR(20),
    status        user_status NOT NULL DEFAULT 'pending',
    email_verified BOOLEAN DEFAULT FALSE,
    email_verified_at TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);

-- ============================================================
-- TABLE: companies (Entreprises B2B)
-- ============================================================

CREATE TABLE companies (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    company_name  VARCHAR(255) NOT NULL,
    siret         VARCHAR(14) UNIQUE,
    vat_number    VARCHAR(20),
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    postal_code   VARCHAR(10) NOT NULL,
    city          VARCHAR(100) NOT NULL,
    country       VARCHAR(2) NOT NULL DEFAULT 'FR',
    website       VARCHAR(255),
    industry      VARCHAR(100),
    employee_count VARCHAR(20),
    validated_at  TIMESTAMPTZ,
    validated_by  UUID,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );

CREATE INDEX idx_companies_user_id ON companies(user_id);
CREATE INDEX idx_companies_siret ON companies(siret);

-- ============================================================
-- TABLE: categories
-- ============================================================

CREATE TABLE categories (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(100) NOT NULL,
    slug        VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_id   UUID REFERENCES categories(id) ON DELETE SET NULL,
    image_url   VARCHAR(500),
    sort_order  INTEGER DEFAULT 0,
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );

CREATE INDEX idx_categories_slug ON categories(slug);
CREATE INDEX idx_categories_parent ON categories(parent_id);

-- ============================================================
-- TABLE: brands (Marques)
-- ============================================================

CREATE TABLE brands (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(100) NOT NULL UNIQUE,
    slug        VARCHAR(100) NOT NULL UNIQUE,
    logo_url    VARCHAR(500),
    website     VARCHAR(255),
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );

-- ============================================================
-- TABLE: products (Produits)
-- ============================================================

CREATE TABLE products (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sku             VARCHAR(50) NOT NULL UNIQUE,
    name            VARCHAR(255) NOT NULL,
    slug            VARCHAR(255) NOT NULL UNIQUE,
    description     TEXT,
    short_desc      VARCHAR(500),
    category_id     UUID REFERENCES categories(id) ON DELETE SET NULL,
    brand_id        UUID REFERENCES brands(id) ON DELETE SET NULL,
    price_ht        DECIMAL(10, 2) NOT NULL CHECK (price_ht >= 0),
    price_ttc       DECIMAL(10, 2) GENERATED ALWAYS AS (ROUND(price_ht * 1.20, 2)) STORED,
    tax_rate        DECIMAL(5, 2) NOT NULL DEFAULT 20.00,
    stock_quantity  INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    stock_threshold INTEGER NOT NULL DEFAULT 5,
    weight_kg       DECIMAL(8, 3),
    dimensions_cm   JSONB,
    images          TEXT[] DEFAULT '{}',
    specifications  JSONB DEFAULT '{}',
    tags            TEXT[] DEFAULT '{}',
    is_active       BOOLEAN DEFAULT TRUE,
    is_featured     BOOLEAN DEFAULT FALSE,
    meta_title      VARCHAR(255),
    meta_desc       VARCHAR(500),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );

CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_slug ON products(slug);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand ON products(brand_id);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_products_price ON products(price_ht);
CREATE INDEX idx_products_stock ON products(stock_quantity);
CREATE INDEX idx_products_search ON products USING GIN(to_tsvector('french', name || ' ' || COALESCE(description, '') || ' ' || sku));

-- ============================================================
-- TABLE: orders (Commandes)
-- ============================================================

CREATE TABLE orders (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number        VARCHAR(20) NOT NULL UNIQUE,
    user_id             UUID NOT NULL REFERENCES users(id),
    company_id          UUID REFERENCES companies(id),
    status              order_status NOT NULL DEFAULT 'pending',
    subtotal_ht         DECIMAL(10, 2) NOT NULL DEFAULT 0,
    tax_amount          DECIMAL(10, 2) NOT NULL DEFAULT 0,
    shipping_amount     DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_ttc           DECIMAL(10, 2) NOT NULL DEFAULT 0,
    currency            VARCHAR(3) NOT NULL DEFAULT 'EUR',
    payment_method      payment_method,
    stripe_payment_id   VARCHAR(255),
    stripe_session_id   VARCHAR(255),
    shipping_address    JSONB NOT NULL,
    billing_address     JSONB NOT NULL,
    notes               TEXT,
    shipped_at          TIMESTAMPTZ,
    delivered_at        TIMESTAMPTZ,
    cancelled_at        TIMESTAMPTZ,
    cancel_reason       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );

CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_number ON orders(order_number);
CREATE INDEX idx_orders_stripe ON orders(stripe_payment_id);
CREATE INDEX idx_orders_created ON orders(created_at DESC);

-- ============================================================
-- TABLE: order_items (Lignes de commande)
-- ============================================================

CREATE TABLE order_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id        UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES products(id),
    product_sku     VARCHAR(50) NOT NULL,
    product_name    VARCHAR(255) NOT NULL,
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_ht   DECIMAL(10, 2) NOT NULL,
    tax_rate        DECIMAL(5, 2) NOT NULL DEFAULT 20.00,
    line_total_ht   DECIMAL(10, 2) NOT NULL,
    line_total_ttc  DECIMAL(10, 2) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- ============================================================
-- TABLE: quotes (Devis)
-- ============================================================

CREATE TABLE quotes (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quote_number    VARCHAR(20) NOT NULL UNIQUE,
    user_id         UUID NOT NULL REFERENCES users(id),
    company_id      UUID REFERENCES companies(id),
    status          quote_status NOT NULL DEFAULT 'draft',
    subtotal_ht     DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_ttc       DECIMAL(10, 2) NOT NULL DEFAULT 0,
    discount_pct    DECIMAL(5, 2) DEFAULT 0,
    notes           TEXT,
    admin_notes     TEXT,
    valid_until     DATE,
    converted_order_id UUID REFERENCES orders(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );

CREATE INDEX idx_quotes_user ON quotes(user_id);
CREATE INDEX idx_quotes_status ON quotes(status);

-- ============================================================
-- TABLE: quote_items (Lignes de devis)
-- ============================================================

CREATE TABLE quote_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quote_id        UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES products(id),
    product_sku     VARCHAR(50) NOT NULL,
    product_name    VARCHAR(255) NOT NULL,
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_ht   DECIMAL(10, 2) NOT NULL,
    line_total_ht   DECIMAL(10, 2) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );

-- ============================================================
-- TABLE: cart (Paniers)
-- ============================================================

CREATE TABLE cart (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id  UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity    INTEGER NOT NULL CHECK (quantity > 0),
    added_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, product_id)
  );

CREATE INDEX idx_cart_user ON cart(user_id);

-- ============================================================
-- TABLE: admin_users (Admins)
-- ============================================================

CREATE TABLE admin_users (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name    VARCHAR(100) NOT NULL,
    last_name     VARCHAR(100) NOT NULL,
    role          VARCHAR(50) NOT NULL DEFAULT 'admin',
    is_active     BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );

-- ============================================================
-- FUNCTION: update_updated_at()
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers updated_at
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_companies_updated_at BEFORE UPDATE ON companies FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_quotes_updated_at BEFORE UPDATE ON quotes FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- FUNCTION: generate_order_number()
-- ============================================================

CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS VARCHAR AS $$
BEGIN
  RETURN 'ORD-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(NEXTVAL('order_seq')::TEXT, 5, '0');
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS order_seq START 1;
CREATE SEQUENCE IF NOT EXISTS quote_seq START 1;

-- ============================================================
-- DONNEES INITIALES
-- ============================================================

-- Categories principales
INSERT INTO categories (name, slug, sort_order) VALUES
  ('Hydraulique', 'hydraulique', 1),
  ('Pneumatique', 'pneumatique', 2),
  ('Transmission', 'transmission', 3),
  ('Electronique industrielle', 'electronique', 4),
  ('Visserie & Fixations', 'visserie', 5),
  ('Outillage', 'outillage', 6),
  ('Lubrifiants', 'lubrifiants', 7),
  ('Etancheite', 'etancheite', 8)
ON CONFLICT (slug) DO NOTHING;

-- Admin par defaut (mot de passe: ChangeMeNow123!)
-- ATTENTION: Changer imperativement en production
INSERT INTO admin_users (email, password_hash, first_name, last_name, role)
VALUES ('admin@ugf-industrie.fr', crypt('ChangeMeNow123!', gen_salt('bf', 12)), 'Admin', 'UGF', 'superadmin')
ON CONFLICT (email) DO NOTHING;
