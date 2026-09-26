import React, { useState, useEffect } from 'react';
import {
  Menu,
  X,
  Scissors,
  CalendarDays,
  Image as ImageIcon,
  GraduationCap,
  Tag,
  Phone,
  MapPin,
  Clock,
  Instagram,
  Facebook,
  MessageCircle,
  ChevronRight,
  Home,
} from 'lucide-react';
import { SALON_CONFIG, buildWhatsAppUrl } from '../../config/salonConfig';

type ClientSection = 'inicio' | 'servicios' | 'galeria' | 'cursos' | 'promos' | 'reservar';

interface ClientLayoutProps {
  children: React.ReactNode;
  activeSection: ClientSection;
  onNavigate: (section: ClientSection) => void;
  onGoToAdmin: () => void;
}

export const ClientLayout: React.FC<ClientLayoutProps> = ({
  children,
  activeSection,
  onNavigate,
  onGoToAdmin,
}) => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 20);
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navItems: { id: ClientSection; label: string; icon: React.ReactNode }[] = [
    { id: 'inicio', label: 'Inicio', icon: <Home className="w-4 h-4" /> },
    { id: 'servicios', label: 'Servicios', icon: <Scissors className="w-4 h-4" /> },
    { id: 'galeria', label: 'Galería', icon: <ImageIcon className="w-4 h-4" /> },
    { id: 'cursos', label: 'Cursos', icon: <GraduationCap className="w-4 h-4" /> },
    { id: 'promos', label: 'Promos', icon: <Tag className="w-4 h-4" /> },
  ];

  const handleWhatsAppGeneralClick = () => {
    const msg = `¡Hola ${SALON_CONFIG.nombre}! 💇‍♀️ Me gustaría obtener información sobre citas y servicios.`;
    window.open(buildWhatsAppUrl(msg), '_blank', 'noopener,noreferrer');
  };

  return (
    <div className="min-h-screen bg-[#fefcfd] text-[#0b1c30] font-sans flex flex-col">
      {/* ═══════════════════ NAVBAR ═══════════════════ */}
      <header
        className={`sticky top-0 z-50 bg-white/90 backdrop-blur-xl border-b border-[#f5e6ed] transition-all duration-300 ${
          scrolled ? 'shadow-lg shadow-black/5' : 'shadow-[0_1px_12px_rgba(177,14,107,0.04)]'
        }`}
      >
        <div className="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8">
          <div className={`flex items-center justify-between transition-all duration-300 ${
            scrolled ? 'h-14' : 'h-16 sm:h-20'
          }`}>
            {/* Logo */}
            <button
              onClick={() => onNavigate('inicio')}
              className="flex items-center gap-2 sm:gap-3 group cursor-pointer"
            >
              <div className={`rounded-full bg-gradient-to-tr from-[#b10e6b] via-[#d23284] to-[#ec4899] flex items-center justify-center text-white font-serif font-bold shadow-lg shadow-[#b10e6b]/20 group-hover:shadow-[#b10e6b]/40 transition-all duration-300 ${
                scrolled ? 'w-8 h-8 text-sm' : 'w-9 h-9 sm:w-10 sm:h-10 text-base sm:text-lg'
              }`}>
                {SALON_CONFIG.letraLogo}
              </div>
              <div className="flex flex-col text-left">
                <span className={`font-serif font-bold text-[#0b1c30] tracking-tight leading-none transition-all duration-300 ${
                  scrolled ? 'text-sm sm:text-base' : 'text-base sm:text-xl'
                }`}>
                  {SALON_CONFIG.nombre}
                </span>
                <span className="text-[8px] sm:text-[10px] uppercase tracking-[0.2em] text-[#b10e6b] font-semibold hidden sm:block">
                  {SALON_CONFIG.eslogan}
                </span>
              </div>
            </button>

            {/* Desktop Nav */}
            <nav className="hidden md:flex items-center gap-1">
              {navItems.map((item) => (
                <button
                  key={item.id}
                  onClick={() => onNavigate(item.id)}
                  className={`flex items-center gap-1.5 px-4 py-2 rounded-full text-sm font-medium transition-all cursor-pointer ${
                    activeSection === item.id
                      ? 'bg-[#b10e6b] text-white shadow-sm shadow-[#b10e6b]/20'
                      : 'text-[#515f74] hover:text-[#b10e6b] hover:bg-[#fdf2f8]'
                  }`}
                >
                  {item.icon}
                  <span>{item.label}</span>
                </button>
              ))}
            </nav>

            {/* CTA + Mobile Toggle (NO admin button here) */}
            <div className="flex items-center gap-2">
              <button
                onClick={() => onNavigate('reservar')}
                className={`hidden sm:flex items-center gap-2 rounded-full bg-gradient-to-r from-[#b10e6b] to-[#d23284] hover:from-[#930b58] hover:to-[#b10e6b] text-white font-bold shadow-lg shadow-[#b10e6b]/25 transition-all active:scale-95 cursor-pointer ${
                  scrolled ? 'px-4 py-2 text-xs' : 'px-5 py-2.5 text-xs sm:text-sm'
                }`}
              >
                <CalendarDays className="w-4 h-4" />
                <span>Reservar Cita</span>
              </button>

              <button
                onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                className="md:hidden p-2 rounded-xl hover:bg-[#fdf2f8] text-[#515f74] transition-colors cursor-pointer"
              >
                {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
              </button>
            </div>
          </div>

          {/* Mobile Menu */}
          <div
            className={`md:hidden overflow-hidden transition-all duration-300 ease-in-out ${
              mobileMenuOpen ? 'max-h-[400px] opacity-100 pb-4' : 'max-h-0 opacity-0'
            }`}
          >
            <div className="border-t border-[#f5e6ed] pt-3">
              <div className="flex flex-col gap-1">
                {navItems.map((item) => (
                  <button
                    key={item.id}
                    onClick={() => {
                      onNavigate(item.id);
                      setMobileMenuOpen(false);
                    }}
                    className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all cursor-pointer ${
                      activeSection === item.id
                        ? 'bg-[#b10e6b] text-white'
                        : 'text-[#515f74] hover:bg-[#fdf2f8]'
                    }`}
                  >
                    {item.icon}
                    <span>{item.label}</span>
                  </button>
                ))}
                <button
                  onClick={() => {
                    onNavigate('reservar');
                    setMobileMenuOpen(false);
                  }}
                  className="mt-2 flex items-center justify-center gap-2 px-5 py-3.5 rounded-xl bg-gradient-to-r from-[#b10e6b] to-[#d23284] text-white text-sm font-bold cursor-pointer shadow-lg active:scale-95 transition-all"
                >
                  <CalendarDays className="w-4 h-4" />
                  <span>Reservar Cita</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* ═══════════════════ MAIN CONTENT ═══════════════════ */}
      <main className="flex-1">{children}</main>

      {/* ═══════════════════ FOOTER ═══════════════════ */}
      <footer className="bg-[#0b1c30] text-white/80 mt-auto">
        {/* CTA Banner */}
        <div className="bg-gradient-to-r from-[#b10e6b] to-[#d23284] py-10 sm:py-14">
          <div className="max-w-4xl mx-auto text-center px-4 sm:px-6">
            <h2 className="font-serif text-xl sm:text-3xl lg:text-4xl font-bold text-white mb-3">
              ¿Lista para transformar tu look?
            </h2>
            <p className="text-white/80 text-xs sm:text-sm mb-6 max-w-xl mx-auto">
              Agenda tu cita directo por WhatsApp y deja que {SALON_CONFIG.duena} haga su magia.
            </p>
            <button
              onClick={() => onNavigate('reservar')}
              className="inline-flex items-center gap-2 px-6 sm:px-8 py-3 sm:py-3.5 rounded-full bg-white text-[#b10e6b] font-bold text-sm shadow-xl hover:shadow-2xl transition-all active:scale-95 cursor-pointer"
            >
              <CalendarDays className="w-5 h-5" />
              <span>Reserva tu Cita Ahora</span>
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Footer Info */}
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10 sm:py-12 grid grid-cols-2 lg:grid-cols-4 gap-6 sm:gap-8">
          {/* Brand */}
          <div className="col-span-2 lg:col-span-1">
            <div className="flex items-center gap-2 mb-4">
              <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-[#b10e6b] to-[#ec4899] flex items-center justify-center text-white font-serif font-bold text-sm">
                {SALON_CONFIG.letraLogo}
              </div>
              <span className="font-serif text-lg font-bold text-white">{SALON_CONFIG.nombre}</span>
            </div>
            <p className="text-xs sm:text-sm text-white/60 leading-relaxed">
              Experta en colorimetría, alisados orgánicos, peinados de novia y tratamientos capilares de alta gama.
            </p>
          </div>

          {/* Horarios */}
          <div>
            <h4 className="text-xs uppercase tracking-widest font-bold text-[#ec4899] mb-3 sm:mb-4">Horarios</h4>
            <ul className="space-y-2 text-xs sm:text-sm">
              <li className="flex items-center gap-2">
                <Clock className="w-3.5 h-3.5 text-[#ec4899] shrink-0" />
                <span>Lun-Vie: {SALON_CONFIG.horarios.lunesViernes}</span>
              </li>
              <li className="flex items-center gap-2">
                <Clock className="w-3.5 h-3.5 text-[#ec4899] shrink-0" />
                <span>Sáb: {SALON_CONFIG.horarios.sabados}</span>
              </li>
              <li className="flex items-center gap-2">
                <Clock className="w-3.5 h-3.5 text-[#ec4899] shrink-0" />
                <span>Dom: {SALON_CONFIG.horarios.domingos}</span>
              </li>
            </ul>
          </div>

          {/* Contacto */}
          <div>
            <h4 className="text-xs uppercase tracking-widest font-bold text-[#ec4899] mb-3 sm:mb-4">Contacto</h4>
            <ul className="space-y-2 text-xs sm:text-sm">
              <li className="flex items-center gap-2">
                <Phone className="w-3.5 h-3.5 text-[#ec4899] shrink-0" />
                <button onClick={handleWhatsAppGeneralClick} className="hover:text-emerald-400 underline text-left cursor-pointer">
                  WhatsApp: {SALON_CONFIG.whatsappNumber}
                </button>
              </li>
              <li className="flex items-center gap-2">
                <MapPin className="w-3.5 h-3.5 text-[#ec4899] shrink-0" />
                <span>{SALON_CONFIG.direccion}</span>
              </li>
            </ul>
          </div>

          {/* Redes */}
          <div>
            <h4 className="text-xs uppercase tracking-widest font-bold text-[#ec4899] mb-3 sm:mb-4">Síguenos</h4>
            <div className="flex items-center gap-3">
              <a href={SALON_CONFIG.instagramUrl} target="_blank" rel="noopener noreferrer" className="w-9 h-9 sm:w-10 sm:h-10 rounded-full bg-white/10 hover:bg-[#b10e6b] flex items-center justify-center transition-colors">
                <Instagram className="w-4 h-4 sm:w-5 sm:h-5" />
              </a>
              <a href={SALON_CONFIG.facebookUrl} target="_blank" rel="noopener noreferrer" className="w-9 h-9 sm:w-10 sm:h-10 rounded-full bg-white/10 hover:bg-[#b10e6b] flex items-center justify-center transition-colors">
                <Facebook className="w-4 h-4 sm:w-5 sm:h-5" />
              </a>
              <button onClick={handleWhatsAppGeneralClick} className="w-9 h-9 sm:w-10 sm:h-10 rounded-full bg-white/10 hover:bg-emerald-600 flex items-center justify-center transition-colors cursor-pointer">
                <MessageCircle className="w-4 h-4 sm:w-5 sm:h-5 text-emerald-400" />
              </button>
            </div>
          </div>
        </div>

        {/* Bottom Bar – Admin link is tiny here only */}
        <div className="border-t border-white/10 py-4 px-4 sm:px-6">
          <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-2 text-xs text-white/40">
            <span>© {new Date().getFullYear()} {SALON_CONFIG.nombre}. Todos los derechos reservados.</span>
            <button
              onClick={onGoToAdmin}
              className="text-white/15 hover:text-white/40 transition-colors cursor-pointer text-[10px]"
            >
              Panel Admin
            </button>
          </div>
        </div>
      </footer>
    </div>
  );
};
