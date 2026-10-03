// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { Navigate, Route, Routes } from 'react-router-dom'
import AppLayout from './layout/AppLayout'
import LoginPage from './pages/LoginPage'
import DashboardPage from './pages/DashboardPage'
import ReportsPage from './pages/ReportsPage'
import CommunitiesPage from './pages/CommunitiesPage'
import RoomsPage from './pages/RoomsPage'
import OwnersPage from './pages/OwnersPage'
import FeeBillsPage from './pages/FeeBillsPage'
import FeePaymentsPage from './pages/FeePaymentsPage'
import RepairsPage from './pages/RepairsPage'
import ComplaintsPage from './pages/ComplaintsPage'
import UsersPage from './pages/UsersPage'
import RolesPage from './pages/RolesPage'
import SystemPage from './pages/SystemPage'
import NotFoundPage from './pages/NotFoundPage'

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<AppLayout />}>
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/reports" element={<ReportsPage />} />
        <Route path="/communities" element={<CommunitiesPage />} />
        <Route path="/rooms" element={<RoomsPage />} />
        <Route path="/owners" element={<OwnersPage />} />
        <Route path="/fee-bills" element={<FeeBillsPage />} />
        <Route path="/fee-payments" element={<FeePaymentsPage />} />
        <Route path="/repairs" element={<RepairsPage />} />
        <Route path="/complaints" element={<ComplaintsPage />} />
        <Route path="/users" element={<UsersPage />} />
        <Route path="/roles" element={<RolesPage />} />
        <Route path="/system" element={<Navigate to="/system/config" replace />} />
        <Route path="/system/:tab" element={<SystemPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes>
  )
}
