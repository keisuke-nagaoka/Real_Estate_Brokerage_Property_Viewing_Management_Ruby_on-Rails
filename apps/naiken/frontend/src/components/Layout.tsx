import { NavLink, Outlet } from 'react-router'

const navItems = [
  { to: '/customers', label: '顧客' },
  { to: '/properties', label: '物件' },
  { to: '/viewings', label: '内見予定' },
]

export function Layout() {
  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="brand">
          <span className="brand-logo">N</span>
          <div>
            <div className="brand-name">Naiken</div>
            <div className="brand-sub">顧客・内見管理</div>
          </div>
        </div>
        <nav className="nav">
          {navItems.map((item) => (
            <NavLink key={item.to} to={item.to} className={({ isActive }) => `nav-item${isActive ? ' active' : ''}`}>
              {item.label}
            </NavLink>
          ))}
        </nav>
      </aside>
      <main className="content">
        <Outlet />
      </main>
    </div>
  )
}
