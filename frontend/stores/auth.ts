import { defineStore } from 'pinia'

interface User {
  id: number
  username: string
  email: string
  fullName: string
  avatarUrl?: string
}

interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  isLoading: boolean
}

export const useAuthStore = defineStore('auth', {
  state: (): AuthState => ({
    user: null,
    token: null,
    isAuthenticated: false,
    isLoading: false
  }),

  getters: {
    isLoggedIn: (state) => state.isAuthenticated && state.token !== null,
    getCurrentUser: (state) => state.user,
    getToken: (state) => state.token
  },

  actions: {
    async login(credentials: { email: string; password: string }) {
      this.isLoading = true
      
      try {
        const { $api } = useNuxtApp()
        const response = await $api.post('/auth/login', credentials)
        
        if (response.data.success) {
          this.setAuth(response.data.data.user, response.data.data.token)
          await navigateTo('/dashboard')
          return { success: true }
        }
        
        return { success: false, message: response.data.message }
      } catch (error: any) {
        const message = error.response?.data?.message || 'Login failed'
        return { success: false, message }
      } finally {
        this.isLoading = false
      }
    },

    async register(userData: {
      username: string
      email: string
      password: string
      fullName: string
    }) {
      this.isLoading = true
      
      try {
        const { $api } = useNuxtApp()
        const response = await $api.post('/auth/register', userData)
        
        if (response.data.success) {
          this.setAuth(response.data.data.user, response.data.data.token)
          await navigateTo('/dashboard')
          return { success: true }
        }
        
        return { success: false, message: response.data.message }
      } catch (error: any) {
        const message = error.response?.data?.message || 'Registration failed'
        return { success: false, message }
      } finally {
        this.isLoading = false
      }
    },

    async fetchProfile() {
      if (!this.token) return
      
      try {
        const { $api } = useNuxtApp()
        const response = await $api.get('/auth/profile')
        
        if (response.data.success) {
          this.user = response.data.data.user
        }
      } catch (error) {
        console.error('Failed to fetch profile:', error)
        this.logout()
      }
    },

    setAuth(user: User, token: string) {
      this.user = user
      this.token = token
      this.isAuthenticated = true
      
      // Store token in localStorage
      if (process.client) {
        localStorage.setItem('auth_token', token)
        localStorage.setItem('auth_user', JSON.stringify(user))
      }
    },

    logout() {
      this.user = null
      this.token = null
      this.isAuthenticated = false
      
      // Clear localStorage
      if (process.client) {
        localStorage.removeItem('auth_token')
        localStorage.removeItem('auth_user')
      }
      
      navigateTo('/login')
    },

    async initializeAuth() {
      if (!process.client) return
      
      const token = localStorage.getItem('auth_token')
      const userStr = localStorage.getItem('auth_user')
      
      if (token && userStr) {
        try {
          const user = JSON.parse(userStr)
          this.setAuth(user, token)
          await this.fetchProfile() // Verify token is still valid
        } catch (error) {
          console.error('Failed to initialize auth:', error)
          this.logout()
        }
      }
    }
  }
})
