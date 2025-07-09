// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-05-15',
  devtools: { enabled: true },
  
  // CSS framework
  modules: [
    '@nuxtjs/tailwindcss',
    '@pinia/nuxt',
    '@vueuse/nuxt'
  ],
  
  // Runtime config
  runtimeConfig: {
    public: {
      apiBase: process.env.NODE_ENV === 'production' 
        ? 'https://your-api-domain.com/api' 
        : 'http://localhost:3001/api',
      socketUrl: process.env.NODE_ENV === 'production' 
        ? 'https://your-api-domain.com' 
        : 'http://localhost:3001',
      sfuUrl: process.env.NODE_ENV === 'production' 
        ? 'https://your-sfu-domain.com' 
        : 'http://localhost:3002'
    }
  },
  
  // App config
  app: {
    head: {
      title: 'GMeeting - Video Conference App',
      meta: [
        { charset: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'description', content: 'Google Meet Clone - Video conferencing made simple' }
      ],
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' }
      ]
    }
  },
  
  // Development server
  devServer: {
    port: 3000
  },
  
  // Build configuration
  build: {
    transpile: ['vue-toastification']
  }
})
