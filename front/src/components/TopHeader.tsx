import React from 'react';
import { Search, Bell, Plus } from 'lucide-react';

interface TopHeaderProps {
  searchQuery: string;
  onSearchChange: (query: string) => void;
  onOpenNewAppointment?: () => void;
  onNewAppointmentClick?: () => void;
  unreadAlertsCount?: number;
  onOpenNotifications?: () => void;
}

export const TopHeader: React.FC<TopHeaderProps> = ({
  searchQuery,
  onSearchChange,
  onOpenNewAppointment,
  onNewAppointmentClick,
  unreadAlertsCount = 0,
  onOpenNotifications,
}) => {
  const handleOpenAppointment = onOpenNewAppointment || onNewAppointmentClick;
  return (
    <header className="fixed top-0 left-0 lg:left-72 right-0 h-20 bg-white/85 backdrop-blur-xl z-40 border-b border-[#eff4ff] shadow-[0_1px_8px_rgba(0,0,0,0.04)] transition-all">
      <div className="h-20 w-full px-4 sm:px-8 flex items-center justify-between gap-4">
        {/* Search Bar */}
        <div className="flex-1 max-w-md relative">
          <Search className="w-4 h-4 text-[#515f74] absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
          <input
            id="global-search-input"
            type="text"
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder="Buscar por cliente, servicio o fecha..."
            className="w-full pl-10 pr-4 py-2.5 bg-[#eff4ff] rounded-full text-xs sm:text-sm text-[#0b1c30] placeholder:text-[#8b7079] focus:outline-none focus:ring-2 focus:ring-[#b10e6b]/20 focus:bg-white transition-all shadow-xs"
          />
          {searchQuery && (
            <button
              onClick={() => onSearchChange('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-[#8b7079] hover:text-[#0b1c30] cursor-pointer"
            >
              ✕
            </button>
          )}
        </div>

        {/* Right Status & Actions */}
        <div className="flex items-center gap-2.5 sm:gap-4 shrink-0">
          {/* Salon Status Chip */}
          <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-full bg-[#eff4ff] border border-[#dce9ff]">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
            <span className="text-xs font-semibold text-[#0b1c30]">Sistema Activo</span>
          </div>

          {/* Notifications Button */}
          <button
            id="btn-header-notifications"
            onClick={onOpenNotifications}
            className="p-2 sm:p-2.5 rounded-full bg-white hover:bg-[#eff4ff] text-[#515f74] hover:text-[#0b1c30] transition-colors relative shadow-xs border border-[#eff4ff] cursor-pointer"
            title="Notificaciones"
            aria-label="Ver notificaciones"
          >
            <Bell className="w-5 h-5" />
            {unreadAlertsCount > 0 && (
              <span className="absolute top-1 right-1 w-2.5 h-2.5 rounded-full bg-[#b10e6b] ring-2 ring-white"></span>
            )}
          </button>

          {/* New Appointment CTA */}
          <button
            id="btn-header-new-appointment"
            onClick={handleOpenAppointment}
            className="flex items-center gap-1.5 sm:gap-2 px-3.5 sm:px-5 py-2 sm:py-2.5 rounded-full bg-[#b10e6b] hover:bg-[#930b58] text-white text-xs sm:text-sm font-semibold shadow-sm transition-all transform active:scale-95 cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span className="hidden xs:inline">Nueva Cita</span>
          </button>

          {/* Admin User Profile */}
          <div className="flex items-center gap-2.5 pl-2 sm:pl-3 py-1 pr-1.5 rounded-full bg-white border border-[#eff4ff] shadow-xs">
            <div className="hidden md:flex flex-col text-right">
              <span className="text-xs font-bold text-[#0b1c30] leading-tight">Raquel</span>
              <span className="text-[10px] text-[#515f74] leading-tight">Administradora</span>
            </div>
            <div className="w-8 h-8 rounded-full bg-[#b10e6b] text-white flex items-center justify-center font-bold text-xs ring-2 ring-[#ffd9e4]">
              R
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};
