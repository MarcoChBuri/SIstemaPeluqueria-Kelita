import React, { useEffect, useState } from 'react';
import { GraduationCap, ExternalLink, BookOpen, Clock, Award, Sparkles } from 'lucide-react';
import { CursoHotmart } from '../../types';
import { getCursos } from '../../services/api';

export const ClientCursos: React.FC = () => {
  const [cursos, setCursos] = useState<CursoHotmart[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    getCursos()
      .then((data) => setCursos(data))
      .catch((err) => console.error('Error cargando cursos:', err))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="min-h-screen bg-[#fefcfd] pb-24">
      {/* Header */}
      <div className="bg-gradient-to-br from-[#0b1c30] to-[#1a2d45] text-white py-16 sm:py-20 px-6">
        <div className="max-w-4xl mx-auto text-center">
          <span className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-white/10 text-white/90 text-xs font-bold uppercase tracking-widest mb-4">
            <GraduationCap className="w-4 h-4 text-[#ec4899]" />
            Capacitación Profesional
          </span>
          <h1 className="font-serif text-3xl sm:text-5xl font-bold mb-4">
            Cursos Online & Masterclasses
          </h1>
          <p className="text-white/70 max-w-xl mx-auto text-sm sm:text-base leading-relaxed">
            Aprende las técnicas, secretos de colorimetría y peinados de la mano de Raquel. Acceso 100% online con certificación.
          </p>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-6 py-12">
        {loading ? (
          <div className="text-center py-20 text-[#515f74]">
            <div className="w-10 h-10 border-4 border-[#b10e6b] border-t-transparent rounded-full animate-spin mx-auto mb-4" />
            <p className="text-sm font-medium">Cargando cursos disponibles...</p>
          </div>
        ) : cursos.length === 0 ? (
          <div className="text-center py-16 bg-white rounded-3xl border border-[#f5e6ed] p-12 max-w-md mx-auto shadow-xs">
            <GraduationCap className="w-12 h-12 mx-auto mb-3 text-slate-300" />
            <h3 className="font-bold text-[#0b1c30] mb-1">Próximamente más cursos</h3>
            <p className="text-xs text-[#515f74]">
              Raquel está preparando nuevas masterclasses y contenidos online. ¡Vuelve pronto!
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {cursos.map((c) => (
              <div
                key={c.id}
                className="bg-white rounded-3xl overflow-hidden border border-[#f5e6ed] shadow-sm hover:shadow-xl transition-all duration-300 flex flex-col justify-between group"
              >
                <div>
                  <div className="relative aspect-video overflow-hidden bg-slate-900">
                    <img
                      src={c.imagen_url || 'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&q=80&w=800'}
                      alt={c.titulo}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                    />
                    <div className="absolute top-3 left-3 bg-[#b10e6b] text-white text-[10px] font-bold uppercase tracking-wider px-2.5 py-1 rounded-full shadow-md flex items-center gap-1">
                      <Sparkles className="w-3 h-3" /> Hotmart
                    </div>
                  </div>

                  <div className="p-6">
                    <h3 className="font-serif font-bold text-xl text-[#0b1c30] mb-2 group-hover:text-[#b10e6b] transition-colors">
                      {c.titulo}
                    </h3>
                    <p className="text-xs text-[#515f74] leading-relaxed line-clamp-3 mb-4">
                      {c.descripcion || 'Domina técnicas profesionales con lecciones paso a paso, trucos de salón y acompañamiento.'}
                    </p>

                    <div className="grid grid-cols-2 gap-2 py-3 border-y border-[#f5e6ed] text-xs text-[#515f74]">
                      <div className="flex items-center gap-1.5">
                        <BookOpen className="w-3.5 h-3.5 text-[#b10e6b]" />
                        <span>Online 24/7</span>
                      </div>
                      <div className="flex items-center gap-1.5">
                        <Award className="w-3.5 h-3.5 text-[#b10e6b]" />
                        <span>Certificado</span>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="p-6 pt-0">
                  <div className="flex items-center justify-between mb-4">
                    <div>
                      <span className="text-[10px] text-[#515f74] uppercase block font-semibold">Inversión</span>
                      <span className="text-2xl font-serif font-bold text-[#b10e6b]">
                        ${Number(c.precio).toFixed(2)}
                      </span>
                    </div>
                  </div>

                  <a
                    href={c.link_hotmart}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-gradient-to-r from-[#b10e6b] to-[#d23284] hover:from-[#930b58] hover:to-[#b10e6b] text-white font-bold text-xs uppercase tracking-wider shadow-md hover:shadow-lg transition-all"
                  >
                    <span>Inscribirme en Hotmart</span>
                    <ExternalLink className="w-4 h-4" />
                  </a>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
