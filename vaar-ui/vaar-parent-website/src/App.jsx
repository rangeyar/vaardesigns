import './App.css'

function App() {
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
        <section className="hero">
          <h2>Welcome to VaarDesigns</h2>
          <p>Your creative design partner</p>
        </section>
      </main>

      <footer className="footer">
        <p>&copy; 2025 VaarDesigns. All rights reserved.</p>
      </footer>
    </>
  )
}

export default App
