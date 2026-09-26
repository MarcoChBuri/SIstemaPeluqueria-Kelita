require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const rawUrl = process.env.SUPABASE_URL || 'https://placeholder-raquel.supabase.co';
const supabaseUrl = rawUrl.replace(/\/rest\/v1\/?$/, '').replace(/\/$/, '');
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'placeholder-key';

if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
  console.warn(
    '⚠️ [AVISO] Faltan las variables SUPABASE_URL y/o SUPABASE_SERVICE_ROLE_KEY en el archivo .env.\n' +
    '   La API arrancará en modo desarrollo. Agrega tus credenciales reales de Supabase para guardar datos en la nube.'
  );
}

const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: { persistSession: false },
});

module.exports = { supabase };
