import React, { useState, useEffect } from 'react';
import { NavigationTab, Cita, Servicio, Promocion, ReporteFinanciero } from './types';
import { getCitas, getServicios, getPromociones, getReporteSimple } from './services/api';
import { NavigationSidebar } from './components/NavigationSidebar';
import { TopHeader } from './components/TopHeader';
import { MobileNavBar } from './components/MobileNavBar';
import { DashboardView } from './components/DashboardView';
import { AgendaCitasView } from './components/AgendaCitasView';
import { ServiciosView } from './components/ServiciosView';
import { CalculadoraView } from './components/CalculadoraView';
import { PromocionesView } from './components/PromocionesView';
import { GastosVentasView } from './components/GastosVentasView';
import { GaleriaCursosView } from './components/GaleriaCursosView';
import { NewAppointmentModal } from './components/NewAppointmentModal';
import { Toast } from './components/Toast';

// Client Portal Components
import { ClientLayout } from './components/client/ClientLayout';
import { ClientLanding } from './components/client/ClientLanding';
import { ClientServicios } from './components/client/ClientServicios';
import { ClientGaleria } from './components/client/ClientGaleria';
import { ClientCursos } from './components/client/ClientCursos';
import { ClientPromos } from './components/client/ClientPromos';
import { ClientReserva } from './components/client/ClientReserva';

type ClientSection = 'inicio' | 'servicios' | 'galeria' | 'cursos' | 'promos' | 'reservar';

export function App() {
  // Inicializar según la URL (#admin o /admin)
  const [appMode, setAppMode] = useState<'client' | 'admin'>(() => {
    if (typeof window !== 'undefined') {
      const hash = window.location.hash.toLowerCase();
      const path = window.location.pathname.toLowerCase();
      if (hash.includes('admin') || path.includes('admin')) {
        return 'admin';
      }
    }
    return 'client';
  });

  const [clientSection, setClientSection] = useState<ClientSection>('inicio');

  // Escuchar cambios de hash (ej. si el usuario escribe #admin en la URL)
  useEffect(() => {
    const handleHashChange = () => {
      const hash = window.location.hash.toLowerCase();
      if (hash.includes('admin')) {
        setAppMode('admin');
      } else {
        setAppMode('client');
      }
    };
    window.addEventListener('hashchange', handleHashChange);
    return () => window.removeEventListener('hashchange', handleHashChange);
  }, []);

  const goToAdmin = () => {
    setAppMode('admin');
    window.location.hash = 'admin';
  };

  const goToClient = () => {
    setAppMode('client');
    window.location.hash = '';
  };

  // Estado del panel admin
  const [activeTab, setActiveTab] = useState<NavigationTab>('dashboard');
  const [citas, setCitas] = useState<Cita[]>([]);
  const [servicios, setServicios] = useState<Servicio[]>([]);
  const [promociones, setPromociones] = useState<Promocion[]>([]);
  const [reporte, setReporte] = useState<ReporteFinanciero | null>(null);
  const [searchQuery, setSearchQuery] = useState<string>('');

  const [isNewAppointmentOpen, setIsNewAppointmentOpen] = useState<boolean>(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  const showToast = (message: string) => {
    setToastMessage(message);
    setTimeout(() => {
      setToastMessage((prev) => (prev === message ? null : prev));
    }, 4000);
  };

  const loadData = async () => {
    try {
      setIsLoading(true);
      const [resCitas, resServicios, resPromos, resReporte] = await Promise.all([
        getCitas().catch(() => []),
        getServicios().catch(() => ({ servicios: [], paquetes_especiales: [], servicios_regulares: [] })),
        getPromociones().catch(() => []),
        getReporteSimple().catch(() => null),
      ]);

      setCitas(resCitas);
      setServicios(resServicios.servicios || []);
      setPromociones(resPromos);
      setReporte(resReporte);
    } catch (err: any) {
      console.error('[App] Error al cargar datos del backend:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleAppointmentCreated = (newCita: Cita) => {
    setCitas((prev) => [newCita, ...prev]);
    showToast(`Cita de ${newCita.cliente_nombre} agendada correctamente.`);
    getReporteSimple().then((r) => setReporte(r)).catch(() => {});
  };

  const handleAppointmentUpdated = (updated: Cita) => {
    setCitas((prev) => prev.map((c) => (c.id === updated.id ? updated : c)));
    showToast(`Cita de ${updated.cliente_nombre} actualizada.`);
    getReporteSimple().then((r) => setReporte(r)).catch(() => {});
  };

  const handleServicioCreated = (newServ: Servicio) => {
    setServicios((prev) => [...prev, newServ]);
    showToast(`Servicio "${newServ.nombre}" creado exitosamente.`);
  };

  const handlePromocionCreated = (newPromo: Promocion) => {
    setPromociones((prev) => [...prev, newPromo]);
    showToast(`Promoción "${newPromo.titulo}" creada exitosamente.`);
  };

  // ═══════════════════════════════════════════════════════════════════
  // RENDER: PORTAL CLIENTE
  // ═══════════════════════════════════════════════════════════════════
  if (appMode === 'client') {
    return (
      <ClientLayout
        activeSection={clientSection}
        onNavigate={(sec) => {
          setClientSection(sec);
          window.scrollTo({ top: 0, behavior: 'smooth' });
        }}
        onGoToAdmin={goToAdmin}
      >
        {clientSection === 'inicio' && (
          <ClientLanding
            onNavigate={(sec) => {
              setClientSection(sec as ClientSection);
              window.scrollTo({ top: 0, behavior: 'smooth' });
            }}
          />
        )}
        {clientSection === 'servicios' && (
          <ClientServicios
            onReservar={() => {
              setClientSection('reservar');
              window.scrollTo({ top: 0, behavior: 'smooth' });
            }}
          />
        )}
        {clientSection === 'galeria' && <ClientGaleria />}
        {clientSection === 'cursos' && <ClientCursos />}
        {clientSection === 'promos' && (
          <ClientPromos
            onReservar={() => {
              setClientSection('reservar');
              window.scrollTo({ top: 0, behavior: 'smooth' });
            }}
          />
        )}
        {clientSection === 'reservar' && <ClientReserva />}
      </ClientLayout>
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // RENDER: PANEL ADMINISTRADOR (RAQUEL)
  // ═══════════════════════════════════════════════════════════════════
  return (
    <div className="min-h-screen bg-[#f8f9ff] text-[#0b1c30] flex flex-col md:flex-row font-sans selection:bg-[#ec4899]/20 selection:text-[#b10e6b]">
      {/* Botón flotante para volver a la vista del cliente */}
      <div className="fixed bottom-4 right-4 z-40">
        <button
          onClick={goToClient}
          className="flex items-center gap-2 px-4 py-2.5 rounded-full bg-[#0b1c30] text-white text-xs font-bold shadow-xl hover:bg-[#b10e6b] transition-all cursor-pointer border border-white/20"
        >
          <span>👁️ Ver Portal de Clientes</span>
        </button>
      </div>

      {/* Sidebar Desktop */}
      <NavigationSidebar
        activeTab={activeTab}
        onSelectTab={(tab) => {
          setActiveTab(tab);
          window.scrollTo({ top: 0, behavior: 'smooth' });
        }}
        onNewAppointmentClick={() => setIsNewAppointmentOpen(true)}
      />

      {/* Main Administrative Container */}
      <main className="flex-1 flex flex-col min-w-0 pb-20 md:pb-8">
        <TopHeader
          searchQuery={searchQuery}
          onSearchChange={setSearchQuery}
          onNewAppointmentClick={() => setIsNewAppointmentOpen(true)}
        />

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-6 w-full space-y-8">
          {activeTab === 'dashboard' && (
            <DashboardView
              reporte={reporte}
              citas={citas}
              promociones={promociones}
              onNavigate={(tab) => setActiveTab(tab)}
              onOpenNewAppointment={() => setIsNewAppointmentOpen(true)}
            />
          )}

          {activeTab === 'citas' && (
            <AgendaCitasView
              citas={citas}
              servicios={servicios}
              onOpenNewAppointment={() => setIsNewAppointmentOpen(true)}
              onAppointmentUpdated={handleAppointmentUpdated}
              onShowToast={showToast}
            />
          )}

          {activeTab === 'servicios' && (
            <ServiciosView
              servicios={servicios}
              onServicioCreated={handleServicioCreated}
              onSelectServicioParaCita={() => {
                setIsNewAppointmentOpen(true);
              }}
              onShowToast={showToast}
            />
          )}

          {activeTab === 'calculadora' && (
            <CalculadoraView
              onScheduleAppointmentWithPrice={(precio) => {
                setIsNewAppointmentOpen(true);
                showToast(`Precio estimado: $${precio.toFixed(2)}. Completa los datos para agendar.`);
              }}
              onShowToast={showToast}
            />
          )}

          {activeTab === 'promociones' && (
            <PromocionesView
              promociones={promociones}
              onPromocionCreated={handlePromocionCreated}
              onApplyPromoToCita={() => {
                setIsNewAppointmentOpen(true);
              }}
              onShowToast={showToast}
            />
          )}

          {activeTab === 'gastos' && (
            <GastosVentasView
              onDataChanged={() => {
                getReporteSimple().then((r) => setReporte(r)).catch(() => {});
              }}
              onShowToast={showToast}
            />
          )}

          {activeTab === 'galeria' && (
            <GaleriaCursosView
              onShowToast={showToast}
            />
          )}
        </div>
      </main>

      {/* Mobile Bottom Navigation Bar (Admin) */}
      <MobileNavBar
        activeTab={activeTab}
        onSelectTab={(tab) => {
          setActiveTab(tab);
          window.scrollTo({ top: 0, behavior: 'smooth' });
        }}
      />

      {/* Modal Nueva Cita */}
      <NewAppointmentModal
        isOpen={isNewAppointmentOpen}
        onClose={() => setIsNewAppointmentOpen(false)}
        servicios={servicios}
        promociones={promociones}
        onAppointmentCreated={handleAppointmentCreated}
      />

      {/* Global Interactive Toast Notification */}
      <Toast message={toastMessage} onClose={() => setToastMessage(null)} />
    </div>
  );
}

export default App;
