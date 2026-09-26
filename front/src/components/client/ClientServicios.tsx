import React, { useEffect, useState, useRef } from 'react';
import { Scissors, Clock, ChevronRight, MessageCircle, Search, Crown, CalendarDays } from 'lucide-react';
import { Servicio } from '../../types';
import { getServicios } from '../../services/api';
import { SALON_CONFIG } from '../../config/salonConfig';
import { ReservaModal } from './ReservaModal';

interface ClientServiciosProps {
  onReservar?: () => void;
}

const CATEGORIAS: { id: string; label: string }[] = [
  { id: 'all', label: 'Todos' },
  { id: 'colorimetria', label: 'Colorimetría' },
  { id: 'corte', label: 'Cortes' },
  { id: 'tratamiento', label: 'Tratamientos' },
  { id: 'peinado_maquillaje', label: 'Peinado & Maquillaje' },
  { id: 'paquete_bodas', label: 'Paquete Bodas' },
  { id: 'paquete_quinceanera', label: 'Quinceañeras' },
  { id: 'pestanas_cejas', label: 'Pestañas & Cejas' },
];

function useScrollReveal(threshold = 0.1) {
  const ref = useRef<HTMLDivElement>(null);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
          observer.disconnect();
        }
      },
      { threshold, rootMargin: '0px 0px -30px 0px' }
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  return { ref, isVisible };
}

const ServiceCard: React.FC<{
  servicio: Servicio;
  index: number;
  onOpenModal: (servicio: Servicio) => void;
}> = ({ servicio, index, onOpenModal }) => {
  const { ref, isVisible } = useScrollReveal();

  return (
    <div
      ref={ref}
      className={`group bg-white rounded-xl sm:rounded-2xl p-4 sm:p-6 border border-[#f5e6ed] hover:border-[#ec4899]/30 shadow-xs hover:shadow-xl hover:shadow-[#b10e6b]/5 transition-all duration-500 flex flex-col justify-between ${
        isVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8'
      }`}
      style={{ transitionDelay: isVisible ? `${(index % 6) * 70}ms` : '0ms' }}
    >
      <div>
        <div className="flex items-center justify-between mb-2 sm:mb-3 gap-2">
          <span className="px-2 sm:px-3 py-0.5 sm:py-1 rounded-full text-[9px] sm:text-[10px] font-bold uppercase tracking-wider bg-[#fdf2f8] text-[#b10e6b] flex items-center gap-1">
            {servicio.categoria.replace(/_/g, ' ')}
          </span>
          <span className="text-[10px] sm:text-xs text-[#515f74] flex items-center gap-1 whitespace-nowrap">
            <Clock className="w-3 h-3" /> {servicio.duracion_minutos} min
          </span>
        </div>

        <h3 className="font-serif text-sm sm:text-lg font-bold text-[#0b1c30] mb-1 sm:mb-2 group-hover:text-[#b10e6b] transition-colors">
          {servicio.nombre}
        </h3>

        <p className="text-[10px] sm:text-xs text-[#515f74] line-clamp-3 mb-3 sm:mb-4">
          {servicio.descripcion || 'Servicio profesional con productos de alta calidad.'}
        </p>
      </div>

      <div className="pt-3 sm:pt-4 border-t border-[#f5e6ed] flex items-center justify-between gap-2">
        <div>
          <span className="text-[9px] sm:text-[10px] text-[#515f74] uppercase block">Desde</span>
          <span className="text-lg sm:text-xl font-serif font-bold text-[#0b1c30]">
            {SALON_CONFIG.monedaSimbolo}{Number(servicio.precio_base).toFixed(2)}
          </span>
        </div>

        <button
          onClick={() => onOpenModal(servicio)}
          className="inline-flex items-center gap-1.5 px-3.5 sm:px-4 py-2 rounded-full text-xs font-bold bg-[#b10e6b] hover:bg-[#930b58] text-white shadow-md transition-all cursor-pointer active:scale-95"
        >
          <CalendarDays className="w-3.5 h-3.5" />
          <span>Reservar</span>
        </button>
      </div>
    </div>
  );
};

export const ClientServicios: React.FC<ClientServiciosProps> = () => {
  const [servicios, setServicios] = useState<Servicio[]>([]);
  const [selectedCat, setSelectedCat] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');

  // Modal State
  const [modalOpen, setModalOpen] = useState(false);
  const [servicioModal, setServicioModal] = useState<Servicio | null>(null);

  const headerReveal = useScrollReveal();

  useEffect(() => {
    getServicios().then((r) => setServicios(r.servicios || [])).catch(() => {});
  }, []);

  const handleOpenModal = (servicio: Servicio) => {
    setServicioModal(servicio);
    setModalOpen(true);
  };

  const filtered = servicios.filter((s) => {
    if (selectedCat !== 'all' && s.categoria !== selectedCat) return false;
    if (searchQuery && !s.nombre.toLowerCase().includes(searchQuery.toLowerCase())) return false;
    return true;
  });

  return (
    <div className="min-h-screen bg-[#fefcfd] pb-24">
      {/* Header */}
      <div
        ref={headerReveal.ref}
        className={`bg-gradient-to-br from-[#0b1c30] to-[#1a2d45] text-white py-12 sm:py-16 lg:py-20 px-4 sm:px-6 relative overflow-hidden transition-all duration-700 ${
          headerReveal.isVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-6'
        }`}
      >
        <div className="absolute top-0 right-0 w-40 h-40 sm:w-80 sm:h-80 rounded-full bg-[#b10e6b]/10 blur-[80px]" />
        <div className="max-w-5xl mx-auto text-center relative z-10">
          <span className="inline-flex items-center gap-2 px-3 sm:px-4 py-1.5 rounded-full bg-white/10 text-white/80 text-[10px] sm:text-xs font-bold uppercase tracking-widest mb-3 sm:mb-4">
            <Scissors className="w-3 h-3 sm:w-3.5 sm:h-3.5 text-[#ec4899]" />
            Catálogo Completo – {SALON_CONFIG.nombre}
          </span>
          <h1 className="font-serif text-2xl sm:text-4xl lg:text-5xl font-bold mb-3 sm:mb-4">
            Nuestros Servicios
          </h1>
          <p className="text-white/60 max-w-lg mx-auto text-xs sm:text-sm">
            Haz clic en cualquier servicio para abrir el calendario flotante y confirmar tu cita por WhatsApp.
          </p>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-3 sm:px-6 -mt-5 sm:-mt-6">
        {/* Search Bar */}
        <div className="relative max-w-md mx-auto mb-6 sm:mb-8">
          <Search className="w-4 h-4 text-[#515f74] absolute left-4 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Buscar servicio..."
            className="w-full pl-11 pr-4 py-3 sm:py-3.5 rounded-2xl bg-white border border-[#f5e6ed] shadow-lg text-sm text-[#0b1c30] placeholder:text-[#8b7079] outline-none focus:ring-2 focus:ring-[#b10e6b]/20"
          />
        </div>

        {/* Category Filter Pills */}
        <div className="flex items-center gap-1.5 sm:gap-2 overflow-x-auto pb-4 scrollbar-none px-1 sm:justify-center">
          {CATEGORIAS.map((cat) => (
            <button
              key={cat.id}
              onClick={() => setSelectedCat(cat.id)}
              className={`px-3 sm:px-4 py-1.5 sm:py-2 rounded-full text-[10px] sm:text-xs font-semibold whitespace-nowrap transition-all cursor-pointer ${
                selectedCat === cat.id
                  ? 'bg-[#b10e6b] text-white shadow-sm shadow-[#b10e6b]/20'
                  : 'bg-white text-[#515f74] hover:bg-[#fdf2f8] border border-[#f5e6ed]'
              }`}
            >
              {cat.label}
            </button>
          ))}
        </div>
      </div>

      {/* Services Grid */}
      <div className="max-w-7xl mx-auto px-3 sm:px-6 py-6 sm:py-10">
        {filtered.length === 0 ? (
          <div className="text-center py-16 text-[#515f74]">
            <Scissors className="w-10 h-10 mx-auto mb-3 text-slate-300" />
            <p className="text-sm">No se encontraron servicios con esos filtros.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-6">
            {filtered.map((s, index) => (
              <ServiceCard
                key={s.id}
                servicio={s}
                index={index}
                onOpenModal={handleOpenModal}
              />
            ))}
          </div>
        )}
      </div>

      {/* Pop-up Overlay Modal */}
      <ReservaModal
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        servicio={servicioModal}
        serviciosDisponibles={servicios}
        onSelectServicio={(s) => setServicioModal(s)}
      />
    </div>
  );
};
