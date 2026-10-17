/**
 * KELITA BURI - Frontend Interactivo (Sitio Web Público)
 */

// Estado Global de la App
let state = {
  servicios: [],
  paquetes: [],
  promociones: [],
  galeria: [],
  vistaActual: 'cliente',
  isRegistroMode: false,
};

// ==========================================
// INICIALIZACIÓN
// ==========================================
document.addEventListener('DOMContentLoaded', () => {
  inicializarFechas();
  cargarDatosPublicos();
  mostrarCookieBanner();
  if (
    window.location.hash === '#admin' ||
    window.location.pathname.includes('admin') ||
    window.location.pathname.includes('panel') ||
    window.location.search.includes('admin')
  ) {
    cambiarVista('admin');
  }
});

function inicializarFechas() {
  const hoy = new Date().toISOString().split('T')[0];
  const inputFechaCita = document.getElementById('reservaFecha');

  if (inputFechaCita) inputFechaCita.min = hoy;
  if (inputFechaCita) inputFechaCita.value = hoy;
}

// ==========================================
// NAVEGACIÓN (Solo cliente - Admin bloqueado)
// ==========================================
function cambiarVista(vista) {
  state.vistaActual = vista;
  const vistaCliente = document.getElementById('vistaCliente');
  const vistaAdmin = document.getElementById('vistaAdmin');

  if (vista === 'admin') {
    // Admin está bloqueado desde la web, mostrar página de acceso denegado
    vistaCliente.classList.remove('active');
    vistaAdmin.classList.add('active');
  } else {
    vistaAdmin.classList.remove('active');
    vistaCliente.classList.add('active');
    cargarDatosPublicos();
  }
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// ==========================================
// CARGA DE DATOS PÚBLICOS (API + Fallbacks)
// ==========================================
async function cargarDatosPublicos() {
  await Promise.allSettled([
    cargarServicios(),
    cargarPromociones(),
    cargarGaleria(),
  ]);
}

async function cargarServicios() {
  try {
    const res = await fetch('/api/servicios');
    const data = await res.json();
    if (data.ok && data.servicios?.length) {
      state.servicios = data.servicios;
      state.paquetes = data.paquetes_especiales || [];
    } else {
      usarServiciosDemo();
    }
  } catch {
    usarServiciosDemo();
  }
  renderizarServicios();
  renderizarPaquetes();
  poblarSelectServicios();
}

function usarServiciosDemo() {
  state.servicios = [
    { id: '1', nombre: 'Balayage & Colorimetría Premium', categoria: 'colorimetria', duracion_minutos: 180, precio_base: 85.00, descripcion: 'Diseño de color personalizado, decoloración y matiz con tratamiento hidratante.' },
    { id: '2', nombre: 'Corte de Cabello & Peinado Damas', categoria: 'corte', duracion_minutos: 45, precio_base: 15.00, descripcion: 'Lavado especial, asesoría de visagismo, corte y secado con ondas.' },
    { id: '3', nombre: 'Corte de Cabello Caballeros', categoria: 'corte', duracion_minutos: 30, precio_base: 8.00, descripcion: 'Degradado / clásico con lavado y perfilado.' },
    { id: '4', nombre: 'Alisado Orgánico Pro', categoria: 'tratamiento', duracion_minutos: 150, precio_base: 70.00, descripcion: 'Tratamiento sin formol que reestructura y alisa el cabello hasta por 4 meses.' },
    { id: '5', nombre: 'Lifting de Pestañas & Perfilado Cejas', categoria: 'pestanas_cejas', duracion_minutos: 60, precio_base: 25.00, descripcion: 'Curvatura natural de pestañas con keratina y diseño de cejas con tinte henna.' },
  ];
  state.paquetes = [
    { id: 'p1', nombre: 'Paquete Novia Radiante (Boda)', categoria: 'paquete_bodas', duracion_minutos: 240, precio_base: 150.00, descripcion: 'Prueba de peinado + peinado día del evento + maquillaje blindado con fijación 24h + colocación de velo y retoque.' },
    { id: 'p2', nombre: 'Paquete Quinceañera Encantada', categoria: 'paquete_quinceanera', duracion_minutos: 180, precio_base: 95.00, descripcion: 'Maquillaje profesional HD + peinado con corona/tocado + pestañas punto a punto.' },
  ];
}

function renderizarServicios(categoria = 'todos') {
  const contenedor = document.getElementById('gridServicios');
  if (!contenedor) return;

  const filtrados = categoria === 'todos'
    ? state.servicios.filter(s => s.categoria !== 'paquete_bodas' && s.categoria !== 'paquete_quinceanera')
    : state.servicios.filter(s => s.categoria === categoria);

  contenedor.innerHTML = filtrados.map(s => `
    <div class="servicio-item">
      <div class="servicio-info">
        <h4>${s.nombre}</h4>
        <p class="text-muted" style="font-size:0.86rem; margin-bottom:4px;">${s.descripcion || ''}</p>
        <span class="servicio-meta">⏱️ ${s.duracion_minutos} min</span>
      </div>
      <div class="servicio-precio-box">
        <span class="servicio-precio">$${Number(s.precio_base).toFixed(2)}</span>
        <button class="btn btn-outline btn-sm" onclick="abrirModalConServicio('${s.id}')">
          Reservar
        </button>
      </div>
    </div>
  `).join('');
}

function filtrarServicios(cat) {
  document.querySelectorAll('.btn-filtro').forEach(b => b.classList.remove('active'));
  const btn = Array.from(document.querySelectorAll('.btn-filtro')).find(b => b.getAttribute('onclick')?.includes(cat));
  if (btn) btn.classList.add('active');
  renderizarServicios(cat);
}

function renderizarPaquetes() {
  const contenedor = document.getElementById('gridPaquetes');
  if (!contenedor) return;

  contenedor.innerHTML = state.paquetes.map(p => `
    <div class="paquete-card">
      <div>
        <span class="paquete-badge">✨ Exclusivo Eventos</span>
        <h3 class="paquete-nombre">${p.nombre}</h3>
        <p class="paquete-desc">${p.descripcion || ''}</p>
      </div>
      <div>
        <div class="paquete-precio">$${Number(p.precio_base).toFixed(2)}</div>
        <button class="btn btn-primary btn-block" onclick="abrirModalConServicio('${p.id}')">
          👰 Reservar Paquete
        </button>
      </div>
    </div>
  `).join('');
}

async function cargarPromociones() {
  try {
    const res = await fetch('/api/promociones');
    const data = await res.json();
    if (data.ok && data.promociones?.length) {
      state.promociones = data.promociones;
    } else {
      state.promociones = [
        { id: 'promo1', titulo: 'Martes & Miércoles de Alisados', descripcion: '20% de descuento en Alisado Orgánico reservando online.', porcentaje_descuento: 20, fecha_fin: '2026-10-15' },
        { id: 'promo2', titulo: 'Pack Novia Anticipada', descripcion: '$20 de descuento reservando tu paquete de boda con al menos 15 días de anticipación.', monto_descuento: 20, fecha_fin: '2026-10-30' },
      ];
    }
  } catch {
    state.promociones = [
      { id: 'promo1', titulo: 'Martes & Miércoles de Alisados', descripcion: '20% de descuento en Alisado Orgánico reservando online.', porcentaje_descuento: 20, fecha_fin: '2026-10-15' },
    ];
  }
  renderizarPromociones();
  poblarSelectPromociones();
}

function renderizarPromociones() {
  const contenedor = document.getElementById('gridPromociones');
  if (!contenedor) return;

  contenedor.innerHTML = state.promociones.map(p => `
    <div class="promo-card">
      <div>
        <span class="promo-tag">${p.porcentaje_descuento ? `${p.porcentaje_descuento}% OFF` : `$${p.monto_descuento} OFF`}</span>
        <h3 class="promo-title">${p.titulo}</h3>
        <p class="promo-desc">${p.descripcion || ''}</p>
      </div>
      <div>
        <div class="promo-vigencia">📅 Válido hasta: ${p.fecha_fin}</div>
        <button class="btn btn-primary btn-block" onclick="abrirModalConPromo('${p.id}')">
          🎁 Aprovechar y Reservar
        </button>
      </div>
    </div>
  `).join('');
}

async function cargarGaleria() {
  try {
    const res = await fetch('/api/galeria');
    const data = await res.json();
    state.galeria = data.ok && data.trabajos?.length ? data.trabajos : [
      { id: 'g1', titulo: 'Balayage Rubio Vainilla', categoria: 'Colorimetría', imagen_url: 'https://images.unsplash.com/photo-1560869713-7d0a29430803?auto=format&fit=crop&w=800&q=80' },
      { id: 'g2', titulo: 'Peinado Novia Romántica', categoria: 'Novias', imagen_url: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=800&q=80' },
      { id: 'g3', titulo: 'Alisado Orgánico Espejo', categoria: 'Tratamientos', imagen_url: 'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?auto=format&fit=crop&w=800&q=80' },
    ];
  } catch {
    state.galeria = [
      { id: 'g1', titulo: 'Balayage Rubio Vainilla', categoria: 'Colorimetría', imagen_url: 'https://images.unsplash.com/photo-1560869713-7d0a29430803?auto=format&fit=crop&w=800&q=80' },
    ];
  }
  renderizarGaleria();
}

function renderizarGaleria() {
  const contenedor = document.getElementById('gridGaleria');
  if (!contenedor) return;

  contenedor.innerHTML = state.galeria.map(g => `
    <div class="galeria-card">
      <img src="${g.imagen_url}" alt="${g.titulo}" class="galeria-img" onerror="this.src='https://images.unsplash.com/photo-1560869713-7d0a29430803?auto=format&fit=crop&w=800&q=80'">
      <div class="galeria-info">
        <span class="galeria-cat">${g.categoria}</span>
        <h4 class="galeria-titulo">${g.titulo}</h4>
      </div>
    </div>
  `).join('');
}

// ==========================================
// MODAL DE RESERVAS (CLIENTES)
// ==========================================
function abrirModalReserva() {
  document.getElementById('modalReserva').classList.add('active');
  const catSel = document.getElementById('reservaCategoria');
  if (catSel && !catSel.value) {
    alCambiarCategoriaReserva();
  }
  actualizarCalculoReserva();
}

function cerrarModalReserva() {
  document.getElementById('modalReserva').classList.remove('active');
}

function servicioEnCategoriaWeb(s, catId) {
  if (!catId) return false;
  const svcCat = (s.categoria || '').toLowerCase().trim();
  const svcNom = (s.nombre || '').toLowerCase().trim();
  const combined = `${svcCat} ${svcNom}`;

  if (catId === 'corte') {
    return svcCat === 'corte' || combined.includes('corte') || combined.includes('cut');
  }
  if (catId === 'color') {
    return svcCat.includes('color') || combined.includes('color') || combined.includes('tinte') || combined.includes('balayage') || combined.includes('decolor') || combined.includes('matiz');
  }
  if (catId === 'tratamiento') {
    return svcCat.includes('tratam') || combined.includes('tratam') || combined.includes('alisad') || combined.includes('keratina') || combined.includes('botox');
  }
  if (catId === 'pestanas') {
    return svcCat.includes('pesta') || svcCat.includes('ceja') || combined.includes('pesta') || combined.includes('ceja') || combined.includes('lash');
  }
  if (catId === 'paquete') {
    return svcCat.includes('paquete') || combined.includes('paquete') || combined.includes('boda') || combined.includes('novia') || combined.includes('quince') || combined.includes('15');
  }
  if (catId === 'peinado') {
    return svcCat.includes('peinado') || svcCat.includes('maquillaje') || combined.includes('peinado') || combined.includes('maquillaje') || combined.includes('makeup') || combined.includes('brushing');
  }
  return svcCat === catId;
}

function alCambiarCategoriaReserva(preselectedServicioId) {
  const cat = document.getElementById('reservaCategoria')?.value;
  const grupoServicio = document.getElementById('grupoServicioReserva');
  const selectServicio = document.getElementById('reservaServicioId');
  if (!selectServicio) return;

  if (!cat) {
    if (grupoServicio) grupoServicio.style.display = 'none';
    selectServicio.innerHTML = '<option value="">-- Selecciona un servicio --</option>';
    selectServicio.value = '';
    actualizarCalculoReserva();
    return;
  }

  const todos = [...state.paquetes, ...state.servicios];
  const filtrados = todos.filter(s => servicioEnCategoriaWeb(s, cat));

  if (grupoServicio) grupoServicio.style.display = 'block';

  if (filtrados.length === 0) {
    selectServicio.innerHTML = '<option value="">No hay servicios registrados en esta categoría</option>';
  } else {
    selectServicio.innerHTML = '<option value="">-- Selecciona un servicio --</option>' +
      filtrados.map(s => `<option value="${s.id}">${s.nombre} ($${Number(s.precio_base).toFixed(2)})</option>`).join('');
  }

  if (preselectedServicioId) {
    selectServicio.value = preselectedServicioId;
  } else {
    selectServicio.value = '';
  }
  actualizarCalculoReserva();
}

function abrirModalConServicio(servicioId) {
  abrirModalReserva();
  const todos = [...state.paquetes, ...state.servicios];
  const s = todos.find(item => item.id === servicioId);
  if (s) {
    let targetCat = 'corte';
    const cats = ['corte', 'color', 'tratamiento', 'pestanas', 'peinado', 'paquete'];
    for (const c of cats) {
      if (servicioEnCategoriaWeb(s, c)) {
        targetCat = c;
        break;
      }
    }
    const selCat = document.getElementById('reservaCategoria');
    if (selCat) selCat.value = targetCat;
    alCambiarCategoriaReserva(servicioId);
  } else {
    actualizarCalculoReserva();
  }
}

function abrirModalConPromo(promoId) {
  abrirModalReserva();
  document.getElementById('reservaPromoId').value = promoId;
  actualizarCalculoReserva();
}

function poblarSelectServicios() {
  alCambiarCategoriaReserva();
}

function poblarSelectPromociones() {
  const select = document.getElementById('reservaPromoId');
  if (!select) return;

  select.innerHTML = `<option value="">Sin promoción (Precio estándar)</option>` +
    state.promociones.map(p => `
      <option value="${p.id}">${p.titulo} (${p.porcentaje_descuento ? `${p.porcentaje_descuento}% OFF` : `$${p.monto_descuento} OFF`})</option>
    `).join('');
}

function actualizarCalculoReserva() {
  const servicioId = document.getElementById('reservaServicioId')?.value;
  const promoId = document.getElementById('reservaPromoId')?.value;

  const todos = [...state.paquetes, ...state.servicios];
  const servicio = todos.find(s => s.id === servicioId);

  const duracionSpan = document.getElementById('resumenDuracion');
  const precioSpan = document.getElementById('resumenPrecio');

  if (!servicio) {
    if (duracionSpan) duracionSpan.innerText = '-- min';
    if (precioSpan) precioSpan.innerText = '$0.00';
    return;
  }

  if (duracionSpan) duracionSpan.innerText = `${servicio.duracion_minutos} min`;

  let precio = Number(servicio.precio_base);
  if (promoId) {
    const promo = state.promociones.find(p => p.id === promoId);
    if (promo) {
      if (promo.porcentaje_descuento) {
        precio -= (precio * promo.porcentaje_descuento) / 100;
      } else if (promo.monto_descuento) {
        precio = Math.max(0, precio - Number(promo.monto_descuento));
      }
    }
  }

  if (precioSpan) precioSpan.innerText = `$${precio.toFixed(2)}`;
}

async function cargarHorasDisponibles() {
  const fecha = document.getElementById('reservaFecha')?.value;
  if (!fecha) return;

  try {
    const res = await fetch(`/api/citas/disponibilidad?fecha=${fecha}`);
    const data = await res.json();
    if (data.ok && data.horas_ocupadas) {
      const selectHora = document.getElementById('reservaHora');
      Array.from(selectHora.options).forEach(opt => {
        const ocupada = data.horas_ocupadas.some(c => c.hora_inicio.startsWith(opt.value));
        opt.disabled = ocupada;
        opt.text = ocupada ? `${opt.value} (Ocupado)` : `${opt.value} (Disponible)`;
      });
    }
  } catch (err) {
    console.error('Error al verificar horas:', err);
  }
}

async function procesarReservaCita(e) {
  e.preventDefault();
  const btn = document.getElementById('btnConfirmarReserva');
  btn.disabled = true;
  btn.innerText = 'Agendando...';

  const payload = {
    cliente_nombre: document.getElementById('reservaClienteNombre').value,
    cliente_telefono: document.getElementById('reservaClienteTelefono').value,
    servicio_id: document.getElementById('reservaServicioId').value,
    promocion_id: document.getElementById('reservaPromoId').value || null,
    fecha_cita: document.getElementById('reservaFecha').value,
    hora_inicio: document.getElementById('reservaHora').value,
  };

  try {
    const res = await fetch('/api/citas', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    const data = await res.json();

    if (data.ok) {
      mostrarToast('🎉 ¡Cita agendada! Abriendo WhatsApp...');
      cerrarModalReserva();
      if (data.whatsapp_url) {
        window.open(data.whatsapp_url, '_blank');
      }
    } else {
      mostrarToast('No se pudo agendar la cita. Por favor, revisa los datos e inténtalo de nuevo.');
    }
  } catch (err) {
    mostrarToast('✅ Cita simulada con éxito (Modo local).');
    cerrarModalReserva();
  } finally {
    btn.disabled = false;
    btn.innerText = '✅ Confirmar Reserva y Abrir WhatsApp';
  }
}

// ==========================================
// LOGIN / REGISTRO DE USUARIOS
// ==========================================
function abrirModalLogin() {
  state.isRegistroMode = false;
  actualizarVistaLogin();
  document.getElementById('modalLogin').classList.add('active');
}

function cerrarModalLogin() {
  document.getElementById('modalLogin').classList.remove('active');
}

function toggleRegistro() {
  state.isRegistroMode = !state.isRegistroMode;
  actualizarVistaLogin();
}

function actualizarVistaLogin() {
  const titulo = document.getElementById('loginModalTitle');
  const btnLogin = document.getElementById('btnLogin');
  const grupoNombre = document.getElementById('grupoRegistroNombre');
  const grupoTelefono = document.getElementById('grupoRegistroTelefono');
  const switchText = document.getElementById('authSwitchText');
  const inputNombre = document.getElementById('registroNombre');
  const inputTelefono = document.getElementById('registroTelefono');

  if (state.isRegistroMode) {
    titulo.innerText = 'Crear Cuenta';
    btnLogin.innerText = 'Registrarme';
    grupoNombre.style.display = 'block';
    grupoTelefono.style.display = 'block';
    inputNombre.required = true;
    inputTelefono.required = true;
    switchText.innerHTML = '¿Ya tienes cuenta? <a href="#" onclick="toggleRegistro(); return false;">Iniciar sesión</a>';
  } else {
    titulo.innerText = 'Iniciar Sesión';
    btnLogin.innerText = 'Iniciar Sesión';
    grupoNombre.style.display = 'none';
    grupoTelefono.style.display = 'none';
    inputNombre.required = false;
    inputTelefono.required = false;
    switchText.innerHTML = '¿No tienes cuenta? <a href="#" onclick="toggleRegistro(); return false;">Crear una cuenta</a>';
  }
}

async function procesarLogin(e) {
  e.preventDefault();
  const email = document.getElementById('loginEmail').value;
  const password = document.getElementById('loginPassword').value;

  if (state.isRegistroMode) {
    const nombre = document.getElementById('registroNombre').value;
    const telefono = document.getElementById('registroTelefono').value;

    try {
      const res = await fetch('/api/clientes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nombre, telefono, email }),
      });
      const data = await res.json();
      if (data.ok || data.cliente) {
        mostrarToast('🎉 ¡Cuenta creada! Ahora puedes acceder a promociones exclusivas.');
        cerrarModalLogin();
      } else {
        mostrarToast('No se pudo crear la cuenta. Por favor, revisa los datos e inténtalo de nuevo.');
      }
    } catch {
      mostrarToast('Cuenta registrada localmente. Conecta el servidor para sincronizar.');
      cerrarModalLogin();
    }
  } else {
    // Login simple - verificar si el cliente existe por email
    try {
      const res = await fetch(`/api/clientes?q=${encodeURIComponent(email)}`);
      const data = await res.json();
      if (data.ok && data.clientes?.length) {
        mostrarToast(`¡Bienvenida de vuelta, ${data.clientes[0].nombre}! 💕`);
        cerrarModalLogin();
      } else {
        mostrarToast('No encontramos una cuenta con ese correo. ¿Deseas registrarte?');
      }
    } catch {
      mostrarToast('Sesión iniciada localmente.');
      cerrarModalLogin();
    }
  }
}

// ==========================================
// MODALES LEGALES (Términos y Cookies)
// ==========================================
function abrirModalTerminos() {
  document.getElementById('modalTerminos').classList.add('active');
}

function cerrarModalTerminos() {
  document.getElementById('modalTerminos').classList.remove('active');
}

function abrirModalPoliticaCookies() {
  document.getElementById('modalCookies').classList.add('active');
}

function cerrarModalPoliticaCookies() {
  document.getElementById('modalCookies').classList.remove('active');
}

// ==========================================
// BANNER DE COOKIES
// ==========================================
function mostrarCookieBanner() {
  if (localStorage.getItem('cookiesAceptadas')) return;
  const banner = document.getElementById('cookieBanner');
  if (banner) banner.style.display = 'flex';
}

function aceptarCookies() {
  localStorage.setItem('cookiesAceptadas', 'true');
  const banner = document.getElementById('cookieBanner');
  if (banner) banner.style.display = 'none';
}

// ==========================================
// TOAST
// ==========================================
function mostrarToast(mensaje) {
  const toast = document.getElementById('toastNotification');
  if (!toast) return;
  toast.innerText = mensaje;
  toast.style.display = 'block';
  setTimeout(() => {
    toast.style.display = 'none';
  }, 4000);
}
