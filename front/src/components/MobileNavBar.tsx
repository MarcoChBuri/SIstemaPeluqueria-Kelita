import React from 'react';
import {
  LayoutDashboard,
  CalendarDays,
  Scissors,
  Calculator,
  DollarSign,
  Tag,
  Image as ImageIcon,
} from 'lucide-react';
import { NavigationTab } from '../types';

interface MobileNavBarProps {
  activeTab: NavigationTab;
  onSelectTab: (tab: NavigationTab) => void;
}

export const MobileNavBar: React.FC<MobileNavBarProps> = ({ activeTab, onSelectTab }) => {
  const items: { id: NavigationTab; label: string; icon: React.ReactNode }[] = [
    {
      id: 'dashboard',
      label: 'Panel',
      icon: <LayoutDashboard className="w-4 h-4 sm:w-5 sm:h-5" />,
    },
    {
      id: 'citas',
      label: 'Citas',
      icon: <CalendarDays className="w-4 h-4 sm:w-5 sm:h-5" />,
    },
    {
      id: 'servicios',
      label: 'Servicios',
      icon: <Scissors className="w-4 h-4 sm:w-5 sm:h-5" />,
    },
    {
      id: 'promociones',
      label: 'Promos',
      icon: <Tag className="w-4 h-4 sm:w-5 sm:h-5" />,
    },
    {
      id: 'calculadora',
      label: 'Tintes',
      icon: <Calculator className="w-4 h-4 sm:w-5 sm:h-5" />,
    },
    {
      id: 'gastos',
      label: 'Gastos',
      icon: <DollarSign className="w-4 h-4 sm:w-5 sm:h-5" />,
    },
    {
      id: 'galeria',
      label: 'Galería',
      icon: <ImageIcon className="w-4 h-4 sm:w-5 sm:h-5" />,
    },
  ];

  return (
    <div className="lg:hidden fixed bottom-0 left-0 right-0 z-50 bg-white border-t border-[#eff4ff] px-1 py-1.5 sm:py-2 flex items-center justify-around shadow-lg overflow-x-auto scrollbar-none">
      {items.map((item) => {
        const isActive = activeTab === item.id;
        return (
          <button
            key={item.id}
            onClick={() => onSelectTab(item.id)}
            className={`flex flex-col items-center gap-0.5 py-1 px-1.5 sm:px-3 rounded-xl text-[9px] sm:text-[11px] font-medium transition-all shrink-0 ${
              isActive ? 'text-[#b10e6b] font-bold' : 'text-[#515f74]'
            }`}
          >
            {item.icon}
            <span>{item.label}</span>
          </button>
        );
      })}
    </div>
  );
};
