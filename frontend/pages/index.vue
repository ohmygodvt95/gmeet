<template>
  <div class="min-h-screen bg-gray-50">
    <div class="container mx-auto px-4 py-8">
      <div class="max-w-md mx-auto">
        <!-- Logo -->
        <div class="text-center mb-8">
          <h1 class="text-4xl font-bold text-blue-600">GMeeting</h1>
          <p class="text-gray-600 mt-2">Video conferencing made simple</p>
        </div>

        <!-- Login Form -->
        <div class="card">
          <h2 class="text-2xl font-semibold text-gray-900 mb-6 text-center">Sign In</h2>
          
          <form @submit.prevent="handleLogin" class="space-y-4">
            <div>
              <label for="email" class="block text-sm font-medium text-gray-700 mb-1">
                Email
              </label>
              <input
                id="email"
                v-model="form.email"
                type="email"
                required
                class="input-field"
                placeholder="Enter your email"
              />
            </div>

            <div>
              <label for="password" class="block text-sm font-medium text-gray-700 mb-1">
                Password
              </label>
              <input
                id="password"
                v-model="form.password"
                type="password"
                required
                class="input-field"
                placeholder="Enter your password"
              />
            </div>

            <button
              type="submit"
              :disabled="isLoading"
              class="btn-primary w-full"
            >
              <span v-if="isLoading" class="loading-spinner inline-block mr-2"></span>
              {{ isLoading ? 'Signing in...' : 'Sign In' }}
            </button>
          </form>

          <div class="mt-6 text-center">
            <p class="text-sm text-gray-600">
              Don't have an account?
              <NuxtLink to="/register" class="text-blue-600 hover:text-blue-500 font-medium">
                Sign up
              </NuxtLink>
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: false,
  middleware: 'guest'
})

const form = ref({
  email: '',
  password: ''
})

const isLoading = ref(false)
const { $toast } = useNuxtApp()
const authStore = useAuthStore()

// Check if user is already authenticated
onMounted(() => {
  if (authStore.isAuthenticated) {
    navigateTo('/dashboard')
  }
})

const handleLogin = async () => {
  isLoading.value = true
  
  try {
    const result = await authStore.login(form.value)
    
    if (result.success) {
      $toast.success('Login successful!')
    } else {
      $toast.error(result.message || 'Login failed')
    }
  } catch (error: any) {
    $toast.error(error.message || 'An error occurred')
  } finally {
    isLoading.value = false
  }
}
</script>
