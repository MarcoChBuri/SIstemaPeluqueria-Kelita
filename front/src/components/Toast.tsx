import React from 'react';
import { CheckCircle2, Sparkles, X } from 'lucide-react';

interface ToastProps {
  message: string | null;
  onClose: () => void;
}

export const Toast: React.FC<ToastProps> = ({ message, onClose }) => {
  if (!message) return null;

  return (
    <div className="fixed bottom-20 lg:bottom-8 right-4 sm:right-8 z-50 flex items-center gap-3 px-4 py-3 rounded-2xl bg-[#0b1c30] text-white shadow-2xl border border-white/10 animate-in slide-in-from-bottom-5 duration-300">
      <div className="w-7 h-7 rounded-full bg-[#b10e6b] flex items-center justify-center text-white shrink-0">
        <Sparkles className="w-4 h-4" />
      </div>
      <span className="text-xs sm:text-sm font-medium pr-2">{message}</span>
      <button
        onClick={onClose}
        className="p-1 rounded-full hover:bg-white/10 text-white/70 hover:text-white transition-colors"
      >
        <X className="w-4 h-4" />
      </button>
    </div>
  );
};
