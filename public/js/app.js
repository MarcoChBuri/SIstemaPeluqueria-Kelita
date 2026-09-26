/**
 * PELUQUERÍA RAQUEL - Frontend Interactivo
 */

// Estado Global de la App
let state = {
  servicios: [],
  paquetes: [],
  promociones: [],
  galeria: [],
  cursos: [],
  citas: [],
  gastos: [],
  vistaActual: 'cliente',
  subtabAdmin: 'agenda',
};

// ==========================================
// INICIALIZACIÓN
// ==========================================
document.addEventListener('DOMContentLoaded', () => {
  inicializarFechas();
  cargarDatosPublicos();
  ejecutarCalculoTintes();
});

function inicializarFechas() {
  const hoy = new Date().toISOString().split('T')[0];
  const inputFechaCita = document.getElementById('reservaFecha');
  const inputFiltroCitas = document.getElementById('filtroFechaCitas');
  const inputPromoInicio = document.getElementById('promoInicio');
  const inputPromoFin = document.getElementById('promoFin');

  if (inputFechaCita) inputFechaCita.min = hoy;
  if (inputFechaCita) inputFechaCita.value = hoy;
  if (inputFiltroCitas) inputFiltroCitas.value = hoy;
  if (inputPromoInicio) inputPromoInicio.value = hoy;
  if (inputPromoFin) {
    const finMes = new Date();
    finMes.setDate(finMes.getDate() + 30);
    inputPromoFin.value = finMes.toISOString().split('T')[0];
  }
}

// ==========================================
// NAVEGACIÓN Y VISTAS (Cliente vs Raquel Admin)
// ==========================================
function cambiarVista(vista) {
  state.vistaActual = vista;
  const vistaCliente = document.getElementById('vistaCliente');
  const vistaAdmin = document.getElementById('vistaAdmin');
  const btnSwitch = document.getElementById('btnSwitchVista');
  const clientNavs = document.querySelectorAll('.client-nav');

  if (vista === 'admin') {
    vistaCliente.classList.remove('active');
    vistaAdmin.classList.add('active');
    btnSwitch.innerText = '🌐 Ver Web de Clientes';
    btnSwitch.classList.remove('btn-outline');
    btnSwitch.classList.add('btn-secondary');
    clientNavs.forEach((el) => (el.style.display = 'none'));
    cargarDatosAdmin();
  } else {
    vistaAdmin.classList.remove('active');
    vistaCliente.classList.add('active');
    btnSwitch.innerText = '🔐 Panel de Raquel';
    btnSwitch.classList.remove('btn-secondary');
    btnSwitch.classList.add('btn-outline');
    clientNavs.forEach((el) => (el.style.display = ''));
    cargarDatosPublicos();
  }
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function toggleModoAdmin() {
  if (state.vistaActual === 'cliente') {
    cambiarVista('admin');
  } else {
    cambiarVista('cliente');
  }
}

function cambiarSubtabAdmin(subtab) {
  state.subtabAdmin = subtab;
  document.querySelectorAll('.subtab-content').forEach((el) => el.classList.remove('active'));
  document.querySelectorAll('.admin-nav-item').forEach((el) => el.classList.remove('active'));

  const tabActiva = document.getElementById(`subtab-${subtab}`);
  if (tabActiva) tabActiva.classList.add('active');

  const btnActivo = Array.from(document.querySelectorAll('.admin-nav-item')).find((btn) =>
    btn.getAttribute('onclick')?.includes(subtab)
  );
  if (btnActivo) btnActivo.classList.add('active');

  if (subtab === 'agenda') cargarCitasAdmin();
  if (subtab === 'gastos') cargarGastosAdmin();
}

// ==========================================
// CARGA DE DATOS PÚBLICOS (API + Fallbacks)
// ==========================================
async function cargarDatosPublicos() {
  await Promise.allSettled([
    cargarServicios(),
    cargarPromociones(),
    cargarGaleria(),
    cargarCursos(),
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
        <span class="servicio-meta">⏱️ ${s.duracion_minutos} min | 🏷️ ${s.categoria}</span>
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

async function cargarCursos() {
  try {
    const res = await fetch('/api/cursos');
    const data = await res.json();
    state.cursos = data.ok && data.cursos?.length ? data.cursos : [
      { id: 'c1', titulo: 'Masterclass: Colorimetría desde Cero a Experta', descripcion: 'Aprende las fórmulas secretas de decoloración, fondos de aclaración y matices perfectos.', precio_referencia: 47.00, link_hotmart: 'https://hotmart.com' },
      { id: 'c2', titulo: 'Técnicas de Peinados de Novia y Quinceañeras', descripcion: 'Domina las ondas glam, semirecogidos y técnicas de fijación profesional paso a paso.', precio_referencia: 35.00, link_hotmart: 'https://hotmart.com' },
    ];
  } catch {
    state.cursos = [
      { id: 'c1', titulo: 'Masterclass: Colorimetría desde Cero a Experta', descripcion: 'Aprende las fórmulas secretas de decoloración y matices.', precio_referencia: 47.00, link_hotmart: 'https://hotmart.com' },
    ];
  }
  renderizarCursos();
}

function renderizarCursos() {
  const contenedor = document.getElementById('gridCursos');
  if (!contenedor) return;

  contenedor.innerHTML = state.cursos.map(c => `
    <div class="curso-card">
      <div>
        <span class="badge-tag">🎓 Hotmart Certified</span>
        <h3 style="margin-top:10px; font-size:1.3rem;">${c.titulo}</h3>
        <p class="text-muted" style="margin-top:8px; font-size:0.92rem;">${c.descripcion}</p>
      </div>
      <div>
        <div class="curso-precio">$${Number(c.precio_referencia).toFixed(2)} USD</div>
        <a href="${c.link_hotmart}" target="_blank" rel="noopener" class="btn btn-primary btn-block">
          🛒 Comprar en Hotmart
        </a>
      </div>
    </div>
  `).join('');
}

// ==========================================
// MODAL DE RESERVAS (CLIENTES)
// ==========================================
function abrirModalReserva() {
  document.getElementById('modalReserva').classList.add('active');
  actualizarCalculoReserva();
}

function cerrarModalReserva() {
  document.getElementById('modalReserva').classList.remove('active');
}

function abrirModalConServicio(servicioId) {
  abrirModalReserva();
  document.getElementById('reservaServicioId').value = servicioId;
  actualizarCalculoReserva();
}

function abrirModalConPromo(promoId) {
  abrirModalReserva();
  document.getElementById('reservaPromoId').value = promoId;
  actualizarCalculoReserva();
}

function poblarSelectServicios() {
  const select = document.getElementById('reservaServicioId');
  if (!select) return;

  const todos = [...state.paquetes, ...state.servicios];
  select.innerHTML = `<option value="">-- Selecciona un servicio --</option>` +
    todos.map(s => `<option value="${s.id}">${s.nombre} ($${Number(s.precio_base).toFixed(2)})</option>`).join('');
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
      mostrarToast('🎉 ¡Cita agendada! Abriendo WhatsApp de Raquel...');
      cerrarModalReserva();
      if (data.whatsapp_url) {
        window.open(data.whatsapp_url, '_blank');
      }
    } else {
      mostrarToast(`⚠️ ${data.error || 'No se pudo agendar la cita.'}`);
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
// PANEL DE ADMINISTRACIÓN DE RAQUEL
// ==========================================
async function cargarDatosAdmin() {
  if (state.subtabAdmin === 'agenda') cargarCitasAdmin();
  if (state.subtabAdmin === 'gastos') cargarGastosAdmin();
}

async function cargarCitasAdmin() {
  const contenedor = document.getElementById('listaCitasAdmin');
  const fecha = document.getElementById('filtroFechaCitas')?.value;

  try {
    const url = fecha ? `/api/citas?fecha=${fecha}` : '/api/citas';
    const res = await fetch(url);
    const data = await res.json();

    if (data.ok && data.citas?.length) {
      state.citas = data.citas;
      contenedor.innerHTML = state.citas.map(c => `
        <div class="cita-card estado-${c.estado}">
          <div>
            <div style="font-weight:700; font-size:1.1rem;">${c.cliente_nombre} - 📞 ${c.cliente_telefono}</div>
            <div class="text-muted" style="font-size:0.9rem;">
              💇‍♀️ ${c.servicios?.nombre || 'Servicio'} | ⏰ ${c.hora_inicio} a ${c.hora_fin} | 📅 ${c.fecha_cita}
            </div>
            <div style="margin-top:6px;">
              <span class="badge-tag">Total: $${Number(c.precio_final).toFixed(2)}</span>
              <span class="badge-tag" style="margin-left:6px;">Estado: ${c.estado.toUpperCase()}</span>
            </div>
          </div>
          <div class="cita-actions">
            ${c.estado === 'pendiente' ? `
              <button class="btn btn-primary btn-sm" onclick="cambiarEstadoCita('${c.id}', 'confirmada')">
                Confirmar
              </button>
            ` : ''}
            ${c.estado === 'confirmada' ? `
              <button class="btn btn-whatsapp btn-sm" onclick="cambiarEstadoCita('${c.id}', 'completada')">
                Completada
              </button>
            ` : ''}
            <button class="btn btn-secondary btn-sm" onclick="cambiarEstadoCita('${c.id}', 'cancelada')">
              Cancelar
            </button>
          </div>
        </div>
      `).join('');
    } else {
      contenedor.innerHTML = `<p class="text-muted">No hay citas registradas para este día. ¡Día despejado!</p>`;
    }
  } catch {
    contenedor.innerHTML = `<p class="text-muted">Conecta Supabase en tu .env para ver las citas en tiempo real.</p>`;
  }
}

async function cambiarEstadoCita(id, nuevoEstado) {
  try {
    const res = await fetch(`/api/citas/${id}/estado`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ estado: nuevoEstado }),
    });
    const data = await res.json();
    if (data.ok) {
      mostrarToast(`Cita marcada como ${nuevoEstado}`);
      cargarCitasAdmin();
    }
  } catch (err) {
    mostrarToast('Error al actualizar estado.');
  }
}

async function guardarPromocion(e) {
  e.preventDefault();
  const payload = {
    titulo: document.getElementById('promoTitulo').value,
    porcentaje_descuento: document.getElementById('promoPorcentaje').value || null,
    monto_descuento: document.getElementById('promoMonto').value || null,
    fecha_inicio: document.getElementById('promoInicio').value,
    fecha_fin: document.getElementById('promoFin').value,
    descripcion: document.getElementById('promoDesc').value,
  };

  try {
    const res = await fetch('/api/promociones', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    const data = await res.json();
    if (data.ok) {
      mostrarToast('🎁 ¡Promoción publicada exitosamente!');
      document.getElementById('formNuevaPromo').reset();
    } else {
      mostrarToast(`⚠️ ${data.error}`);
    }
  } catch {
    mostrarToast('Promoción simulada guardada.');
  }
}

async function guardarFotoGaleria(e) {
  e.preventDefault();
  const payload = {
    titulo: document.getElementById('fotoTitulo').value,
    categoria: document.getElementById('fotoCategoria').value,
    imagen_url: document.getElementById('fotoUrl').value,
    descripcion: document.getElementById('fotoDesc').value,
    destacado: true,
  };

  try {
    const res = await fetch('/api/galeria', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    const data = await res.json();
    if (data.ok) {
      mostrarToast('📸 ¡Foto agregada al portafolio web!');
      document.getElementById('formNuevaFoto').reset();
    }
  } catch {
    mostrarToast('Foto simulada guardada.');
  }
}

// Calculadora de Tintes
async function ejecutarCalculoTintes() {
  const porciones = parseInt(document.getElementById('calcDecolorante')?.value || 0, 10);
  const tubos = parseInt(document.getElementById('calcTinte')?.value || 0, 10);
  const peroxido = parseInt(document.getElementById('calcPeroxido')?.value || 0, 10);
  const horas = parseInt(document.getElementById('calcHoras')?.value || 0, 10);

  // Precios de referencia
  const costoDecolorante = porciones * 6.25;
  const costoTinte = tubos * 6.00;
  const costoPeroxido = peroxido * 1.50;
  const costoMateriales = costoDecolorante + costoTinte + costoPeroxido;
  const materialesConMargen = costoMateriales * 3;
  const manoDeObra = horas * 5.00;
  const precioFinal = materialesConMargen + manoDeObra;

  const precioFinalEl = document.getElementById('calcPrecioFinal');
  const desgloseEl = document.getElementById('calcDesglose');

  if (precioFinalEl) precioFinalEl.innerText = `$${precioFinal.toFixed(2)}`;
  if (desgloseEl) {
    desgloseEl.innerHTML = `
      <div><strong>Materiales de costo:</strong> $${costoMateriales.toFixed(2)}</div>
      <div><strong>Margen aplicado:</strong> x3 ($${materialesConMargen.toFixed(2)})</div>
      <div><strong>Mano de obra (${horas}h):</strong> $${manoDeObra.toFixed(2)}</div>
    `;
  }
}

// Gastos
async function guardarGasto(e) {
  e.preventDefault();
  const payload = {
    monto: document.getElementById('gastoMonto').value,
    categoria: document.getElementById('gastoCategoria').value,
    concepto: document.getElementById('gastoConcepto').value,
  };

  try {
    const res = await fetch('/api/gastos', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    const data = await res.json();
    if (data.ok) {
      mostrarToast('💵 Gasto registrado en la base de datos.');
      document.getElementById('formGasto').reset();
      cargarGastosAdmin();
    }
  } catch {
    mostrarToast('Gasto simulado.');
  }
}

async function cargarGastosAdmin() {
  const contenedor = document.getElementById('listaGastosAdmin');
  if (!contenedor) return;

  try {
    const res = await fetch('/api/gastos');
    const data = await res.json();
    if (data.ok && data.gastos?.length) {
      contenedor.innerHTML = data.gastos.map(g => `
        <div style="display:flex; justify-content:space-between; padding:8px 0; border-bottom:1px solid rgba(255,255,255,0.08);">
          <span>${g.concepto || g.categoria} (${g.categoria})</span>
          <strong style="color:var(--accent-gold);">$${Number(g.monto).toFixed(2)}</strong>
        </div>
      `).join('');
    } else {
      contenedor.innerHTML = `<p class="text-muted">No hay gastos registrados este mes.</p>`;
    }
  } catch {
    contenedor.innerHTML = `<p class="text-muted">Conecta Supabase para ver el historial de gastos.</p>`;
  }
}

// Toast
function mostrarToast(mensaje) {
  const toast = document.getElementById('toastNotification');
  if (!toast) return;
  toast.innerText = mensaje;
  toast.style.display = 'block';
  setTimeout(() => {
    toast.style.display = 'none';
  }, 4000);
}
