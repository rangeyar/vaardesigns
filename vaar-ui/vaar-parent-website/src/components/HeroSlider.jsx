import { useState, useEffect } from 'react';
import './HeroSlider.css';

const HeroSlider = () => {
  const [currentSlide, setCurrentSlide] = useState(0);
  const [isAutoPlaying, setIsAutoPlaying] = useState(true);

  const slides = [
    {
      id: 1,
      title: "Providing AI-Based Solutions",
      subtitle: "Transforming businesses with cutting-edge artificial intelligence.",
      description: "One platform. Endless possibilities.",
      buttonText: "KNOW MORE"
    },
    {
      id: 2,
      title: "AI Security Challenges",
      subtitle: "Protecting your data in the age of intelligent systems.",
      description: "Advanced security for AI-driven enterprises.",
      buttonText: "KNOW MORE"
    },
    {
      id: 3,
      title: "AI Challenges with LAW",
      subtitle: "Navigating legal compliance in artificial intelligence.",
      description: "Ensuring regulatory adherence and ethical AI practices.",
      buttonText: "KNOW MORE"
    },
    {
      id: 4,
      title: "AI Financial Challenges",
      subtitle: "Managing costs and ROI in AI implementation.",
      description: "Strategic financial planning for AI transformation.",
      buttonText: "KNOW MORE"
    },
    {
      id: 5,
      title: "AI Non-Financial Challenges",
      subtitle: "Addressing organizational and cultural transformation.",
      description: "Building AI-ready teams and processes.",
      buttonText: "KNOW MORE"
    }
  ];

  // Auto-advance slides
  useEffect(() => {
    if (!isAutoPlaying) return;

    const timer = setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % slides.length);
    }, 5000);

    return () => clearInterval(timer);
  }, [isAutoPlaying, slides.length]);

  const goToSlide = (index) => {
    setCurrentSlide(index);
    setIsAutoPlaying(false);
    setTimeout(() => setIsAutoPlaying(true), 10000);
  };

  const nextSlide = () => {
    setCurrentSlide((prev) => (prev + 1) % slides.length);
  };

  const prevSlide = () => {
    setCurrentSlide((prev) => (prev - 1 + slides.length) % slides.length);
  };

  const handleKeyDown = (e) => {
    if (e.key === 'ArrowLeft') {
      prevSlide();
    } else if (e.key === 'ArrowRight') {
      nextSlide();
    }
  };

  useEffect(() => {
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  return (
    <div className="hero-slider">
      <div className="slides-container">
        {slides.map((slide, index) => (
          <div
            key={slide.id}
            className={`slide ${
              index === currentSlide ? 'active' : index < currentSlide ? 'prev' : ''
            }`}
          >
            {/* Gradient Overlay */}
            <div className="slide-overlay"></div>
            
            {/* Animated Background */}
            <div className="slide-background">
              <div className="bg-blob-1"></div>
              <div className="bg-blob-2"></div>
            </div>

            {/* Content */}
            <div className="slide-content">
              <div className="slide-inner">
                {/* Slide Number */}
                <div className="slide-number">
                  {String(slide.id).padStart(2, '0')} / {String(slides.length).padStart(2, '0')}
                </div>

                {/* Main Title */}
                <h1 className="slide-title">{slide.title}</h1>

                {/* Subtitle */}
                <p className="slide-subtitle">{slide.subtitle}</p>

                {/* Description */}
                <p className="slide-description">{slide.description}</p>

                {/* Button */}
                <button className="slide-button">
                  <span>{slide.buttonText}</span>
                  <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                  </svg>
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Navigation Dots */}
      <div className="slider-dots">
        {slides.map((_, index) => (
          <button
            key={index}
            onClick={() => goToSlide(index)}
            className={`dot ${index === currentSlide ? 'active' : ''}`}
            aria-label={`Go to slide ${index + 1}`}
          />
        ))}
      </div>

      {/* Progress Bar */}
      <div className="slider-progress">
        <div
          className="progress-bar"
          style={{
            width: `${((currentSlide + 1) / slides.length) * 100}%`
          }}
        />
      </div>

      {/* Left Arrow */}
      <button
        onClick={prevSlide}
        className="slider-arrow left"
        aria-label="Previous slide"
      >
        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
        </svg>
      </button>

      {/* Right Arrow */}
      <button
        onClick={nextSlide}
        className="slider-arrow right"
        aria-label="Next slide"
      >
        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
        </svg>
      </button>
    </div>
  );
};

export default HeroSlider;
