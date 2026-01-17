import './App.css'
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
import HeroSlider from './components/HeroSlider'
import Products from './components/Products/Products'

function App() {
  console.log('App component rendered')
  console.log('Test run')
  return (
    <Router>
      <Layout>
        <Routes>
          <Route path="/" element={<HeroSlider />} />
          <Route path="/products" element={<Products />} />
        </Routes>
      </Layout>
    </Router>
  )
}

export default App
