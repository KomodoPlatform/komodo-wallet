// Web Performance Optimization Configuration
// This file contains web-specific optimizations for the Komodo Wallet

// Service Worker for caching and offline support
const CACHE_NAME = 'komodo-wallet-v1';
const STATIC_CACHE_NAME = 'komodo-wallet-static-v1';
const DYNAMIC_CACHE_NAME = 'komodo-wallet-dynamic-v1';

// Critical resources to cache immediately
const CRITICAL_RESOURCES = [
  '/',
  '/index.html',
  '/flutter_bootstrap.js',
  '/assets/packages/komodo_defi_framework/assets/config/coins.json',
  '/assets/packages/komodo_defi_framework/assets/config/coins_config.json',
  '/icons/logo_icon.png',
  '/assets/fonts/Manrope-Regular.ttf',
  '/assets/fonts/Manrope-Bold.ttf',
];

// Static assets to cache
const STATIC_ASSETS = [
  '/assets/ui_icons/',
  '/assets/nav_icons/',
  '/assets/logo/',
  '/assets/fonts/',
];

// Dynamic resources (API responses, etc.)
const DYNAMIC_RESOURCES = [
  'https://cache.defi-stats.komodo.earth/api/v3/prices/tickers_v2.json',
];

// Performance optimization functions
const PerformanceOptimizer = {
  // Initialize performance optimizations
  init() {
    this.setupServiceWorker();
    this.optimizeImages();
    this.preloadCriticalResources();
    this.setupResourceHints();
    this.optimizeFonts();
  },

  // Setup service worker for caching
  setupServiceWorker() {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/sw.js')
        .then(registration => {
          console.log('Service Worker registered:', registration);
        })
        .catch(error => {
          console.log('Service Worker registration failed:', error);
        });
    }
  },

  // Optimize image loading
  optimizeImages() {
    // Use Intersection Observer for lazy loading
    if ('IntersectionObserver' in window) {
      const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            const img = entry.target;
            img.src = img.dataset.src;
            img.classList.remove('lazy');
            observer.unobserve(img);
          }
        });
      });

      document.querySelectorAll('img[data-src]').forEach(img => {
        imageObserver.observe(img);
      });
    }
  },

  // Preload critical resources
  preloadCriticalResources() {
    CRITICAL_RESOURCES.forEach(resource => {
      const link = document.createElement('link');
      link.rel = 'preload';
      link.as = this.getResourceType(resource);
      link.href = resource;
      document.head.appendChild(link);
    });
  },

  // Setup resource hints
  setupResourceHints() {
    // DNS prefetch for external domains
    const domains = [
      'https://www.gstatic.com',
      'https://www.googletagmanager.com',
      'https://worldtimeapi.org',
      'https://cache.defi-stats.komodo.earth',
    ];

    domains.forEach(domain => {
      const link = document.createElement('link');
      link.rel = 'dns-prefetch';
      link.href = domain;
      document.head.appendChild(link);
    });
  },

  // Optimize font loading
  optimizeFonts() {
    // Use font-display: swap for better performance
    const fontLinks = document.querySelectorAll('link[rel="preload"][as="font"]');
    fontLinks.forEach(link => {
      link.setAttribute('crossorigin', 'anonymous');
    });
  },

  // Get resource type for preloading
  getResourceType(resource) {
    if (resource.endsWith('.js')) return 'script';
    if (resource.endsWith('.css')) return 'style';
    if (resource.endsWith('.json')) return 'fetch';
    if (resource.endsWith('.ttf') || resource.endsWith('.woff')) return 'font';
    if (resource.endsWith('.png') || resource.endsWith('.jpg') || resource.endsWith('.svg')) return 'image';
    return 'fetch';
  },

  // Performance monitoring
  monitorPerformance() {
    // Monitor Core Web Vitals
    if ('PerformanceObserver' in window) {
      const observer = new PerformanceObserver((list) => {
        list.getEntries().forEach((entry) => {
          console.log('Performance metric:', entry.name, entry.value);
        });
      });
      
      observer.observe({ entryTypes: ['largest-contentful-paint', 'first-input', 'layout-shift'] });
    }
  },

  // Optimize bundle loading
  optimizeBundleLoading() {
    // Use requestIdleCallback for non-critical operations
    if ('requestIdleCallback' in window) {
      requestIdleCallback(() => {
        this.loadNonCriticalResources();
      });
    } else {
      // Fallback for browsers without requestIdleCallback
      setTimeout(() => {
        this.loadNonCriticalResources();
      }, 1000);
    }
  },

  // Load non-critical resources
  loadNonCriticalResources() {
    // Load additional fonts, icons, and other non-critical resources
    const nonCriticalResources = [
      '/assets/blockchain_icons/',
      '/assets/fiat/',
      '/assets/others/',
    ];

    nonCriticalResources.forEach(resource => {
      const link = document.createElement('link');
      link.rel = 'prefetch';
      link.href = resource;
      document.head.appendChild(link);
    });
  }
};

// Initialize optimizations when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    PerformanceOptimizer.init();
  });
} else {
  PerformanceOptimizer.init();
}

// Export for use in other scripts
window.PerformanceOptimizer = PerformanceOptimizer;