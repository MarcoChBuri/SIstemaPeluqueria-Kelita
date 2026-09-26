import React, { useEffect, useState, useRef } from 'react';
import { Image as ImageIcon, Heart, Tag, Eye, X, MessageCircle } from 'lucide-react';
import { GaleriaItem } from '../../types';
import { getGaleria } from '../../services/api';
import { SALON_CONFIG, buildWhatsAppUrl } from '../../config/salonConfig';

const CATEGORIAS = [
  { id: 'all', label: 'Todos' },
  { id: 'Colorimetría', label: 'Colorimetría' },
  { id: 'Alisados', label: 'Alisados' },
  { id: 'Novias', label: 'Novias' },
  { id: 'Tratamientos', label: 'Tratamientos' },
  { id: 'Cortes', label: 'Cortes' },
];

// Hook for individual card scroll reveal
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

// Individual gallery card with scroll animation
const GalleryCard: React.FC<{
  item: GaleriaItem;
  index: number;
  onClick: () => void;
}> = ({ item, index, onClick }) => {
  const { ref, isVisible } = useScrollReveal(0.1);

  return (
    <div
      ref={ref}
      onClick={onClick}
      className={`group relative bg-white rounded-2xl sm:rounded-3xl overflow-hidden border border-[#f5e6ed] shadow-sm hover:shadow-xl transition-all duration-500 cursor-pointer flex flex-col ${
        isVisible
          ? 'opacity-100 translate-y-0 scale-100'
          : 'opacity-0 translate-y-8 scale-95'
      }`}
      style={{
        transitionDelay: isVisible ? `${(index % 6) * 80}ms` : '0ms',
      }}
    >
      <div className="relative aspect-[4/5] overflow-hidden bg-slate-100">
        <img
          src={item.imagen_url}
          alt={item.titulo}
          className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700 ease-out"
          loading="lazy"
        />
        {/* Hover overlay */}
        <div className="absolute inset-0 bg-gradient-to-t from-black/75 via-black/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-center justify-center">
          <div className="w-12 h-12 rounded-full bg-white/20 backdrop-blur-md flex items-center justify-center text-white scale-75 group-hover:scale-100 transition-transform duration-300">
            <Eye className="w-6 h-6" />
          </div>
        </div>
        {item.destacado && (
          <span className="absolute top-2 left-2 sm:top-3 sm:left-3 bg-[#b10e6b] text-white text-[9px] sm:text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 sm:px-2.5 sm:py-1 rounded-full shadow-md flex items-center gap-1">
            <Heart className="w-2.5 h-2.5 sm:w-3 sm:h-3 fill-current" /> Destacado
          </span>
        )}
        <span className="absolute bottom-2 left-2 sm:bottom-3 sm:left-3 bg-white/90 backdrop-blur-md text-[#0b1c30] text-[9px] sm:text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 sm:px-2.5 sm:py-1 rounded-lg">
          {item.categoria}
        </span>
      </div>

      <div className="p-3 sm:p-5 flex-1 flex flex-col justify-between">
        <div>
          <h3 className="font-serif font-bold text-sm sm:text-base text-[#0b1c30] mb-1 group-hover:text-[#b10e6b] transition-colors">
            {item.titulo}
          </h3>
          {item.descripcion && (
            <p className="text-[10px] sm:text-xs text-[#515f74] line-clamp-2 leading-relaxed">
              {item.descripcion}
            </p>
          )}
        </div>
      </div>
    </div>
  );
};

export const ClientGaleria: React.FC = () => {
  const [items, setItems] = useState<GaleriaItem[]>([]);
  const [selectedCat, setSelectedCat] = useState<string>('all');
  const [activeItem, setActiveItem] = useState<GaleriaItem | null>(null);
  const [loading, setLoading] = useState(true);

  const headerReveal = useScrollReveal(0.1);

  useEffect(() => {
    setLoading(true);
    getGaleria()
      .then((data) => setItems(data))
      .catch((err) => console.error('Error cargando galería:', err))
      .finally(() => setLoading(false));
  }, []);

  const filtered = items.filter((item) => {
    if (selectedCat === 'all') return true;
    return item.categoria.toLowerCase() === selectedCat.toLowerCase();
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
        {/* Decorative orbs */}
        <div className="absolute top-0 right-0 w-40 h-40 sm:w-80 sm:h-80 rounded-full bg-[#b10e6b]/10 blur-[80px]" />
        <div className="absolute bottom-0 left-0 w-32 h-32 sm:w-60 sm:h-60 rounded-full bg-[#ec4899]/10 blur-[60px]" />

        <div className="relative z-10 max-w-4xl mx-auto text-center">
          <span className="inline-flex items-center gap-2 px-3 sm:px-4 py-1.5 rounded-full bg-white/10 text-white/90 text-[10px] sm:text-xs font-bold uppercase tracking-widest mb-3 sm:mb-4">
            <Heart className="w-3 h-3 sm:w-3.5 sm:h-3.5 text-[#ec4899]" />
            Nuestro Portafolio
          </span>
          <h1 className="font-serif text-2xl sm:text-4xl lg:text-5xl font-bold mb-3 sm:mb-4">
            Galería de Trabajos
          </h1>
          <p className="text-white/70 max-w-xl mx-auto text-xs sm:text-sm leading-relaxed">
            Descubre transformaciones reales creadas por Raquel. Calidad, brillo y cuidado para cada estilo de cabello.
          </p>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="max-w-7xl mx-auto px-3 sm:px-6 -mt-5 sm:-mt-6">
        <div className="flex items-center gap-1.5 sm:gap-2 overflow-x-auto pb-4 scrollbar-none justify-start sm:justify-center px-1">
          {CATEGORIAS.map((cat) => (
            <button
              key={cat.id}
              onClick={() => setSelectedCat(cat.id)}
              className={`px-3 sm:px-5 py-2 sm:py-2.5 rounded-full text-[11px] sm:text-xs font-semibold whitespace-nowrap transition-all shadow-xs cursor-pointer ${
                selectedCat === cat.id
                  ? 'bg-[#b10e6b] text-white shadow-[#b10e6b]/20 shadow-md'
                  : 'bg-white text-[#515f74] hover:bg-[#fdf2f8] border border-[#f5e6ed]'
              }`}
            >
              {cat.label}
            </button>
          ))}
        </div>
      </div>

      {/* Grid */}
      <div className="max-w-7xl mx-auto px-3 sm:px-6 py-6 sm:py-8">
        {loading ? (
          <div className="text-center py-20 text-[#515f74]">
            <div className="w-10 h-10 border-4 border-[#b10e6b] border-t-transparent rounded-full animate-spin mx-auto mb-4" />
            <p className="text-sm font-medium">Cargando portafolio...</p>
          </div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-16 sm:py-20 bg-white rounded-3xl border border-[#f5e6ed] p-8 sm:p-12 max-w-md mx-auto shadow-xs">
            <ImageIcon className="w-12 h-12 mx-auto mb-3 text-slate-300" />
            <h3 className="font-bold text-[#0b1c30] mb-1">Sin fotos aún</h3>
            <p className="text-xs text-[#515f74]">
              Pronto Raquel subirá más fotos para esta categoría.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-6">
            {filtered.map((item, index) => (
              <GalleryCard
                key={item.id}
                item={item}
                index={index}
                onClick={() => setActiveItem(item)}
              />
            ))}
          </div>
        )}
      </div>

      {/* Lightbox Modal */}
      {activeItem && (
        <div
          className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-3 sm:p-6 animate-[fadeIn_0.2s_ease-out]"
          onClick={() => setActiveItem(null)}
        >
          <div
            className="relative max-w-4xl w-full bg-white rounded-2xl sm:rounded-3xl overflow-hidden shadow-2xl flex flex-col md:flex-row max-h-[90vh] animate-[scaleIn_0.3s_ease-out]"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              onClick={() => setActiveItem(null)}
              className="absolute top-3 right-3 sm:top-4 sm:right-4 z-10 w-8 h-8 sm:w-9 sm:h-9 rounded-full bg-black/50 hover:bg-black text-white flex items-center justify-center transition-colors cursor-pointer"
            >
              <X className="w-4 h-4 sm:w-5 sm:h-5" />
            </button>

            <div className="md:w-3/5 bg-slate-900 flex items-center justify-center overflow-hidden min-h-[250px] sm:min-h-[300px] md:min-h-[480px]">
              <img
                src={activeItem.imagen_url}
                alt={activeItem.titulo}
                className="w-full h-full object-contain max-h-[50vh] md:max-h-[80vh]"
              />
            </div>

            <div className="md:w-2/5 p-5 sm:p-8 flex flex-col justify-between bg-white overflow-y-auto">
              <div>
                <div className="flex items-center gap-2 mb-3 flex-wrap">
                  <span className="px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider bg-[#fdf2f8] text-[#b10e6b]">
                    {activeItem.categoria}
                  </span>
                  {activeItem.destacado && (
                    <span className="px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider bg-amber-50 text-amber-700">
                      Favorito
                    </span>
                  )}
                </div>
                <h3 className="font-serif text-xl sm:text-2xl font-bold text-[#0b1c30] mb-2 sm:mb-3">
                  {activeItem.titulo}
                </h3>
                <p className="text-xs sm:text-sm text-[#515f74] leading-relaxed mb-4 sm:mb-6">
                  {activeItem.descripcion || 'Trabajo profesional realizado con técnicas de última generación y productos de máxima calidad en Peluquería Raquel.'}
                </p>
              </div>

              <div className="pt-4 sm:pt-6 border-t border-[#f5e6ed]">
                <p className="text-xs text-[#8b7079] mb-3">
                  ¿Te gustaría un resultado similar en tu cabello?
                </p>
                <a
                  href={buildWhatsAppUrl(`¡Hola ${SALON_CONFIG.nombre}! 💇‍♀️ Me encantó este trabajo de la galería: "${activeItem.titulo}" y quisiera consultar disponibilidad.`)}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-full inline-flex items-center justify-center gap-2 py-3 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs uppercase tracking-wider shadow-md hover:shadow-lg transition-all active:scale-95"
                >
                  <MessageCircle className="w-4 h-4" />
                  Consultar por WhatsApp
                </a>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
