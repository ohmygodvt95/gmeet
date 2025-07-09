<template>
  <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
    <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
      <div class="mt-3">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-medium text-gray-900">Tạo phòng họp mới</h3>
          <button
            @click="$emit('close')"
            class="text-gray-400 hover:text-gray-600"
          >
            <XMarkIcon class="h-6 w-6" />
          </button>
        </div>
        
        <form @submit.prevent="createRoom" class="space-y-4">
          <div>
            <label for="title" class="block text-sm font-medium text-gray-700">
              Tên phòng họp
            </label>
            <input
              id="title"
              v-model="form.title"
              type="text"
              required
              class="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              placeholder="Nhập tên phòng họp"
            />
          </div>
          
          <div>
            <label for="description" class="block text-sm font-medium text-gray-700">
              Mô tả (tùy chọn)
            </label>
            <textarea
              id="description"
              v-model="form.description"
              rows="3"
              class="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              placeholder="Mô tả về cuộc họp"
            ></textarea>
          </div>
          
          <div>
            <label for="maxParticipants" class="block text-sm font-medium text-gray-700">
              Số người tham gia tối đa
            </label>
            <select
              id="maxParticipants"
              v-model="form.maxParticipants"
              class="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="10">10 người</option>
              <option value="25">25 người</option>
              <option value="50">50 người</option>
              <option value="100">100 người</option>
            </select>
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
              :disabled="loading"
              class="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <span v-if="loading" class="flex items-center">
                <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                Đang tạo...
              </span>
              <span v-else>Tạo phòng</span>
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
  created: [room: any]
}>()

// Stores
const roomStore = useRoomStore()
const { $toast } = useNuxtApp()

// Reactive data
const loading = ref(false)
const form = reactive({
  title: '',
  description: '',
  maxParticipants: 10
})

// Methods
const createRoom = async () => {
  if (!form.title.trim()) {
    $toast.error('Vui lòng nhập tên phòng họp')
    return
  }
  
  loading.value = true
  
  try {
    const room = await roomStore.createRoom({
      title: form.title.trim(),
      description: form.description.trim(),
      maxParticipants: form.maxParticipants
    })
    
    emit('created', room)
  } catch (error: any) {
    console.error('Error creating room:', error)
    $toast.error(error.message || 'Không thể tạo phòng họp')
  } finally {
    loading.value = false
  }
}
</script>
