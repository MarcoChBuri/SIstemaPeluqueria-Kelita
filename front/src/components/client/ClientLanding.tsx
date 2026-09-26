import React, { useEffect, useState, useRef } from 'react';
import {
  Sparkles,
  ChevronRight,
  CalendarDays,
  Scissors,
  Clock,
  Star,
  ArrowRight,
  Heart,
  Tag,
  MessageCircle,
} from 'lucide-react';
import { Servicio, GaleriaItem, Promocion } from '../../types';
import { getServicios, getGaleria, getPromociones } from '../../services/api';
import { SALON_CONFIG } from '../../config/salonConfig';
import { ReservaModal } from './ReservaModal';

interface ClientLandingProps {
  onNavigate: (section: string) => void;
}

function useScrollReveal(threshold = 0.12) {
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
      { threshold, rootMargin: '0px 0px -40px 0px' }
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  return { ref, isVisible };
}

const AnimatedGalleryCard: React.FC<{
  item: GaleriaItem;
  index: number;
  onClick: () => void;
}> = ({ item, index, onClick }) => {
  const { ref, isVisible } = useScrollReveal(0.1);

  return (
    <div
      ref={ref}
      className={`group relative rounded-xl sm:rounded-2xl overflow-hidden aspect-square cursor-pointer transition-all duration-600 ${
        isVisible
          ? 'opacity-100 translate-y-0 scale-100'
          : 'opacity-0 translate-y-10 scale-90'
      }`}
      style={{ transitionDelay: isVisible ? `${index * 100}ms` : '0ms' }}
      onClick={onClick}
    >
      <img
        src={item.imagen_url}
        alt={item.titulo}
        className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700 ease-out"
        loading="lazy"
      />
      <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex flex-col justify-end p-3 sm:p-4">
        <span className="text-white text-xs sm:text-sm font-bold">{item.titulo}</span>
        <span className="text-white/70 text-[10px] sm:text-xs">{item.categoria}</span>
      </div>
    </div>
  );
};

const AnimatedServiceCard: React.FC<{
  servicio: Servicio;
  index: number;
  onClick: () => void;
}> = ({ servicio, index, onClick }) => {
  const { ref, isVisible } = useScrollReveal(0.1);

  return (
    <div
      ref={ref}
      className={`group bg-white rounded-xl sm:rounded-2xl p-4 sm:p-6 border border-[#f5e6ed] hover:border-[#ec4899]/30 shadow-xs hover:shadow-xl hover:shadow-[#b10e6b]/5 transition-all duration-500 flex flex-col justify-between cursor-pointer ${
        isVisible
          ? 'opacity-100 translate-y-0'
          : 'opacity-0 translate-y-8'
      }`}
      style={{ transitionDelay: isVisible ? `${index * 80}ms` : '0ms' }}
      onClick={onClick}
    >
      <div>
        <div className="flex items-center justify-between mb-2 sm:mb-3">
          <span className="px-2 sm:px-3 py-0.5 sm:py-1 rounded-full text-[9px] sm:text-[10px] font-bold uppercase tracking-wider bg-[#fdf2f8] text-[#b10e6b]">
            {servicio.categoria.replace(/_/g, ' ')}
          </span>
          <span className="text-[10px] sm:text-xs text-[#515f74] flex items-center gap-1">
            <Clock className="w-3 h-3" /> {servicio.duracion_minutos} min
          </span>
        </div>

        <h3 className="font-serif text-sm sm:text-lg font-bold text-[#0b1c30] mb-1 sm:mb-2 group-hover:text-[#b10e6b] transition-colors">
          {servicio.nombre}
        </h3>

        <p className="text-[10px] sm:text-xs text-[#515f74] line-clamp-2 mb-3 sm:mb-4">
          {servicio.descripcion || 'Servicio profesional con productos de alta calidad.'}
        </p>
      </div>

      <div className="pt-3 sm:pt-4 border-t border-[#f5e6ed] flex items-center justify-between">
        <div>
          <span className="text-[9px] sm:text-[10px] text-[#515f74] uppercase block">Desde</span>
          <span className="text-lg sm:text-xl font-serif font-bold text-[#0b1c30]">
            {SALON_CONFIG.monedaSimbolo}{Number(servicio.precio_base).toFixed(2)}
          </span>
        </div>
        <span className="inline-flex items-center gap-1 text-[10px] sm:text-xs font-bold text-white bg-[#b10e6b] px-3 py-1.5 rounded-full shadow-xs group-hover:scale-105 transition-all">
          <CalendarDays className="w-3.5 h-3.5" /> Reservar
        </span>
      </div>
    </div>
  );
};

export const ClientLanding: React.FC<ClientLandingProps> = ({ onNavigate }) => {
  const [servicios, setServicios] = useState<Servicio[]>([]);
  const [galeriaDestacada, setGaleriaDestacada] = useState<GaleriaItem[]>([]);
  const [promos, setPromos] = useState<Promocion[]>([]);

  // Modal State
  const [modalOpen, setModalOpen] = useState(false);
  const [servicioModal, setServicioModal] = useState<Servicio | null>(null);

  const heroReveal = useScrollReveal(0.1);
  const servicesHeaderReveal = useScrollReveal();
  const promosReveal = useScrollReveal();
  const galleryHeaderReveal = useScrollReveal();

  useEffect(() => {
    getServicios()
      .then((r) => setServicios(r.servicios || []))
      .catch(() => {});
    getGaleria()
      .then((items) => setGaleriaDestacada(items.filter((i) => i.destacado).slice(0, 6)))
      .catch(() => {});
    getPromociones()
      .then((p) => setPromos(p.slice(0, 2)))
      .catch(() => {});
  }, []);

  const handleOpenServiceModal = (s: Servicio) => {
    setServicioModal(s);
    setModalOpen(true);
  };

  return (
    <div className="flex flex-col">
      {/* ═══════════════════ HERO ═══════════════════ */}
      <section className="relative overflow-hidden bg-gradient-to-br from-[#0b1c30] via-[#1a2d45] to-[#0b1c30] text-white min-h-[80vh] sm:min-h-[85vh] flex items-center">
        {/* Decorative Orbs */}
        <div className="absolute top-1/4 -right-16 sm:-right-32 w-[300px] sm:w-[500px] h-[300px] sm:h-[500px] rounded-full bg-[#b10e6b]/15 blur-[100px] sm:blur-[120px]" />
        <div className="absolute bottom-0 -left-10 sm:-left-20 w-[250px] sm:w-[400px] h-[250px] sm:h-[400px] rounded-full bg-[#ec4899]/10 blur-[80px] sm:blur-[100px]" />
        <div className="absolute top-10 left-1/3 w-[150px] sm:w-[200px] h-[150px] sm:h-[200px] rounded-full bg-[#d23284]/8 blur-[60px] sm:blur-[80px]" />

        {/* Grid Pattern */}
        <div className="absolute inset-0 opacity-[0.03]" style={{
          backgroundImage: 'radial-gradient(circle at 1px 1px, white 1px, transparent 0)',
          backgroundSize: '40px 40px',
        }} />

        <div
          ref={heroReveal.ref}
          className={`relative z-10 max-w-7xl mx-auto px-4 sm:px-6 py-16 sm:py-20 lg:py-28 grid grid-cols-1 lg:grid-cols-2 gap-8 sm:gap-12 items-center transition-all duration-700 ${
            heroReveal.isVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8'
          }`}
        >
          <div className="flex flex-col">
            <div className="inline-flex items-center gap-2 px-3 sm:px-4 py-1.5 sm:py-2 rounded-full bg-white/10 backdrop-blur-sm border border-white/10 w-fit mb-4 sm:mb-6">
              <Sparkles className="w-3.5 h-3.5 sm:w-4 sm:h-4 text-[#ec4899]" />
              <span className="text-[10px] sm:text-xs font-semibold text-white/80 tracking-wide">Especialistas en Colorimetría & Novias</span>
            </div>

            <h1 className="font-serif text-3xl sm:text-4xl lg:text-6xl font-bold leading-[1.1] mb-4 sm:mb-6">
              Tu belleza merece
              <br />
              <span className="bg-gradient-to-r from-[#ec4899] via-[#f472b6] to-[#fb923c] bg-clip-text text-transparent">
                manos expertas
              </span>
            </h1>

            <p className="text-sm sm:text-base lg:text-lg text-white/60 max-w-lg mb-6 sm:mb-8 leading-relaxed">
              Colorimetría profesional, alisados orgánicos sin formol, peinados de novia y tratamientos capilares premium. Agenda tu transformación hoy.
            </p>

            <div className="flex flex-col sm:flex-row items-start sm:items-center gap-3 sm:gap-4">
              <button
                onClick={() => {
                  if (servicios.length > 0) handleOpenServiceModal(servicios[0]);
                  else onNavigate('reservar');
                }}
                className="group w-full sm:w-auto flex items-center justify-center gap-2.5 px-6 sm:px-7 py-3.5 sm:py-4 rounded-full bg-gradient-to-r from-[#b10e6b] to-[#d23284] hover:from-[#930b58] hover:to-[#b10e6b] text-white font-bold text-sm shadow-2xl shadow-[#b10e6b]/30 transition-all active:scale-95 cursor-pointer"
              >
                <MessageCircle className="w-5 h-5" />
                <span>Reserva tu Cita Ahora</span>
                <ChevronRight className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
              </button>

              <button
                onClick={() => onNavigate('servicios')}
                className="w-full sm:w-auto flex items-center justify-center gap-2 px-6 py-3.5 sm:py-4 rounded-full border border-white/20 hover:bg-white/10 text-white/80 hover:text-white font-semibold text-sm transition-all cursor-pointer"
              >
                <span>Ver Servicios</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>

            {/* Trust Stats */}
            <div className="flex items-center gap-4 sm:gap-6 lg:gap-8 mt-8 sm:mt-10 pt-6 sm:pt-8 border-t border-white/10">
              <div className="flex flex-col">
                <span className="text-xl sm:text-2xl lg:text-3xl font-serif font-bold text-white">7+</span>
                <span className="text-[9px] sm:text-[11px] text-white/50 uppercase tracking-wider">Años de Exp.</span>
              </div>
              <div className="w-px h-8 sm:h-10 bg-white/10" />
              <div className="flex flex-col">
                <span className="text-xl sm:text-2xl lg:text-3xl font-serif font-bold text-white">500+</span>
                <span className="text-[9px] sm:text-[11px] text-white/50 uppercase tracking-wider">Clientas Felices</span>
              </div>
              <div className="w-px h-8 sm:h-10 bg-white/10" />
              <div className="flex flex-col">
                <div className="flex items-center gap-0.5">
                  {[1, 2, 3, 4, 5].map((i) => (
                    <Star key={i} className="w-3 h-3 sm:w-4 sm:h-4 fill-[#fbbf24] text-[#fbbf24]" />
                  ))}
                </div>
                <span className="text-[9px] sm:text-[11px] text-white/50 uppercase tracking-wider">Calificación</span>
              </div>
            </div>
          </div>

          {/* Hero Gallery Preview (Desktop) */}
          <div className="hidden lg:grid grid-cols-2 gap-4 relative">
            {galeriaDestacada.slice(0, 4).map((item, index) => (
              <div
                key={item.id}
                className={`relative rounded-2xl overflow-hidden shadow-2xl shadow-black/30 group cursor-pointer ${
                  index === 0 ? 'row-span-2 aspect-[3/4]' : 'aspect-square'
                }`}
                style={{
                  animation: heroReveal.isVisible ? `fadeInUp 0.6s ${index * 150}ms ease-out both` : 'none',
                }}
                onClick={() => onNavigate('galeria')}
              >
                <img
                  src={item.imagen_url}
                  alt={item.titulo}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                <div className="absolute bottom-3 left-3 right-3 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                  <span className="text-white text-xs font-bold">{item.titulo}</span>
                </div>
              </div>
            ))}

            {/* Floating Badge */}
            <div className="absolute -bottom-4 -left-4 bg-white rounded-2xl p-3 sm:p-4 shadow-xl shadow-black/10 flex items-center gap-3 z-10">
              <div className="w-9 h-9 sm:w-10 sm:h-10 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
                <Heart className="w-4 h-4 sm:w-5 sm:h-5 fill-current" />
              </div>
              <div>
                <span className="text-xs font-bold text-[#0b1c30] block">100% Recomendadas</span>
                <span className="text-[10px] text-[#515f74]">Por nuestras clientas</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ═══════════════════ SERVICIOS DESTACADOS ═══════════════════ */}
      <section className="py-12 sm:py-16 lg:py-24 px-4 sm:px-6 bg-white">
        <div className="max-w-7xl mx-auto">
          <div
            ref={servicesHeaderReveal.ref}
            className={`text-center mb-8 sm:mb-12 transition-all duration-700 ${
              servicesHeaderReveal.isVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-6'
            }`}
          >
            <span className="inline-flex items-center gap-2 px-3 sm:px-4 py-1.5 rounded-full bg-[#fdf2f8] text-[#b10e6b] text-[10px] sm:text-xs font-bold uppercase tracking-widest mb-3 sm:mb-4">
              <Scissors className="w-3 h-3 sm:w-3.5 sm:h-3.5" />
              Nuestros Servicios
            </span>
            <h2 className="font-serif text-2xl sm:text-3xl lg:text-4xl font-bold text-[#0b1c30] mb-2 sm:mb-3">
              Servicios Profesionales
            </h2>
            <p className="text-xs sm:text-sm text-[#515f74] max-w-xl mx-auto">
              Haz clic en cualquier servicio para abrir el calendario de reserva instantáneo.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-6">
            {servicios.slice(0, 6).map((s, index) => (
              <AnimatedServiceCard
                key={s.id}
                servicio={s}
                index={index}
                onClick={() => handleOpenServiceModal(s)}
              />
            ))}
          </div>

          <div className="text-center mt-8 sm:mt-10">
            <button
              onClick={() => onNavigate('servicios')}
              className="inline-flex items-center gap-2 px-5 sm:px-6 py-2.5 sm:py-3 rounded-full border-2 border-[#b10e6b] text-[#b10e6b] hover:bg-[#b10e6b] hover:text-white font-bold text-xs sm:text-sm transition-all cursor-pointer active:scale-95"
            >
              Ver Todos los Servicios
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </section>

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
