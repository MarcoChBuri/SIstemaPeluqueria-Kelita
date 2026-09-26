/**
 * ═══════════════════════════════════════════════════════════════════════════
 * CONFIGURACIÓN CENTRAL DEL NEGOCIO / PELUQUERÍA
 * ═══════════════════════════════════════════════════════════════════════════
 * Edita este archivo para personalizar fácilmente el sistema para cualquier
 * peluquería o centro de belleza sin tocar el código fuente.
 */

export const SALON_CONFIG = {
  // Nombre comercial de la peluquería
  nombre: 'Peluquería Raquel',
  nombreCorto: 'Raquel',
  letraLogo: 'R',
  eslogan: 'Belleza & Estilo Profesional',
  duena: 'Raquel',

  // Número de WhatsApp principal (pon aquí el número de la peluquería)
  whatsappNumber: '968737579',
  
  // Código de país telefónico (+593 para Ecuador)
  codigoPais: '593',

  // Moneda
  monedaSimbolo: '$',

  // Horarios de atención
  horarios: {
    lunesViernes: '9:00 AM - 7:00 PM',
    sabados: '9:00 AM - 5:00 PM',
    domingos: 'Cerrado',
  },

  // Ubicación y Contacto
  direccion: 'Atención en salón y a domicilio',
  ciudad: 'Guayaquil / Lima',

  // Redes Sociales
  instagramUrl: 'https://instagram.com',
  facebookUrl: 'https://facebook.com',
};

/**
 * Función auxiliar para generar el enlace directo a WhatsApp con mensaje pre-llenado.
 */
export const buildWhatsAppUrl = (mensaje: string): string => {
  let cleanNumber = SALON_CONFIG.whatsappNumber.replace(/\D/g, '');
  
  // Si el número tiene 9 dígitos (formato celular típico), le anteponemos el código de país
  if (cleanNumber.length === 9) {
    cleanNumber = `${SALON_CONFIG.codigoPais}${cleanNumber}`;
  }

  return `https://wa.me/${cleanNumber}?text=${encodeURIComponent(mensaje)}`;
};
