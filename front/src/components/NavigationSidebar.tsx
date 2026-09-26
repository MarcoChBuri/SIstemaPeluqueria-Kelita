import React from 'react';
import {
  LayoutDashboard,
  CalendarDays,
  Scissors,
  Calculator,
  Tag,
  DollarSign,
  Image as ImageIcon,
  Armchair,
} from 'lucide-react';
import { NavigationTab } from '../types';

interface NavigationSidebarProps {
  activeTab: NavigationTab;
  onSelectTab: (tab: NavigationTab) => void;
  onNewAppointmentClick?: () => void;
  completedAppointmentsCount?: number;
  totalAppointmentsCount?: number;
}

export const NavigationSidebar: React.FC<NavigationSidebarProps> = ({
  activeTab,
  onSelectTab,
  completedAppointmentsCount = 0,
  totalAppointmentsCount = 0,
}) => {
  const capacityPercent =
    totalAppointmentsCount > 0
      ? Math.min(100, Math.round((completedAppointmentsCount / totalAppointmentsCount) * 100))
      : 0;

  const navItems: { id: NavigationTab; label: string; icon: React.ReactNode }[] = [
    {
      id: 'dashboard',
      label: 'Panel General',
      icon: <LayoutDashboard className="w-5 h-5" />,
    },
    {
      id: 'citas',
      label: 'Agenda de Citas',
      icon: <CalendarDays className="w-5 h-5" />,
    },
    {
      id: 'servicios',
      label: 'Servicios y Paquetes',
      icon: <Scissors className="w-5 h-5" />,
    },
    {
      id: 'calculadora',
      label: 'Calculadora de Tintes',
      icon: <Calculator className="w-5 h-5" />,
    },
    {
      id: 'promociones',
      label: 'Promociones del Mes',
      icon: <Tag className="w-5 h-5" />,
    },
    {
      id: 'gastos',
      label: 'Gastos y Ventas',
      icon: <DollarSign className="w-5 h-5" />,
    },
    {
      id: 'galeria',
      label: 'Galería y Cursos',
      icon: <ImageIcon className="w-5 h-5" />,
    },
  ];

  return (
    <aside className="hidden lg:flex fixed left-0 top-0 h-full w-72 bg-white z-50 flex-col justify-between border-r border-[#eff4ff] shadow-[0_1px_8px_rgba(0,0,0,0.04)]">
      <div className="flex flex-col">
        {/* Salon Brand Banner */}
        <div className="h-20 px-6 flex items-center gap-3 bg-white border-b border-[#f8f9ff]">
          <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-[#b10e6b] to-[#ec4899] flex items-center justify-center text-white font-serif font-bold text-xl shadow-md">
            R
          </div>
          <div className="flex flex-col">
            <span className="font-serif text-xl font-bold text-[#0b1c30] tracking-tight">
              Peluquería Raquel
            </span>
            <span className="text-[10px] uppercase tracking-widest text-[#b10e6b] font-bold">
              Control & Gestión
            </span>
          </div>
        </div>

        {/* Navigation Items List */}
        <nav className="flex flex-col gap-1.5 px-4 py-6">
          {navItems.map((item) => {
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                id={`sidebar-nav-${item.id}`}
                onClick={() => onSelectTab(item.id)}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all group text-left cursor-pointer ${
                  isActive
                    ? 'bg-[#d23284] text-white font-semibold shadow-sm'
                    : 'text-[#515f74] hover:bg-[#eff4ff] hover:text-[#0b1c30]'
                }`}
              >
                <span
                  className={`${
                    isActive
                      ? 'text-white'
                      : 'text-[#515f74] group-hover:text-[#b10e6b] transition-colors'
                  }`}
                >
                  {item.icon}
                </span>
                <span>{item.label}</span>
              </button>
            );
          })}
        </nav>
      </div>

      {/* Salon Daily Capacity Widget */}
      <div className="p-4 mx-4 mb-6 rounded-2xl bg-[#eff4ff] border border-[#dce9ff] flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-1.5">
            <Armchair className="w-4 h-4 text-[#515f74]" />
            <span className="text-[10px] uppercase font-bold text-[#515f74] tracking-wider">
              Citas Atendidas
            </span>
          </div>
          <span className="text-xs font-bold text-[#b10e6b] bg-[#ffd9e4] px-2 py-0.5 rounded-full">
            {capacityPercent}%
          </span>
        </div>

        <div className="w-full bg-[#dce9ff] rounded-full h-2 overflow-hidden">
          <div
            className="bg-[#b10e6b] h-full rounded-full transition-all duration-500"
            style={{ width: `${capacityPercent}%` }}
          ></div>
        </div>

        <div className="flex items-center justify-between text-[11px] text-[#515f74]">
          <span>Citas confirmadas</span>
          <span className="font-semibold text-[#0b1c30]">
            {completedAppointmentsCount}/{totalAppointmentsCount}
          </span>
        </div>
      </div>
    </aside>
  );
};
