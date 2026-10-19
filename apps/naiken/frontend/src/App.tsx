import { Navigate, Route, Routes } from 'react-router'
import { Layout } from './components/Layout'
import { NotFoundPage } from './pages/NotFoundPage'
import { CustomerDetailPage } from './pages/customers/CustomerDetailPage'
import { CustomerEditPage } from './pages/customers/CustomerEditPage'
import { CustomerListPage } from './pages/customers/CustomerListPage'
import { CustomerNewPage } from './pages/customers/CustomerNewPage'
import { PropertyDetailPage } from './pages/properties/PropertyDetailPage'
import { PropertyEditPage } from './pages/properties/PropertyEditPage'
import { PropertyListPage } from './pages/properties/PropertyListPage'
import { PropertyNewPage } from './pages/properties/PropertyNewPage'
import { ViewingEditPage } from './pages/viewings/ViewingEditPage'
import { ViewingListPage } from './pages/viewings/ViewingListPage'
import { ViewingNewPage } from './pages/viewings/ViewingNewPage'

function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<Navigate to="/customers" replace />} />
        <Route path="customers" element={<CustomerListPage />} />
        <Route path="customers/new" element={<CustomerNewPage />} />
        <Route path="customers/:id" element={<CustomerDetailPage />} />
        <Route path="customers/:id/edit" element={<CustomerEditPage />} />
        <Route path="properties" element={<PropertyListPage />} />
        <Route path="properties/new" element={<PropertyNewPage />} />
        <Route path="properties/:id" element={<PropertyDetailPage />} />
        <Route path="properties/:id/edit" element={<PropertyEditPage />} />
        <Route path="viewings" element={<ViewingListPage />} />
        <Route path="viewings/new" element={<ViewingNewPage />} />
        <Route path="viewings/:id/edit" element={<ViewingEditPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes>
  )
}

export default App
