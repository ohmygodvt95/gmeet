<template>
  <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
    <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
      <div class="mt-3">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-medium text-gray-900">Tham gia phòng họp</h3>
          <button
            @click="$emit('close')"
            class="text-gray-400 hover:text-gray-600"
          >
            <XMarkIcon class="h-6 w-6" />
          </button>
        </div>
        
        <form @submit.prevent="joinRoom" class="space-y-4">
          <div>
            <label for="roomId" class="block text-sm font-medium text-gray-700">
              Mã phòng hoặc Link
            </label>
            <input
              id="roomId"
              v-model="roomId"
              type="text"
              required
              class="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              placeholder="Nhập mã phòng hoặc link phòng họp"
            />
            <p class="mt-1 text-xs text-gray-500">
              Ví dụ: abc123xyz hoặc http://localhost:3000/room/abc123xyz
            </p>
          </div>
          
          <div class="flex justify-end space-x-3 pt-4">
            <button
              type="button"
              @click="$emit('close')"
              class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md transition-colors"
            >
              Hủy
            </button>
            <button
              type="submit"
              :disabled="loading || !roomId.trim()"
              class="px-4 py-2 text-sm font-medium text-white bg-green-600 hover:bg-green-700 rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <span v-if="loading" class="flex items-center">
                <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                Đang tham gia...
              </span>
              <span v-else>Tham gia</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { XMarkIcon } from '@heroicons/vue/24/outline'

// Events
const emit = defineEmits<{
  close: []
  joined: [roomId: string]
}>()

// Stores
const roomStore = useRoomStore()
const { $toast } = useNuxtApp()

// Reactive data
const loading = ref(false)
const roomId = ref('')

// Methods
const joinRoom = async () => {
  if (!roomId.value.trim()) {
    $toast.error('Vui lòng nhập mã phòng')
    return
  }
  
  loading.value = true
  
  try {
    // Extract room ID from URL if needed
    let extractedRoomId = roomId.value.trim()
    
    // If it's a URL, extract the room ID
    if (extractedRoomId.includes('/room/')) {
      const matches = extractedRoomId.match(/\/room\/([^\/\?]+)/)
      if (matches) {
        extractedRoomId = matches[1]
      }
    }
    
    // Check if room exists
    const room = await roomStore.getRoomById(extractedRoomId)
    if (!room) {
      $toast.error('Phòng họp không tồn tại')
      return
    }
    
    emit('joined', extractedRoomId)
  } catch (error: any) {
    console.error('Error joining room:', error)
    $toast.error(error.message || 'Không thể tham gia phòng họp')
  } finally {
    loading.value = false
  }
}
</script>
