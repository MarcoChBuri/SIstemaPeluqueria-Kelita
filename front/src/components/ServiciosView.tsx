import React, { useState } from 'react';
import { Scissors, Plus, Clock, DollarSign, Sparkles, CheckCircle2, HeartHandshake } from 'lucide-react';
import { Servicio, CategoriaServicio } from '../types';
import { createServicio } from '../services/api';

interface ServiciosViewProps {
  servicios: Servicio[];
  onServicioCreated: (servicio: Servicio) => void;
  onSelectServicioParaCita?: (servicioId: string) => void;
  onShowToast: (message: string) => void;
}

const CATEGORIAS_CONFIG: { id: string; label: string }[] = [
  { id: 'all', label: 'Todos los Servicios' },
  { id: 'colorimetria', label: 'Colorimetría & Tintes' },
  { id: 'corte', label: 'Cortes & Estilo' },
  { id: 'tratamiento', label: 'Tratamientos & Alisados' },
  { id: 'peinado_maquillaje', label: 'Peinado & Maquillaje' },
  { id: 'paquete_bodas', label: 'Paquetes de Bodas' },
  { id: 'paquete_quinceanera', label: 'Quinceañeras' },
  { id: 'pestanas_cejas', label: 'Pestañas & Cejas' },
];

export const ServiciosView: React.FC<ServiciosViewProps> = ({
  servicios,
  onServicioCreated,
  onSelectServicioParaCita,
  onShowToast,
}) => {
  const [selectedCategoria, setSelectedCategoria] = useState<string>('all');
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);

  // Form State
  const [nombre, setNombre] = useState<string>('');
  const [categoria, setCategoria] = useState<CategoriaServicio>('colorimetria');
  const [descripcion, setDescripcion] = useState<string>('');
  const [duracionMinutos, setDuracionMinutos] = useState<number>(60);
  const [precioBase, setPrecioBase] = useState<number>(25);
  const [imagenUrl, setImagenUrl] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  const filteredServicios = servicios.filter((s) => {
    if (selectedCategoria === 'all') return true;
    return s.categoria === selectedCategoria;
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!nombre.trim()) return;

    try {
      setIsSubmitting(true);
      const nuevo = await createServicio({
        nombre: nombre.trim(),
        categoria,
        descripcion: descripcion.trim() || undefined,
        duracion_minutos: duracionMinutos,
        precio_base: precioBase,
        imagen_url: imagenUrl.trim() || undefined,
      });

      onServicioCreated(nuevo);
      onShowToast(`Servicio "${nuevo.nombre}" creado exitosamente.`);
      setIsModalOpen(false);
      setNombre('');
      setDescripcion('');
      setPrecioBase(25);
      setDuracionMinutos(60);
      setImagenUrl('');
    } catch (err: any) {
      onShowToast(`Error: ${err.message}`);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="flex flex-col gap-6 w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-[#eff4ff] shadow-xs">
        <div>
          <span className="text-[10px] uppercase tracking-widest text-[#b10e6b] font-bold">
            Catálogo Oficial
          </span>
          <h1 className="font-serif text-2xl sm:text-3xl font-bold text-[#0b1c30]">
            Servicios y Paquetes de Boda
          </h1>
          <p className="text-xs text-[#515f74] mt-0.5">
            Tarifario base, tiempos asignados y paquetes especiales de Raquel.
          </p>
        </div>

        <button
          onClick={() => setIsModalOpen(true)}
          className="flex items-center gap-2 px-5 py-2.5 rounded-full bg-[#b10e6b] hover:bg-[#930b58] text-white text-xs sm:text-sm font-bold shadow-md transition-all active:scale-95 cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          <span>Nuevo Servicio</span>
        </button>
      </div>

      {/* Category Filter Pills */}
      <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-none">
        {CATEGORIAS_CONFIG.map((cat) => (
          <button
            key={cat.id}
            onClick={() => setSelectedCategoria(cat.id)}
            className={`px-4 py-2 rounded-full text-xs font-semibold whitespace-nowrap transition-all cursor-pointer ${
              selectedCategoria === cat.id
                ? 'bg-[#b10e6b] text-white shadow-xs'
                : 'bg-white text-[#515f74] hover:bg-[#eff4ff] border border-[#eff4ff]'
            }`}
          >
            {cat.label}
          </button>
        ))}
      </div>

      {/* Services Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredServicios.map((s) => (
          <div
            key={s.id}
            className="bg-white rounded-2xl p-6 border border-[#eff4ff] shadow-xs flex flex-col justify-between hover:shadow-md transition-all"
          >
            <div>
              <div className="flex items-center justify-between gap-2 mb-2">
                <span className="inline-block px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider bg-[#ffd9e4] text-[#b10e6b]">
                  {s.categoria.replace('_', ' ')}
                </span>
              </div>

              <h3 className="font-serif text-lg font-bold text-[#0b1c30] mb-2">
                {s.nombre}
              </h3>

              <p className="text-xs text-[#515f74] mb-4 line-clamp-3">
                {s.descripcion || 'Sin descripción detallada.'}
              </p>
            </div>

            <div className="pt-4 border-t border-[#eff4ff] flex items-center justify-between">
              <div>
                <span className="text-[10px] text-[#515f74] uppercase block">Precio Base</span>
                <span className="text-xl font-serif font-bold text-[#0b1c30]">
                  ${Number(s.precio_base).toFixed(2)}
                </span>
              </div>

              {onSelectServicioParaCita && (
                <button
                  onClick={() => onSelectServicioParaCita(s.id)}
                  className="px-4 py-2 rounded-full bg-[#eff4ff] hover:bg-[#b10e6b] hover:text-white text-[#b10e6b] text-xs font-bold transition-colors cursor-pointer"
                >
                  Agendar Cita
                </button>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Modal para crear Servicio */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs">
          <div className="w-full max-w-md rounded-3xl bg-white p-6 sm:p-8 shadow-2xl border border-[#eff4ff]">
            <h2 className="font-serif text-xl font-bold text-[#0b1c30] mb-1">Agregar Nuevo Servicio</h2>
            <p className="text-xs text-[#515f74] mb-4">Se guardará en la tabla de servicios del backend.</p>

            <form onSubmit={handleSubmit} className="space-y-3 text-xs">
              <div>
                <label className="block font-bold text-[#0b1c30] mb-1">Nombre del Servicio</label>
                <input
                  type="text"
                  required
                  placeholder="Ej: Balayage Rubio Platinado"
                  value={nombre}
                  onChange={(e) => setNombre(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30]"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block font-bold text-[#0b1c30] mb-1">Categoría</label>
                  <select
                    value={categoria}
                    onChange={(e) => setCategoria(e.target.value as CategoriaServicio)}
                    className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30]"
                  >
                    <option value="colorimetria">Colorimetría</option>
                    <option value="corte">Corte</option>
                    <option value="tratamiento">Tratamiento</option>
                    <option value="peinado_maquillaje">Peinado / Maquillaje</option>
                    <option value="paquete_bodas">Paquete Bodas</option>
                    <option value="paquete_quinceanera">Quinceañera</option>
                    <option value="pestanas_cejas">Pestañas / Cejas</option>
                    <option value="otro">Otro</option>
                  </select>
                </div>

                <div>
                  <label className="block font-bold text-[#0b1c30] mb-1">Duración (min)</label>
                  <input
                    type="number"
                    min="5"
                    required
                    value={duracionMinutos}
                    onChange={(e) => setDuracionMinutos(Number(e.target.value))}
                    className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30]"
                  />
                </div>
              </div>

              <div>
                <label className="block font-bold text-[#0b1c30] mb-1">Precio Base ($)</label>
                <input
                  type="number"
                  min="0"
                  step="0.5"
                  required
                  value={precioBase}
                  onChange={(e) => setPrecioBase(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30]"
                />
              </div>

              <div>
                <label className="block font-bold text-[#0b1c30] mb-1">Descripción</label>
                <textarea
                  rows={2}
                  placeholder="Detalles del procedimiento..."
                  value={descripcion}
                  onChange={(e) => setDescripcion(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30] resize-none"
                />
              </div>

              <div className="pt-3 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 rounded-full bg-[#eff4ff] text-[#515f74] font-semibold"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 rounded-full bg-[#b10e6b] hover:bg-[#930b58] text-white font-bold"
                >
                  {isSubmitting ? 'Guardando...' : 'Guardar Servicio'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
