import {
  ClipboardList,
  LogOut,
  MapPin,
  Menu,
  Route,
  Truck,
  X,
} from 'lucide-react';
import { useState } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { clsx } from 'clsx';
import { useAuthStore } from '../store/auth';
import { Button } from './Button';

const navItems = [
  { to: '/', label: 'Заказы', icon: ClipboardList },
  { to: '/couriers/locations', label: 'Курьеры на карте', icon: MapPin },
  { to: '/couriers/reports', label: 'Отчеты курьеров', icon: Truck },
  { to: '/couriers/shifts', label: 'Смены курьеров', icon: Route },
];

export function Layout() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const logout = useAuthStore((state) => state.logout);
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login', { replace: true });
  };

  return (
    <div className="min-h-screen bg-slate-50 text-ink">
      <aside
        className={clsx(
          'fixed inset-y-0 left-0 z-40 w-72 border-r border-line bg-white transition-transform lg:translate-x-0',
          mobileOpen ? 'translate-x-0' : '-translate-x-full',
        )}
      >
        <div className="flex h-16 items-center justify-between border-b border-line px-5">
          <div>
            <p className="text-sm font-semibold uppercase tracking-wide text-brand-600">
              Панель магазина
            </p>
            <h1 className="text-lg font-bold text-ink">Обработка заказов</h1>
          </div>
          <Button
            variant="ghost"
            className="h-9 w-9 px-0 lg:hidden"
            onClick={() => setMobileOpen(false)}
            aria-label="Закрыть меню"
            icon={<X className="h-5 w-5" />}
          />
        </div>

        <nav className="space-y-1 p-3">
          {navItems.map((item) => {
            const Icon = item.icon;
            return (
              <NavLink
                key={item.to}
                to={item.to}
                onClick={() => setMobileOpen(false)}
                className={({ isActive }) =>
                  clsx(
                    'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-semibold transition',
                    isActive
                      ? 'bg-brand-50 text-brand-700'
                      : 'text-slate-600 hover:bg-slate-100 hover:text-ink',
                  )
                }
              >
                <Icon className="h-5 w-5" />
                {item.label}
              </NavLink>
            );
          })}
        </nav>
      </aside>

      {mobileOpen ? (
        <button
          className="fixed inset-0 z-30 bg-slate-950/30 lg:hidden"
          type="button"
          aria-label="Закрыть меню"
          onClick={() => setMobileOpen(false)}
        />
      ) : null}

      <div className="lg:pl-72">
        <header className="sticky top-0 z-20 flex h-16 items-center justify-between border-b border-line bg-white/95 px-4 backdrop-blur lg:px-6">
          <div className="flex items-center gap-3">
            <Button
              variant="ghost"
              className="h-10 w-10 px-0 lg:hidden"
              onClick={() => setMobileOpen(true)}
              aria-label="Открыть меню"
              icon={<Menu className="h-5 w-5" />}
            />
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-muted">
                Рабочее место
              </p>
              <p className="text-sm font-semibold text-ink">Светлая админ-панель</p>
            </div>
          </div>
          <Button
            variant="secondary"
            onClick={handleLogout}
            icon={<LogOut className="h-4 w-4" />}
          >
            Выйти
          </Button>
        </header>

        <main className="mx-auto w-full max-w-7xl px-4 py-5 lg:px-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
