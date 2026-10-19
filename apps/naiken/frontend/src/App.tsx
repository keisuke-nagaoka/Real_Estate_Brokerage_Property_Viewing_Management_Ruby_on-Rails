import { Navigate, Route, Routes } from 'react-router'
import { Layout } from './components/Layout'
import { NotFoundPage } from './pages/NotFoundPage'
import { CustomerDetailPage } from './pages/customers/CustomerDetailPage'
import { CustomerEditPage } from './pages/customers/CustomerEditPage'
import { CustomerListPage } from './pages/customers/CustomerListPage'
import { CustomerNewPage } from './pages/customers/CustomerNewPage'

function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<Navigate to="/customers" replace />} />
        <Route path="customers" element={<CustomerListPage />} />
        <Route path="customers/new" element={<CustomerNewPage />} />
        <Route path="customers/:id" element={<CustomerDetailPage />} />
        <Route path="customers/:id/edit" element={<CustomerEditPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes>
  )
}

export default App
