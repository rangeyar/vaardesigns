import { useState } from 'react'
import './Products.css'

const Products = () => {
  const [activeCategory, setActiveCategory] = useState('AI Security')

  const categories = [
    'AI Security',
    'AI Law',
    'AI Financial',
    'AI Non Financial'
  ]

  const productData = {
    'AI Security': [
      {
        title: 'THREAT DETECTION PLATFORM',
        description: 'Advanced AI-powered threat detection and response system'
      },
      {
        title: 'SECURITY ANALYTICS',
        description: 'Real-time security monitoring and analytics'
      },
      {
        title: 'VULNERABILITY SCANNER',
        description: 'Automated vulnerability assessment and remediation'
      },
      {
        title: 'IDENTITY PROTECTION',
        description: 'AI-driven identity and access management'
      }
    ],
    'AI Law': [
      {
        title: 'LEGAL DOCUMENT ANALYZER',
        description: 'Automated legal document analysis and review'
      },
      {
        title: 'CONTRACT MANAGEMENT',
        description: 'Smart contract creation and management platform'
      },
      {
        title: 'COMPLIANCE MONITORING',
        description: 'AI-powered regulatory compliance tracking'
      },
      {
        title: 'CASE RESEARCH ASSISTANT',
        description: 'Intelligent legal research and case analysis'
      }
    ],
    'AI Financial': [
      {
        title: 'FRAUD DETECTION SYSTEM',
        description: 'Real-time fraud detection and prevention'
      },
      {
        title: 'RISK ASSESSMENT PLATFORM',
        description: 'Advanced financial risk modeling and analysis'
      },
      {
        title: 'ALGORITHMIC TRADING',
        description: 'AI-powered trading algorithms and strategies'
      },
      {
        title: 'PORTFOLIO OPTIMIZER',
        description: 'Intelligent investment portfolio management'
      }
    ],
    'AI Non Financial': [
      {
        title: 'CONTENT GENERATOR',
        description: 'AI-powered content creation and optimization'
      },
      {
        title: 'CUSTOMER SERVICE BOT',
        description: 'Intelligent chatbot for customer support'
      },
      {
        title: 'PROCESS AUTOMATION',
        description: 'Business process automation and optimization'
      },
      {
        title: 'PREDICTIVE ANALYTICS',
        description: 'Data-driven insights and forecasting'
      }
    ]
  }

  return (
    <div className="products-page">
      <div className="products-hero">
        <h1>Our Products</h1>
        <p>Discover our comprehensive suite of AI-powered solutions</p>
      </div>

      <div className="mega-menu-container">
        <div className="mega-menu-content">
          {/* Left Side - Categories */}
          <div className="mega-menu-left">
            <h2>Products</h2>
            {categories.map((category) => (
              <button
                key={category}
                className={`category-item ${activeCategory === category ? 'active' : ''}`}
                onClick={() => setActiveCategory(category)}
              >
                {category}
              </button>
            ))}
            <button className="see-all-btn">
              SEE ALL PRODUCTS AND SOLUTIONS
              <span className="arrow">→</span>
            </button>
          </div>

          {/* Right Side - Product Details */}
          <div className="mega-menu-right">
            <h3 className="category-title">{activeCategory}</h3>
            <div className="products-grid">
              {productData[activeCategory].map((product, index) => (
                <div key={index} className="product-card">
                  <h4>{product.title}</h4>
                  <p>{product.description}</p>
                  <span className="product-arrow">›</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Products
