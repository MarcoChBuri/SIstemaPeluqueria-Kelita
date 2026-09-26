const express = require('express');
const cors = require('cors');
const path = require('path');
const routes = require('../src/routes');

const app = express();

// --- Middleware global ---
app.use(cors());
app.use(express.json());

// --- Servir archivos estáticos (Frontend) ---
const fs = require('fs');
const frontDist = path.join(__dirname, '../front/dist');
const publicDir = path.join(__dirname, '../public');
const staticDir = fs.existsSync(path.join(frontDist, 'index.html')) ? frontDist : publicDir;

app.use(express.static(staticDir));

// --- Rutas de la API ---
app.use('/api', routes);

// --- Health check ---
app.get('/api/health', (_req, res) => {
  res.json({ ok: true, mensaje: 'API de Peluquería Raquel funcionando 🚀' });
});

// --- Fallback para Frontend ---
app.get('*', (req, res, next) => {
  if (req.path.startsWith('/api')) {
    return next();
  }
  const indexPath = path.join(staticDir, 'index.html');
  if (fs.existsSync(indexPath)) {
    return res.sendFile(indexPath);
  }
  res.sendFile(path.join(publicDir, 'index.html'));
});

// --- 404 para API ---
app.use((_req, res) => {
  res.status(404).json({
    ok: false,
    error: 'Ruta no encontrada en la API.',
  });
});

// --- Exportar para Vercel Serverless ---
module.exports = app;
