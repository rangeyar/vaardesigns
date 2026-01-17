import './App.css'
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom'
import AskArvashu from './components/AskArvashu'
import HeroSlider from './components/HeroSlider'
import Products from './components/Products/Products'

function HomePage() {
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
        {/* Hero Slider */}
        <HeroSlider />
      </main>

      <footer className="footer">
        <p>&copy; 2025 VaarDesigns. All rights reserved.</p>
      </footer>

      {/* AI Assistant */}
      <AskArvashu />
    </>
  )
}

function App() {
  console.log('App component rendered')
  console.log('Test run')
  return (
    <Router>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/products" element={<Products />} />
      </Routes>
    </Router>
  )
}

export default App
