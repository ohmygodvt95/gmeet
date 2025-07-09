<template>
  <div class="flex flex-col h-full">
    <!-- Header -->
    <div class="p-4 border-b border-gray-200 flex items-center justify-between">
      <h3 class="text-lg font-medium text-gray-900">Chat</h3>
      <button
        @click="$emit('close')"
        class="text-gray-400 hover:text-gray-600"
      >
        <XMarkIcon class="h-5 w-5" />
      </button>
    </div>

    <!-- Messages -->
    <div
      ref="messagesContainer"
      class="flex-1 overflow-y-auto p-4 space-y-3"
    >
      <div v-if="messages.length === 0" class="text-center text-gray-500 py-8">
        <ChatBubbleLeftIcon class="h-8 w-8 mx-auto mb-2 opacity-50" />
        <p class="text-sm">Chưa có tin nhắn nào</p>
        <p class="text-xs">Hãy bắt đầu cuộc trò chuyện!</p>
      </div>
      
      <div
        v-for="message in messages"
        :key="message.id"
        :class="[
          'flex',
          message.user_id === currentUserId ? 'justify-end' : 'justify-start'
        ]"
      >
        <div
          :class="[
            'max-w-xs lg:max-w-md px-3 py-2 rounded-lg text-sm',
            message.user_id === currentUserId
              ? 'bg-blue-600 text-white'
              : 'bg-gray-100 text-gray-900'
          ]"
        >
          <div
            v-if="message.user_id !== currentUserId"
            class="text-xs opacity-75 mb-1"
          >
            {{ message.username }}
          </div>
          <div>{{ message.content }}</div>
          <div
            :class="[
              'text-xs mt-1',
              message.user_id === currentUserId ? 'text-blue-100' : 'text-gray-500'
            ]"
          >
            {{ formatTime(message.created_at) }}
          </div>
        </div>
      </div>
    </div>

    <!-- Input -->
    <div class="p-4 border-t border-gray-200">
      <form @submit.prevent="sendMessage" class="flex space-x-2">
        <input
          v-model="newMessage"
          type="text"
          placeholder="Nhập tin nhắn..."
          class="flex-1 border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          :disabled="sending"
        />
        <button
          type="submit"
          :disabled="!newMessage.trim() || sending"
          class="bg-blue-600 hover:bg-blue-700 disabled:bg-gray-300 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors"
        >
          <PaperAirplaneIcon class="h-4 w-4" />
        </button>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import {
  XMarkIcon,
  ChatBubbleLeftIcon,
  PaperAirplaneIcon
} from '@heroicons/vue/24/outline'

interface ChatMessage {
  id: string
  user_id: number
  username: string
  content: string
  created_at: string
}

// Events
const emit = defineEmits<{
  close: []
  messageSent: []
}>()

// Stores
const authStore = useAuthStore()

// Reactive data
const messages = ref<ChatMessage[]>([])
const newMessage = ref('')
const sending = ref(false)
const messagesContainer = ref<HTMLElement>()

const currentUserId = computed(() => authStore.user?.id)

// Socket connection for chat
const socket = ref<any>()

// Lifecycle
onMounted(() => {
  // Initialize socket connection for chat
  // This would be connected to the same socket instance used for WebRTC signaling
  // For now, we'll simulate it
})

onUnmounted(() => {
  if (socket.value) {
    socket.value.disconnect()
  }
})

// Methods
const sendMessage = async () => {
  if (!newMessage.value.trim() || sending.value) return
  
  sending.value = true
  
  try {
    const message: ChatMessage = {
      id: Date.now().toString(),
      user_id: currentUserId.value!,
      username: authStore.user?.username || 'Unknown',
      content: newMessage.value.trim(),
      created_at: new Date().toISOString()
    }
    
    // Add to local messages immediately for better UX
    messages.value.push(message)
    
    // TODO: Send through socket to other participants
    // socket.value?.emit('chat-message', message)
    
    newMessage.value = ''
    emit('messageSent')
    
    // Scroll to bottom
    nextTick(() => {
      scrollToBottom()
    })
  } catch (error) {
    console.error('Error sending message:', error)
  } finally {
    sending.value = false
  }
}

const formatTime = (timestamp: string) => {
  return new Date(timestamp).toLocaleTimeString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

const scrollToBottom = () => {
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
  }
}

// Watch for new messages to auto-scroll
watch(messages, () => {
  nextTick(() => {
    scrollToBottom()
  })
}, { deep: true })
</script>
