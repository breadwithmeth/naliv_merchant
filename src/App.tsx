import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { Layout } from './components/Layout';
import { useAuthStore } from './store/auth';
import { CourierLocationsPage } from './pages/CourierLocationsPage';
import { CourierReportsPage } from './pages/CourierReportsPage';
import { CourierShiftDetailPage } from './pages/CourierShiftDetailPage';
import { CourierShiftsPage } from './pages/CourierShiftsPage';
import { LoginPage } from './pages/LoginPage';
import { OrderDetailPage } from './pages/OrderDetailPage';
import { OrdersPage } from './pages/OrdersPage';

function ProtectedRoute() {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
  return isAuthenticated ? <Layout /> : <Navigate to="/login" replace />;
}

export function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route element={<ProtectedRoute />}>
          <Route index element={<OrdersPage />} />
          <Route path="/orders/:orderId" element={<OrderDetailPage />} />
          <Route
            path="/orders/:orderId/locations"
            element={<CourierLocationsPage />}
          />
          <Route path="/couriers/locations" element={<CourierLocationsPage />} />
          <Route path="/couriers/reports" element={<CourierReportsPage />} />
          <Route path="/couriers/shifts" element={<CourierShiftsPage />} />
          <Route
            path="/couriers/shifts/:shiftId"
            element={<CourierShiftDetailPage />}
          />
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
