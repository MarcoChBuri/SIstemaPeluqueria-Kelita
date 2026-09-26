/**
 * Servidor local de desarrollo.
 * En producción (Vercel), se usa api/index.js directamente.
 *
 * Uso: node server.js
 */

require('dotenv').config();

const app = require('./api');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`\n🚀 API de Peluquería Raquel corriendo en http://localhost:${PORT}`);
  console.log(`   Health check: http://localhost:${PORT}/api/health\n`);
});
