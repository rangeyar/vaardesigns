import './App.css'
import AskArvashu from './components/AskArvashu'
import HeroSlider from './components/HeroSlider'

function App() {
  console.log('App component rendered')
  console.log('Test run')
  return (
    <>
      <header className="header">
        <div className="header-container">
          <div className="logo">
            <h1>VaarDesigns</h1>
          </div>
          <nav className="nav">
            <a href="#home">Home</a>
            <a href="#products">Products</a>
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

export default App
