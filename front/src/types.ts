export type NavigationTab = 'dashboard' | 'citas' | 'servicios' | 'calculadora' | 'promociones' | 'gastos' | 'galeria' | 'cursos';

export type CategoriaServicio =
  | 'corte'
  | 'colorimetria'
  | 'tratamiento'
  | 'peinado_maquillaje'
  | 'paquete_bodas'
  | 'paquete_quinceanera'
  | 'pestanas_cejas'
  | 'otro';

export type EstadoCita = 'pendiente' | 'confirmada' | 'completada' | 'cancelada';
export type EstadoPago = 'pagado' | 'pendiente';

export type CategoriaGasto = 'arriendo' | 'servicios' | 'productos' | 'comida' | 'transporte' | 'otros';

export interface Servicio {
  id: string;
  created_at?: string;
  nombre: string;
  categoria: CategoriaServicio;
  descripcion?: string | null;
  duracion_minutos: number;
  precio_base: number;
  imagen_url?: string | null;
  activo: boolean;
}

export interface Promocion {
  id: string;
  created_at?: string;
  titulo: string;
  descripcion?: string | null;
  porcentaje_descuento?: number | null;
  monto_descuento?: number | null;
  fecha_inicio: string;
  fecha_fin: string;
  imagen_url?: string | null;
  activa: boolean;
}

export interface Cita {
  id: string;
  created_at?: string;
  cliente_nombre: string;
  cliente_telefono: string;
  cliente_email?: string | null;
  servicio_id: string;
  promocion_id?: string | null;
  fecha_cita: string;
  hora_inicio: string;
  hora_fin: string;
  estado: EstadoCita;
  estado_pago: EstadoPago;
  precio_original: number;
  descuento_aplicado: number;
  precio_final: number;
  notas?: string | null;
  servicios?: {
    nombre: string;
    duracion_minutos: number;
    categoria: string;
  } | null;
  promociones?: {
    titulo: string;
    porcentaje_descuento?: number | null;
  } | null;
}

export interface Gasto {
  id: string;
  fecha: string;
  concepto?: string | null;
  monto: number;
  categoria: CategoriaGasto;
}

export interface VentaProducto {
  id: string;
  fecha: string;
  nombre_producto: string;
  nombre_cliente?: string | null;
  precio_costo: number;
  precio_venta: number;
  cantidad: number;
  ganancia?: number;
}

export interface DesgloseCalculadora {
  decolorante: { porciones: number; precio_unitario: number; subtotal: number };
  tinte: { tubos: number; precio_unitario: number; subtotal: number };
  peroxido: { mezclas: number; precio_unitario: number; subtotal: number };
  extra?: { extra: string };
  costo_total_materiales: number;
  multiplicador: string;
  materiales_con_margen: number;
  mano_de_obra: { horas: number; precio_hora: number; subtotal: number };
}

export interface CalculoPrecioResult {
  ok: boolean;
  desglose: DesgloseCalculadora;
  PRECIO_FINAL: number;
  mensaje: string;
}

export interface ReporteFinanciero {
  ok: boolean;
  periodo: string;
  ingresos: {
    cursos: number;
    servicios: number;
    productos: number;
  };
  total_ingresos: number;
  total_gastos: number;
  ganancia_real_productos: number;
  balance_neto: number;
  mensaje: string;
}

export interface GaleriaItem {
  id: string;
  created_at: string;
  titulo: string;
  categoria: string;
  imagen_url: string;
  descripcion?: string | null;
  destacado: boolean;
}

export interface CursoItem {
  id: string;
  created_at: string;
  titulo: string;
  descripcion: string;
  precio_referencia: number;
  imagen_url?: string | null;
  link_hotmart: string;
  activo: boolean;
}
