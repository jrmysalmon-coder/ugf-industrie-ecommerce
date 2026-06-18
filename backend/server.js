'use strict';

/**
 * UGF Industrie - Backend Express Server
  * Application e-commerce B2B
   */

   const express = require('express');
   const cors = require('cors');
   const helmet = require('helmet');
   const morgan = require('morgan');
   const compression = require('compression');
   const rateLimit = require('express-rate-limit');
   const path = require('path');
   require('dotenv').config();

   // --- App Init ---
   const app = express();
   const PORT = process.env.PORT || 3001;
   const NODE_ENV = process.env.NODE_ENV || 'development';

   // --- Security Middleware ---
   app.use(helmet({
     contentSecurityPolicy: {
         directives: {
               defaultSrc: ["'self'"],
                     scriptSrc: ["'self'", "'unsafe-inline'", "https://js.stripe.com"],
                           styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
                                 fontSrc: ["'self'", "https://fonts.gstatic.com"],
                                       imgSrc: ["'self'", "data:", "https:"],
                                             connectSrc: ["'self'", "https://api.stripe.com"],
                                                   frameSrc: ["https://js.stripe.com"],
                                                       },
                                                         },
                                                         }));

                                                         // --- Rate Limiting ---
                                                         const limiter = rateLimit({
                                                           windowMs: 15 * 60 * 1000, // 15 minutes
                                                             max: 100,
                                                               standardHeaders: true,
                                                                 legacyHeaders: false,
                                                                   message: { error: 'Trop de requetes, reessayez dans 15 minutes.' },
                                                                   });

                                                                   const authLimiter = rateLimit({
                                                                     windowMs: 15 * 60 * 1000,
                                                                       max: 10,
                                                                         message: { error: 'Trop de tentatives de connexion.' },
                                                                         });

                                                                         app.use('/api/', limiter);

                                                                         // --- CORS ---
                                                                         const corsOptions = {
                                                                           origin: process.env.FRONTEND_URL || 'http://localhost:3000',
                                                                             credentials: true,
                                                                               methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
                                                                                 allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
                                                                                 };
                                                                                 app.use(cors(corsOptions));

                                                                                 // --- Body Parsing ---
                                                                                 app.use(express.json({ limit: '10mb' }));
                                                                                 app.use(express.urlencoded({ extended: true, limit: '10mb' }));

                                                                                 // --- Compression ---
                                                                                 app.use(compression());

                                                                                 // --- Logging ---
                                                                                 if (NODE_ENV !== 'test') {
                                                                                   app.use(morgan(NODE_ENV === 'production' ? 'combined' : 'dev'));
                                                                                   }

                                                                                   // --- Static Files ---
                                                                                   app.use('/public', express.static(path.join(__dirname, '../public'), {
                                                                                     maxAge: NODE_ENV === 'production' ? '1d' : 0,
                                                                                     }));

                                                                                     // --- Routes ---
                                                                                     const authRoutes = require('./routes/auth');
                                                                                     const productRoutes = require('./routes/products');
                                                                                     const orderRoutes = require('./routes/orders');
                                                                                     const quoteRoutes = require('./routes/quotes');
                                                                                     const userRoutes = require('./routes/users');
                                                                                     const adminRoutes = require('./routes/admin');
                                                                                     const stripeRoutes = require('./routes/stripe');

                                                                                     // Auth
                                                                                     app.use('/api/v1/auth', authLimiter, authRoutes);

                                                                                     // Resources
                                                                                     app.use('/api/v1/products', productRoutes);
                                                                                     app.use('/api/v1/orders', orderRoutes);
                                                                                     app.use('/api/v1/quotes', quoteRoutes);
                                                                                     app.use('/api/v1/users', userRoutes);
                                                                                     app.use('/api/v1/admin', adminRoutes);

                                                                                     // Stripe Webhooks (raw body required)
                                                                                     app.use('/api/v1/stripe', express.raw({ type: 'application/json' }), stripeRoutes);

                                                                                     // --- Health Check ---
                                                                                     app.get('/health', (req, res) => {
                                                                                       res.status(200).json({
                                                                                           status: 'ok',
                                                                                               environment: NODE_ENV,
                                                                                                   timestamp: new Date().toISOString(),
                                                                                                       version: process.env.npm_package_version || '0.1.0',
                                                                                                         });
                                                                                                         });
                                                                                                         
                                                                                                         // --- API Info ---
                                                                                                         app.get('/api/v1', (req, res) => {
                                                                                                           res.json({
                                                                                                               name: 'UGF Industrie API',
                                                                                                                   version: 'v1',
                                                                                                                       status: 'running',
                                                                                                                           endpoints: {
                                                                                                                                 auth: '/api/v1/auth',
                                                                                                                                       products: '/api/v1/products',
                                                                                                                                             orders: '/api/v1/orders',
                                                                                                                                                   quotes: '/api/v1/quotes',
                                                                                                                                                         users: '/api/v1/users',
                                                                                                                                                               admin: '/api/v1/admin',
                                                                                                                                                                   },
                                                                                                                                                                     });
                                                                                                                                                                     });
                                                                                                                                                                     
                                                                                                                                                                     // --- 404 Handler ---
                                                                                                                                                                     app.use((req, res) => {
                                                                                                                                                                       res.status(404).json({
                                                                                                                                                                           error: 'Route non trouvee',
                                                                                                                                                                               code: 'NOT_FOUND',
                                                                                                                                                                                   path: req.originalUrl,
                                                                                                                                                                                     });
                                                                                                                                                                                     });
                                                                                                                                                                                     
                                                                                                                                                                                     // --- Global Error Handler ---
                                                                                                                                                                                     app.use((err, req, res, next) => {
                                                                                                                                                                                       const status = err.status || err.statusCode || 500;
                                                                                                                                                                                         const message = err.message || 'Erreur interne du serveur';
                                                                                                                                                                                         
                                                                                                                                                                                           if (NODE_ENV !== 'production') {
                                                                                                                                                                                               console.error('[ERROR]', err.stack);
                                                                                                                                                                                                 }
                                                                                                                                                                                                 
                                                                                                                                                                                                   res.status(status).json({
                                                                                                                                                                                                       error: message,
                                                                                                                                                                                                           code: err.code || 'INTERNAL_ERROR',
                                                                                                                                                                                                               ...(NODE_ENV !== 'production' && { stack: err.stack }),
                                                                                                                                                                                                                 });
                                                                                                                                                                                                                 });
                                                                                                                                                                                                                 
                                                                                                                                                                                                                 // --- Start Server ---
                                                                                                                                                                                                                 const server = app.listen(PORT, () => {
                                                                                                                                                                                                                   console.log(`[UGF Industrie] Serveur ${NODE_ENV} demarre sur http://localhost:${PORT}`);
                                                                                                                                                                                                                     console.log(`[UGF Industrie] API disponible sur http://localhost:${PORT}/api/v1`);
                                                                                                                                                                                                                     });
                                                                                                                                                                                                                     
                                                                                                                                                                                                                     // Graceful Shutdown
                                                                                                                                                                                                                     process.on('SIGTERM', () => {
                                                                                                                                                                                                                       console.log('[UGF Industrie] SIGTERM recu. Arret gracieux...');
                                                                                                                                                                                                                         server.close(() => {
                                                                                                                                                                                                                             console.log('[UGF Industrie] Serveur arrete.');
                                                                                                                                                                                                                                 process.exit(0);
                                                                                                                                                                                                                                   });
                                                                                                                                                                                                                                   });
                                                                                                                                                                                                                                   
                                                                                                                                                                                                                                   process.on('unhandledRejection', (reason, promise) => {
                                                                                                                                                                                                                                     console.error('[UGF Industrie] Unhandled Rejection:', reason);
                                                                                                                                                                                                                                     });
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     module.exports = app;
