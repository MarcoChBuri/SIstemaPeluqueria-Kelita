import {
  Cita,
  Servicio,
  Promocion,
  Gasto,
  VentaProducto,
  CalculoPrecioResult,
  ReporteFinanciero,
  GaleriaItem,
  CursoItem
} from '../types';

const API_BASE = '/api';

// Helper genérico para peticiones
async function request<T>(endpoint: string, options?: RequestInit): Promise<T> {
  const url = `${API_BASE}${endpoint}`;
  const response = await fetch(url, {
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
    ...options,
  });

  const data = await response.json();
  if (!response.ok || data.ok === false) {
    throw new Error(data.error || `Error en la petición: ${response.statusText}`);
  }
  return data;
}

// ==========================================
// 1. CITAS
// ==========================================
export async function getCitas(params?: { fecha?: string; estado?: string; mes?: number; anio?: number }): Promise<Cita[]> {
  const query = new URLSearchParams();
  if (params?.fecha) query.append('fecha', params.fecha);
  if (params?.estado) query.append('estado', params.estado);
  if (params?.mes) query.append('mes', String(params.mes));
  if (params?.anio) query.append('anio', String(params.anio));

  const res = await request<{ ok: boolean; cantidad: number; citas: Cita[] }>(`/citas?${query.toString()}`);
  return res.citas;
}

export async function createCita(payload: {
  cliente_nombre: string;
  cliente_telefono: string;
  cliente_email?: string;
  servicio_id: string;
  promocion_id?: string;
  fecha_cita: string;
  hora_inicio: string;
  notas?: string;
}): Promise<{ cita: Cita; whatsapp_url: string; mensaje: string }> {
  return request<{ ok: boolean; mensaje: string; cita: Cita; whatsapp_url: string }>('/citas', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export async function updateCitaEstado(
  id: string,
  payload: { estado?: 'pendiente' | 'confirmada' | 'completada' | 'cancelada'; estado_pago?: 'pendiente' | 'pagado' }
): Promise<Cita> {
  const res = await request<{ ok: boolean; mensaje: string; cita: Cita }>(`/citas/${id}/estado`, {
    method: 'PATCH',
    body: JSON.stringify(payload),
  });
  return res.cita;
}

export async function getDisponibilidad(fecha: string): Promise<{ hora_inicio: string; hora_fin: string; estado: string }[]> {
  const res = await request<{ ok: boolean; fecha: string; horas_ocupadas: { hora_inicio: string; hora_fin: string; estado: string }[] }>(
    `/citas/disponibilidad?fecha=${fecha}`
  );
  return res.horas_ocupadas;
}

// ==========================================
// 2. SERVICIOS Y PAQUETES
// ==========================================
export async function getServicios(params?: { categoria?: string; solo_activos?: boolean }): Promise<{
  servicios: Servicio[];
  paquetes_especiales: Servicio[];
  servicios_regulares: Servicio[];
}> {
  const query = new URLSearchParams();
  if (params?.categoria) query.append('categoria', params.categoria);
  if (params?.solo_activos !== undefined) query.append('solo_activos', String(params.solo_activos));

  return request<{
    ok: boolean;
    servicios: Servicio[];
    paquetes_especiales: Servicio[];
    servicios_regulares: Servicio[];
  }>(`/servicios?${query.toString()}`);
}

export async function createServicio(payload: {
  nombre: string;
  categoria: string;
  descripcion?: string;
  duracion_minutos: number;
  precio_base: number;
  imagen_url?: string;
}): Promise<Servicio> {
  const res = await request<{ ok: boolean; mensaje: string; servicio: Servicio }>('/servicios', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  return res.servicio;
}

// ==========================================
// 3. PROMOCIONES
// ==========================================
export async function getPromociones(): Promise<Promocion[]> {
  const res = await request<{ ok: boolean; promociones: Promocion[] }>('/promociones');
  return res.promociones;
}

export async function createPromocion(payload: {
  titulo: string;
  descripcion?: string;
  porcentaje_descuento?: number;
  monto_descuento?: number;
  fecha_inicio?: string;
  fecha_fin: string;
  imagen_url?: string;
}): Promise<Promocion> {
  const res = await request<{ ok: boolean; mensaje: string; promocion: Promocion }>('/promociones', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  return res.promocion;
}

// ==========================================
// 4. CALCULADORA DE PRECIOS QUÍMICOS
// ==========================================
export async function calcularPrecio(payload: {
  porciones_decolorante: number;
  tubos_tinte: number;
  mezclas_peroxido: number;
  horas_trabajo: number;
  extra?: number;
}): Promise<CalculoPrecioResult> {
  return request<CalculoPrecioResult>('/calcular-precio', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

// ==========================================
// 5. GASTOS Y AUDITORÍA DE CAJA
// ==========================================
export async function getGastos(): Promise<{ total: number; gastos: Gasto[] }> {
  return request<{ ok: boolean; total: number; gastos: Gasto[] }>('/gastos');
}

export async function createGasto(payload: {
  monto: number;
  categoria: 'arriendo' | 'servicios' | 'productos' | 'comida' | 'transporte' | 'otros';
  concepto?: string;
}): Promise<Gasto> {
  const res = await request<{ ok: boolean; mensaje: string; data: Gasto }>('/gastos', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  return res.data;
}

// ==========================================
// 6. VENTAS DE PRODUCTOS
// ==========================================
export async function createVentaProducto(payload: {
  nombre: string;
  costo: number;
  precio: number;
}): Promise<VentaProducto> {
  const res = await request<{ ok: boolean; mensaje: string; data: VentaProducto }>('/productos/venta', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  return res.data;
}

export async function getVentasProductos(params?: { mes?: number; anio?: number }): Promise<{
  periodo: string;
  cantidad: number;
  total_ventas: number;
  total_costo: number;
  ganancia_total: number;
  ventas: VentaProducto[];
}> {
  const query = new URLSearchParams();
  if (params?.mes) query.append('mes', String(params.mes));
  if (params?.anio) query.append('anio', String(params.anio));

  return request<{
    ok: boolean;
    periodo: string;
    cantidad: number;
    total_ventas: number;
    total_costo: number;
    ganancia_total: number;
    ventas: VentaProducto[];
  }>(`/productos/ventas?${query.toString()}`);
}

// ==========================================
// 7. REPORTES FINANCIEROS Y BALANCE
// ==========================================
export async function getReporteSimple(params?: { mes?: number; anio?: number }): Promise<ReporteFinanciero> {
  const query = new URLSearchParams();
  if (params?.mes) query.append('mes', String(params.mes));
  if (params?.anio) query.append('anio', String(params.anio));

  return request<ReporteFinanciero>(`/reporte-simple?${query.toString()}`);
}

// ==========================================
// 8. GALERÍA Y CURSOS
// ==========================================
export async function getGaleria(categoria?: string): Promise<GaleriaItem[]> {
  const query = categoria ? `?categoria=${categoria}` : '';
  const res = await request<{ ok: boolean; trabajos: GaleriaItem[] }>(`/galeria${query}`);
  return res.trabajos;
}

export async function getCursos(): Promise<CursoItem[]> {
  const res = await request<{ ok: boolean; cursos: CursoItem[] }>('/cursos');
  return res.cursos;
}
