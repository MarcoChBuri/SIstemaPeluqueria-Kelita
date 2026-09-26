import React, { useState, useEffect } from 'react';
import { Image as ImageIcon, GraduationCap, Plus, ExternalLink, Sparkles } from 'lucide-react';
import { GaleriaItem, CursoItem } from '../types';
import { getGaleria, getCursos } from '../services/api';

interface GaleriaCursosViewProps {
  onShowToast: (message: string) => void;
}

export const GaleriaCursosView: React.FC<GaleriaCursosViewProps> = ({ onShowToast }) => {
  const [activeTab, setActiveTab] = useState<'galeria' | 'cursos'>('galeria');
  const [trabajos, setTrabajos] = useState<GaleriaItem[]>([]);
  const [cursos, setCursos] = useState<CursoItem[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(false);

  useEffect(() => {
    async function load() {
      try {
        setIsLoading(true);
        const [resGaleria, resCursos] = await Promise.all([
          getGaleria().catch(() => []),
          getCursos().catch(() => []),
        ]);
        setTrabajos(resGaleria);
        setCursos(resCursos);
      } catch (err: any) {
        console.error(err);
      } finally {
        setIsLoading(false);
      }
    }
    load();
  }, []);

  return (
    <div className="flex flex-col gap-6 w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-[#eff4ff] shadow-xs">
        <div>
          <span className="text-[10px] uppercase tracking-widest text-[#b10e6b] font-bold">
            Portafolio & Formación
          </span>
          <h1 className="font-serif text-2xl sm:text-3xl font-bold text-[#0b1c30]">
            Galería y Cursos Online
          </h1>
          <p className="text-xs text-[#515f74] mt-0.5">
            Fotos de transformaciones capilares y programas de capacitación en Hotmart.
          </p>
        </div>
      </div>

      {/* Switcher */}
      <div className="flex items-center gap-2 border-b border-[#eff4ff] pb-2">
        <button
          onClick={() => setActiveTab('galeria')}
          className={`flex items-center gap-2 px-5 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
            activeTab === 'galeria'
              ? 'bg-[#b10e6b] text-white shadow-xs'
              : 'bg-white text-[#515f74] hover:bg-[#eff4ff]'
          }`}
        >
          <ImageIcon className="w-4 h-4" />
          <span>Galería de Trabajos ({trabajos.length})</span>
        </button>
        <button
          onClick={() => setActiveTab('cursos')}
          className={`flex items-center gap-2 px-5 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
            activeTab === 'cursos'
              ? 'bg-[#b10e6b] text-white shadow-xs'
              : 'bg-white text-[#515f74] hover:bg-[#eff4ff]'
          }`}
        >
          <GraduationCap className="w-4 h-4" />
          <span>Cursos Hotmart ({cursos.length})</span>
        </button>
      </div>

      {/* Content */}
      {activeTab === 'galeria' ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {trabajos.map((item) => (
            <div
              key={item.id}
              className="bg-white rounded-2xl overflow-hidden border border-[#eff4ff] shadow-xs hover:shadow-md transition-all flex flex-col justify-between"
            >
              <div className="relative aspect-4/3 w-full bg-slate-100 overflow-hidden">
                <img
                  src={item.imagen_url}
                  alt={item.titulo}
                  className="w-full h-full object-cover"
                />
                <span className="absolute top-3 left-3 px-2.5 py-1 rounded-full text-[10px] font-bold uppercase bg-white/90 backdrop-blur-xs text-[#b10e6b]">
                  {item.categoria}
                </span>
              </div>
              <div className="p-4">
                <h3 className="font-serif text-base font-bold text-[#0b1c30] mb-1">{item.titulo}</h3>
                <p className="text-xs text-[#515f74]">{item.descripcion || 'Transformación profesional.'}</p>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {cursos.map((c) => (
            <div
              key={c.id}
              className="bg-white rounded-2xl p-6 border border-[#eff4ff] shadow-xs hover:shadow-md transition-all flex flex-col justify-between"
            >
              <div>
                <div className="flex items-center justify-between mb-3">
                  <span className="px-3 py-1 rounded-full text-[10px] font-bold bg-[#ffd9e4] text-[#b10e6b]">
                    Hotmart Online
                  </span>
                  <span className="text-lg font-serif font-bold text-[#0b1c30]">
                    ${Number(c.precio_referencia).toFixed(2)}
                  </span>
                </div>
                <h3 className="font-serif text-xl font-bold text-[#0b1c30] mb-2">{c.titulo}</h3>
                <p className="text-xs text-[#515f74] mb-6">{c.descripcion}</p>
              </div>

              <a
                href={c.link_hotmart}
                target="_blank"
                rel="noopener noreferrer"
                className="w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-full bg-[#eff4ff] hover:bg-[#b10e6b] hover:text-white text-[#b10e6b] font-bold text-xs transition-all"
              >
                <span>Acceder en Hotmart</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
