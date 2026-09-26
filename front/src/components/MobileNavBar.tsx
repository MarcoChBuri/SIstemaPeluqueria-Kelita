import React from 'react';
import {
  LayoutDashboard,
  CalendarDays,
  Scissors,
  Calculator,
  DollarSign,
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
      icon: <LayoutDashboard className="w-5 h-5" />,
    },
    {
      id: 'citas',
      label: 'Citas',
      icon: <CalendarDays className="w-5 h-5" />,
    },
    {
      id: 'servicios',
      label: 'Servicios',
      icon: <Scissors className="w-5 h-5" />,
    },
    {
      id: 'calculadora',
      label: 'Tintes',
      icon: <Calculator className="w-5 h-5" />,
    },
    {
      id: 'gastos',
      label: 'Gastos',
      icon: <DollarSign className="w-5 h-5" />,
    },
  ];

  return (
    <div className="lg:hidden fixed bottom-0 left-0 right-0 z-50 bg-white border-t border-[#eff4ff] px-2 py-2 flex items-center justify-around shadow-lg">
      {items.map((item) => {
        const isActive = activeTab === item.id;
        return (
          <button
            key={item.id}
            onClick={() => onSelectTab(item.id)}
            className={`flex flex-col items-center gap-1 py-1 px-3 rounded-xl text-[11px] font-medium transition-all ${
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
