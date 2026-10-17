/// Utilidades para formateo de números de teléfono de Ecuador para WhatsApp.
String formatEcuadorPhone(String rawPhone) {
  String clean = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (clean.isEmpty) return clean;
  
  if (clean.startsWith('+')) {
    clean = clean.substring(1);
  }

  // Si empieza con 5930... quitar el 0 redundante (ej. 593099... -> 59399...)
  if (clean.startsWith('5930')) {
    clean = '593${clean.substring(4)}';
  } else if (clean.startsWith('0')) {
    // Si empieza con 0 (ej. 0991234567), quitar el 0 inicial y poner 593
    clean = '593${clean.substring(1)}';
  } else if (!clean.startsWith('593')) {
    // Agregar código de país 593 de Ecuador
    clean = '593$clean';
  }
  return clean;
}
