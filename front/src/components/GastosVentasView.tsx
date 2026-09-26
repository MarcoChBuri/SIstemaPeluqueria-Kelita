import React, { useState, useEffect } from 'react';
import { DollarSign, Plus, ArrowDownRight, TrendingUp, Package, ShoppingBag, Calendar, CheckCircle2 } from 'lucide-react';
import { Gasto, VentaProducto, CategoriaGasto } from '../types';
import { getGastos, createGasto, createVentaProducto, getVentasProductos } from '../services/api';

interface GastosVentasViewProps {
  onDataChanged?: () => void;
  onShowToast: (message: string) => void;
}

export const GastosVentasView: React.FC<GastosVentasViewProps> = ({
  onDataChanged,
  onShowToast,
}) => {
  const [activeSubTab, setActiveSubTab] = useState<'gastos' | 'ventas'>('gastos');

  // Gastos State
  const [gastos, setGastos] = useState<Gasto[]>([]);
  const [totalGastos, setTotalGastos] = useState<number>(0);
  const [isGastoModalOpen, setIsGastoModalOpen] = useState<boolean>(false);
  const [gastoMonto, setGastoMonto] = useState<number>(10);
  const [gastoCategoria, setGastoCategoria] = useState<CategoriaGasto>('productos');
  const [gastoConcepto, setGastoConcepto] = useState<string>('');

  // Ventas State
  const [ventas, setVentas] = useState<VentaProducto[]>([]);
  const [totalVentas, setTotalVentas] = useState<number>(0);
  const [gananciaVentas, setGananciaVentas] = useState<number>(0);
  const [isVentaModalOpen, setIsVentaModalOpen] = useState<boolean>(false);
  const [productoNombre, setProductoNombre] = useState<string>('');
  const [productoCosto, setProductoCosto] = useState<number>(5);
  const [productoPrecio, setProductoPrecio] = useState<number>(15);

  const [isLoading, setIsLoading] = useState<boolean>(false);

  const loadData = async () => {
    try {
      setIsLoading(true);
      const [resGastos, resVentas] = await Promise.all([
        getGastos().catch(() => ({ total: 0, gastos: [] })),
        getVentasProductos().catch(() => ({ total_ventas: 0, ganancia_total: 0, ventas: [] })),
      ]);

      setGastos(resGastos.gastos);
      setTotalGastos(resGastos.total);

      setVentas(resVentas.ventas);
      setTotalVentas(resVentas.total_ventas);
      setGananciaVentas(resVentas.ganancia_total);
    } catch (err: any) {
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleCreateGasto = async (e: React.FormEvent) => {
    e.preventDefault();
    if (gastoMonto <= 0) return;

    try {
      const nuevo = await createGasto({
        monto: gastoMonto,
        categoria: gastoCategoria,
        concepto: gastoConcepto.trim() || undefined,
      });

      setGastos((prev) => [nuevo, ...prev]);
      setTotalGastos((prev) => prev + Number(nuevo.monto));
      onShowToast(`Gasto de $${Number(nuevo.monto).toFixed(2)} registrado.`);
      setIsGastoModalOpen(false);
      setGastoConcepto('');
      setGastoMonto(10);
      onDataChanged?.();
    } catch (err: any) {
      onShowToast(`Error: ${err.message}`);
    }
  };

  const handleCreateVenta = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!productoNombre.trim() || productoPrecio <= 0) return;

    try {
      const nueva = await createVentaProducto({
        nombre: productoNombre.trim(),
        costo: productoCosto,
        precio: productoPrecio,
      });

      setVentas((prev) => [nueva, ...prev]);
      setTotalVentas((prev) => prev + Number(nueva.precio_venta));
      setGananciaVentas((prev) => prev + (Number(nueva.precio_venta) - Number(nueva.precio_costo)));
      onShowToast(`Venta de "${nueva.nombre_producto}" registrada.`);
      setIsVentaModalOpen(false);
      setProductoNombre('');
      setProductoCosto(5);
      setProductoPrecio(15);
      onDataChanged?.();
    } catch (err: any) {
      onShowToast(`Error: ${err.message}`);
    }
  };

  return (
    <div className="flex flex-col gap-6 w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-[#eff4ff] shadow-xs">
        <div>
          <span className="text-[10px] uppercase tracking-widest text-[#b10e6b] font-bold">
            Control Financiero
          </span>
          <h1 className="font-serif text-2xl sm:text-3xl font-bold text-[#0b1c30]">
            Gastos y Venta de Productos
          </h1>
          <p className="text-xs text-[#515f74] mt-0.5">
            Registro de egresos operativos (arriendo, insumos) y venta de productos en salón.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setIsGastoModalOpen(true)}
            className="flex items-center gap-2 px-4 py-2.5 rounded-full bg-rose-50 hover:bg-rose-100 text-rose-700 text-xs font-bold transition-all cursor-pointer"
          >
            <ArrowDownRight className="w-4 h-4" />
            <span>Registrar Gasto</span>
          </button>

          <button
            onClick={() => setIsVentaModalOpen(true)}
            className="flex items-center gap-2 px-4 py-2.5 rounded-full bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold shadow-md transition-all cursor-pointer"
          >
            <ShoppingBag className="w-4 h-4" />
            <span>Vender Producto</span>
          </button>
        </div>
      </div>

      {/* Subtabs Switcher */}
      <div className="flex items-center gap-2 border-b border-[#eff4ff] pb-2">
        <button
          onClick={() => setActiveSubTab('gastos')}
          className={`px-5 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
            activeSubTab === 'gastos'
              ? 'bg-[#b10e6b] text-white shadow-xs'
              : 'bg-white text-[#515f74] hover:bg-[#eff4ff]'
          }`}
        >
          Gastos del Negocio (${totalGastos.toFixed(2)})
        </button>
        <button
          onClick={() => setActiveSubTab('ventas')}
          className={`px-5 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
            activeSubTab === 'ventas'
              ? 'bg-[#b10e6b] text-white shadow-xs'
              : 'bg-white text-[#515f74] hover:bg-[#eff4ff]'
          }`}
        >
          Ventas de Productos (${totalVentas.toFixed(2)} - Ganancia: ${gananciaVentas.toFixed(2)})
        </button>
      </div>

      {/* Subtab Content */}
      {activeSubTab === 'gastos' ? (
        <div className="bg-white rounded-2xl p-6 border border-[#eff4ff] shadow-xs">
          <h2 className="font-serif text-lg font-bold text-[#0b1c30] mb-4">
            Historial de Gastos ({gastos.length})
          </h2>

          {gastos.length === 0 ? (
            <div className="text-center py-10 text-xs text-[#515f74]">
              No hay gastos registrados en este período.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="border-b border-[#eff4ff] text-[#515f74]">
                    <th className="pb-3 font-semibold">Fecha</th>
                    <th className="pb-3 font-semibold">Categoría</th>
                    <th className="pb-3 font-semibold">Concepto / Detalle</th>
                    <th className="pb-3 font-semibold text-right">Monto</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#eff4ff]">
                  {gastos.map((g) => (
                    <tr key={g.id} className="hover:bg-[#f8f9ff]">
                      <td className="py-3 text-[#515f74]">{new Date(g.fecha).toLocaleDateString()}</td>
                      <td className="py-3">
                        <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase bg-rose-50 text-rose-700">
                          {g.categoria}
                        </span>
                      </td>
                      <td className="py-3 text-[#0b1c30] font-medium">{g.concepto || 'Gasto general'}</td>
                      <td className="py-3 text-right font-bold text-rose-600">
                        -${Number(g.monto).toFixed(2)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      ) : (
        <div className="bg-white rounded-2xl p-6 border border-[#eff4ff] shadow-xs">
          <h2 className="font-serif text-lg font-bold text-[#0b1c30] mb-4">
            Ventas de Productos ({ventas.length})
          </h2>

          {ventas.length === 0 ? (
            <div className="text-center py-10 text-xs text-[#515f74]">
              No hay ventas de productos registradas este mes.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="border-b border-[#eff4ff] text-[#515f74]">
                    <th className="pb-3 font-semibold">Fecha</th>
                    <th className="pb-3 font-semibold">Producto</th>
                    <th className="pb-3 font-semibold">Costo Raquel</th>
                    <th className="pb-3 font-semibold">Precio Venta</th>
                    <th className="pb-3 font-semibold text-right">Ganancia Neta</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#eff4ff]">
                  {ventas.map((v) => {
                    const cost = Number(v.precio_costo);
                    const sell = Number(v.precio_venta);
                    const profit = sell - cost;
                    return (
                      <tr key={v.id} className="hover:bg-[#f8f9ff]">
                        <td className="py-3 text-[#515f74]">{new Date(v.fecha).toLocaleDateString()}</td>
                        <td className="py-3 text-[#0b1c30] font-bold">{v.nombre_producto}</td>
                        <td className="py-3 text-[#515f74]">${cost.toFixed(2)}</td>
                        <td className="py-3 font-semibold text-[#0b1c30]">${sell.toFixed(2)}</td>
                        <td className="py-3 text-right font-bold text-emerald-600">
                          +${profit.toFixed(2)}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Modal Registrar Gasto */}
      {isGastoModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs">
          <div className="w-full max-w-md rounded-3xl bg-white p-6 sm:p-8 shadow-2xl border border-[#eff4ff]">
            <h2 className="font-serif text-xl font-bold text-[#0b1c30] mb-1">Registrar Gasto</h2>
            <p className="text-xs text-[#515f74] mb-4">Se guardará en la tabla de gastos operativos del backend.</p>

            <form onSubmit={handleCreateGasto} className="space-y-3 text-xs">
              <div>
                <label className="block font-bold text-[#0b1c30] mb-1">Monto ($) *</label>
                <input
                  type="number"
                  min="0.1"
                  step="0.1"
                  required
                  value={gastoMonto}
                  onChange={(e) => setGastoMonto(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30]"
                />
              </div>

              <div>
                <label className="block font-bold text-[#0b1c30] mb-1">Categoría *</label>
                <select
                  value={gastoCategoria}
                  onChange={(e) => setGastoCategoria(e.target.value as any)}
                  className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30]"
                >
                  <option value="productos">Productos / Insumos</option>
                  <option value="arriendo">Arriendo</option>
                  <option value="servicios">Servicios Básicos (Luz/Agua/Internet)</option>
                  <option value="comida">Comida</option>
                  <option value="transporte">Transporte</option>
                  <option value="otros">Otros</option>
                </select>
              </div>

              <div>
                <label className="block font-bold text-[#0b1c30] mb-1">Concepto / Descripción</label>
                <input
                  type="text"
                  placeholder="Ej: Compra de tinte 7/1 y champú neutro"
                  value={gastoConcepto}
                  onChange={(e) => setGastoConcepto(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30]"
                />
              </div>

              <div className="pt-3 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsGastoModalOpen(false)}
                  className="px-4 py-2 rounded-full bg-[#eff4ff] text-[#515f74] font-semibold"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-full bg-rose-600 hover:bg-rose-700 text-white font-bold"
                >
                  Guardar Gasto
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Registrar Venta Producto */}
      {isVentaModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs">
          <div className="w-full max-w-md rounded-3xl bg-white p-6 sm:p-8 shadow-2xl border border-[#eff4ff]">
            <h2 className="font-serif text-xl font-bold text-[#0b1c30] mb-1">Registrar Venta de Producto</h2>
            <p className="text-xs text-[#515f74] mb-4">Calcula automáticamente la ganancia neta.</p>

            <form onSubmit={handleCreateVenta} className="space-y-3 text-xs">
              <div>
                <label className="block font-bold text-[#0b1c30] mb-1">Nombre del Producto *</label>
                <input
                  type="text"
                  required
                  placeholder="Ej: Champú Kérastase Nutritive"
                  value={productoNombre}
                  onChange={(e) => setProductoNombre(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30]"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block font-bold text-[#0b1c30] mb-1">Costo ($) *</label>
                  <input
                    type="number"
                    min="0"
                    step="0.5"
                    required
                    value={productoCosto}
                    onChange={(e) => setProductoCosto(Number(e.target.value))}
                    className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30]"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#0b1c30] mb-1">Precio Venta ($) *</label>
                  <input
                    type="number"
                    min="0.1"
                    step="0.5"
                    required
                    value={productoPrecio}
                    onChange={(e) => setProductoPrecio(Number(e.target.value))}
                    className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30]"
                  />
                </div>
              </div>

              <div className="p-3 rounded-xl bg-emerald-50 text-emerald-700 text-xs font-bold">
                Ganancia calculada: ${(productoPrecio - productoCosto).toFixed(2)}
              </div>

              <div className="pt-3 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsVentaModalOpen(false)}
                  className="px-4 py-2 rounded-full bg-[#eff4ff] text-[#515f74] font-semibold"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-full bg-emerald-600 hover:bg-emerald-700 text-white font-bold"
                >
                  Guardar Venta
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
