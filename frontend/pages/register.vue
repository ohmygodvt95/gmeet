<template>
  <div class="min-h-screen bg-gray-50">
    <div class="container mx-auto px-4 py-8">
      <div class="max-w-md mx-auto">
        <!-- Logo -->
        <div class="text-center mb-8">
          <h1 class="text-4xl font-bold text-blue-600">GMeeting</h1>
          <p class="text-gray-600 mt-2">Create your account</p>
        </div>

        <!-- Register Form -->
        <div class="card">
          <h2 class="text-2xl font-semibold text-gray-900 mb-6 text-center">Sign Up</h2>
          
          <form @submit.prevent="handleRegister" class="space-y-4">
            <div>
              <label for="username" class="block text-sm font-medium text-gray-700 mb-1">
                Username
              </label>
              <input
                id="username"
                v-model="form.username"
                type="text"
                required
                class="input-field"
                placeholder="Choose a username"
              />
            </div>

            <div>
              <label for="fullName" class="block text-sm font-medium text-gray-700 mb-1">
                Full Name
              </label>
              <input
                id="fullName"
                v-model="form.fullName"
                type="text"
                required
                class="input-field"
                placeholder="Enter your full name"
              />
            </div>

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
                minlength="6"
                class="input-field"
                placeholder="Create a password (min. 6 characters)"
              />
            </div>

            <button
              type="submit"
              :disabled="isLoading"
              class="btn-primary w-full"
            >
              <span v-if="isLoading" class="loading-spinner inline-block mr-2"></span>
              {{ isLoading ? 'Creating account...' : 'Create Account' }}
            </button>
          </form>

          <div class="mt-6 text-center">
            <p class="text-sm text-gray-600">
              Already have an account?
              <NuxtLink to="/" class="text-blue-600 hover:text-blue-500 font-medium">
                Sign in
              </NuxtLink>
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
definePageMeta({
  layout: false,
  middleware: 'guest'
})

const form = ref({
  username: '',
  fullName: '',
  email: '',
  password: ''
})

const isLoading = ref(false)

const handleRegister = async () => {
  isLoading.value = true
  
  try {
    const authStore = useAuthStore()
    const result = await authStore.register(form.value)
    
    if (result.success) {
      useToast().success('Account created successfully!')
    } else {
      useToast().error(result.message || 'Registration failed')
    }
  } catch (error) {
    useToast().error(error.message || 'An error occurred')
  } finally {
    isLoading.value = false
  }
}
</script>
