import { Link } from 'react-router-dom'
import AskArvashu from './AskArvashu'

const Layout = ({ children }) => {
  return (
    <>
      <header className="header">
        <div className="header-container">
          <div className="logo">
            <h1>VaarDesigns</h1>
          </div>
          <nav className="nav">
            <Link to="/">Home</Link>
            <Link to="/products">Products</Link>
            <a href="#services">Services</a>
            <a href="#about">About Us</a>
            <a href="#contact">Contact Us</a>
          </nav>
        </div>
      </header>

      <main className="main-content">
        {children}
      </main>

      <footer className="footer">
        <p>&copy; 2025 VaarDesigns. All rights reserved.</p>
      </footer>

      {/* AI Assistant */}
      <AskArvashu />
    </>
  )
}

export default Layout
