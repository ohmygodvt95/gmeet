<template>
  <div class="min-h-screen bg-gray-900">
    <!-- Loading State -->
    <div v-if="loading" class="flex items-center justify-center min-h-screen">
      <div class="text-center text-white">
        <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-white mb-4"></div>
        <p>Đang tải phòng họp...</p>
      </div>
    </div>

    <!-- Room Not Found -->
    <div v-else-if="!currentRoom" class="flex items-center justify-center min-h-screen">
      <div class="text-center text-white">
        <h2 class="text-2xl font-bold mb-2">Phòng họp không tồn tại</h2>
        <p class="text-gray-300 mb-6">Phòng họp bạn đang tìm kiếm không tồn tại hoặc đã bị xóa.</p>
        <NuxtLink
          to="/dashboard"
          class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-md font-medium transition-colors"
        >
          Về trang chủ
        </NuxtLink>
      </div>
    </div>

    <!-- Main Meeting Interface -->
    <div v-else class="flex flex-col h-screen">
      <!-- Top Bar -->
      <header class="bg-gray-800 text-white px-6 py-4 flex items-center justify-between border-b border-gray-700">
        <div class="flex items-center space-x-4">
          <h1 class="text-xl font-semibold">{{ currentRoom.title }}</h1>
          <div class="flex items-center space-x-2 text-sm text-gray-300">
            <span>{{ participantCount }} người tham gia</span>
          </div>
        </div>
        
        <div class="flex items-center space-x-3">
          <!-- Room ID Copy -->
          <div class="flex items-center space-x-2 bg-gray-700 px-3 py-2 rounded-md">
            <span class="text-sm text-gray-300">ID:</span>
            <span class="text-sm font-mono">{{ roomId.slice(0, 8) }}</span>
            <button
              @click="copyRoomLink"
              class="text-gray-400 hover:text-white transition-colors"
              title="Sao chép link phòng"
            >
              📋
            </button>
          </div>
          
          <!-- Leave Room -->
          <button
            @click="leaveRoom"
            class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors"
          >
            Rời phòng
          </button>
        </div>
      </header>

      <!-- Main Content -->
      <div class="flex-1 flex">
        <!-- Video Grid -->
        <div class="flex-1 relative">
          <!-- Before Join Screen -->
          <div v-if="!hasJoined" class="absolute inset-0 bg-gray-900 flex items-center justify-center z-10">
            <div class="bg-white rounded-lg p-8 max-w-md w-full mx-4">
              <h3 class="text-lg font-semibold text-gray-900 mb-4">Chuẩn bị tham gia cuộc họp</h3>
              
              <!-- Device Preview -->
              <div class="mb-6">
                <div class="relative bg-gray-900 rounded-lg overflow-hidden mb-4" style="aspect-ratio: 16/9;">
                  <video
                    ref="previewVideo"
                    autoplay
                    muted
                    playsinline
                    class="w-full h-full object-cover"
                  ></video>
                  <div v-if="!deviceSettings.camera" class="absolute inset-0 flex items-center justify-center bg-gray-800">
                    <div class="text-center text-white">
                      <div class="text-4xl mb-2">📹</div>
                      <p class="text-sm">Camera đã tắt</p>
                    </div>
                  </div>
                </div>
                
                <div class="flex items-center justify-center space-x-4">
                  <button
                    @click="togglePreviewCamera"
                    :class="[
                      'p-3 rounded-full transition-colors',
                      deviceSettings.camera 
                        ? 'bg-gray-600 hover:bg-gray-700 text-white' 
                        : 'bg-red-600 hover:bg-red-700 text-white'
                    ]"
                  >
                    {{ deviceSettings.camera ? '📹' : '🚫' }}
                  </button>
                  
                  <button
                    @click="togglePreviewMicrophone"
                    :class="[
                      'p-3 rounded-full transition-colors',
                      deviceSettings.microphone 
                        ? 'bg-gray-600 hover:bg-gray-700 text-white' 
                        : 'bg-red-600 hover:bg-red-700 text-white'
                    ]"
                  >
                    {{ deviceSettings.microphone ? '🎤' : '🔇' }}
                  </button>
                </div>
              </div>
              
              <div class="flex space-x-3">
                <button
                  @click="joinMeeting"
                  :disabled="joining"
                  class="flex-1 bg-blue-600 hover:bg-blue-700 text-white py-3 px-4 rounded-md font-medium transition-colors disabled:opacity-50"
                >
                  <span v-if="joining">Đang tham gia...</span>
                  <span v-else>Tham gia ngay</span>
                </button>
                <NuxtLink
                  to="/dashboard"
                  class="px-4 py-3 text-gray-600 hover:text-gray-800 transition-colors"
                >
                  Hủy
                </NuxtLink>
              </div>
            </div>
          </div>

          <!-- Meeting Interface -->
          <div v-else class="h-full flex flex-col">
            <!-- Video Grid -->
            <div class="flex-1 p-4">
              <div class="grid gap-4 h-full grid-cols-2">
                <!-- Local Video -->
                <div class="relative bg-gray-800 rounded-lg overflow-hidden">
                  <video
                    ref="localVideo"
                    autoplay
                    muted
                    playsinline
                    class="w-full h-full object-cover"
                  ></video>
                  <div class="absolute bottom-4 left-4 bg-black bg-opacity-50 text-white px-2 py-1 rounded text-sm">
                    Bạn
                  </div>
                  <div class="absolute top-4 right-4 flex space-x-2">
                    <div v-if="!deviceSettings.camera" class="bg-red-600 p-1 rounded text-white text-xs">
                      🚫📹
                    </div>
                    <div v-if="!deviceSettings.microphone" class="bg-red-600 p-1 rounded text-white text-xs">
                      🔇
                    </div>
                  </div>
                </div>

                <!-- Remote Video Placeholder -->
                <div class="relative bg-gray-800 rounded-lg overflow-hidden flex items-center justify-center">
                  <div class="text-center text-white">
                    <div class="text-4xl mb-2">👥</div>
                    <p class="text-sm">Đang chờ người khác tham gia...</p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Controls Bar -->
            <div class="bg-gray-800 border-t border-gray-700 p-4">
              <div class="flex items-center justify-center space-x-4">
                <!-- Microphone Toggle -->
                <button
                  @click="toggleMicrophone"
                  :class="[
                    'p-4 rounded-full transition-colors text-2xl',
                    deviceSettings.microphone 
                      ? 'bg-gray-600 hover:bg-gray-700 text-white' 
                      : 'bg-red-600 hover:bg-red-700 text-white'
                  ]"
                >
                  {{ deviceSettings.microphone ? '🎤' : '🔇' }}
                </button>

                <!-- Camera Toggle -->
                <button
                  @click="toggleCamera"
                  :class="[
                    'p-4 rounded-full transition-colors text-2xl',
                    deviceSettings.camera 
                      ? 'bg-gray-600 hover:bg-gray-700 text-white' 
                      : 'bg-red-600 hover:bg-red-700 text-white'
                  ]"
                >
                  {{ deviceSettings.camera ? '📹' : '🚫' }}
                </button>

                <!-- Screen Share -->
                <button
                  @click="toggleScreenShare"
                  :class="[
                    'p-4 rounded-full transition-colors text-2xl',
                    isScreenSharing
                      ? 'bg-blue-600 hover:bg-blue-700 text-white'
                      : 'bg-gray-600 hover:bg-gray-700 text-white'
                  ]"
                >
                  🖥️
                </button>

                <!-- Chat Toggle -->
                <button
                  @click="showChat = !showChat"
                  class="p-4 rounded-full bg-gray-600 hover:bg-gray-700 text-white transition-colors text-2xl relative"
                >
                  💬
                  <div v-if="unreadMessages > 0" class="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                    {{ unreadMessages }}
                  </div>
                </button>

                <!-- Leave -->
                <button
                  @click="leaveRoom"
                  class="p-4 rounded-full bg-red-600 hover:bg-red-700 text-white transition-colors text-2xl"
                >
                  📞
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Chat Sidebar -->
        <div v-if="showChat" class="w-80 bg-white border-l border-gray-200 flex flex-col">
          <div class="p-4 border-b border-gray-200 flex items-center justify-between">
            <h3 class="font-semibold">Chat</h3>
            <button @click="showChat = false" class="text-gray-500 hover:text-gray-700">
              ✕
            </button>
          </div>
          <div class="flex-1 overflow-y-auto p-4">
            <p class="text-gray-500 text-center">Tính năng chat đang được phát triển...</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import {
  ExclamationTriangleIcon,
  UsersIcon,
  ClipboardIcon,
  VideoCameraIcon,
  VideoCameraSlashIcon,
  MicrophoneIcon,
  NoSymbolIcon,
  CogIcon,
  ComputerDesktopIcon,
  ChatBubbleLeftIcon,
  PhoneIcon
} from '@heroicons/vue/24/outline'

// Define page meta
definePageMeta({
  middleware: 'auth'
})

// Route parameter
const route = useRoute()
const router = useRouter()
const roomId = route.params.id as string

// Stores
const authStore = useAuthStore()
const roomStore = useRoomStore()

// Composables  
const sfu = useSFU()
const { $toast } = useNuxtApp()

// Initialize SFU
onMounted(async () => {
  if (process.client) {
    const token = authStore.token
    if (token) {
      try {
        await sfu.initSFU(token)
        await sfu.getAvailableDevices()
      } catch (error) {
        console.error('Failed to initialize SFU:', error)
      }
    }
  }
  
  await loadRoom()
  await setupPreview()
})

// Reactive data
const user = computed(() => authStore.user)
const currentRoom = computed(() => roomStore.currentRoom)
const participants = computed(() => {
  const roomParticipants = roomStore.currentRoom?.participants || []
  return roomParticipants
})
const remoteParticipants = computed(() => 
  participants.value.filter(p => p.user_id !== user.value?.id)
)

const loading = ref(true)
const hasJoined = ref(false)
const joining = ref(false)
const showChat = ref(false)
const showDeviceSettings = ref(false)
const unreadMessages = ref(0)
const isScreenSharing = computed(() => sfu.mediaState.value.isScreenSharing)

const previewVideo = ref<HTMLVideoElement>()
const localVideo = ref<HTMLVideoElement>()
const previewStream = ref<MediaStream>()

const deviceSettings = reactive({
  camera: true,
  microphone: true
})

// Methods
const loadRoom = async () => {
  loading.value = true
  try {
    await roomStore.fetchRoom(roomId)
  } catch (error) {
    console.error('Error loading room:', error)
  } finally {
    loading.value = false
  }
}

const setupPreview = async () => {
  try {
    const constraints = {
      video: deviceSettings.camera,
      audio: deviceSettings.microphone
    }
    
    previewStream.value = await navigator.mediaDevices.getUserMedia(constraints)
    
    if (previewVideo.value) {
      previewVideo.value.srcObject = previewStream.value
    }
  } catch (error) {
    console.error('Error setting up preview:', error)
    deviceSettings.camera = false
    deviceSettings.microphone = false
  }
}

const stopPreview = () => {
  if (previewStream.value) {
    previewStream.value.getTracks().forEach(track => track.stop())
    previewStream.value = undefined
  }
}

const togglePreviewCamera = async () => {
  deviceSettings.camera = !deviceSettings.camera
  await setupPreview()
}

const togglePreviewMicrophone = () => {
  deviceSettings.microphone = !deviceSettings.microphone
  if (previewStream.value) {
    const audioTracks = previewStream.value.getAudioTracks()
    audioTracks.forEach(track => {
      track.enabled = deviceSettings.microphone
    })
  }
}

const joinMeeting = async () => {
  joining.value = true
  
  try {
    // Join room in backend
    await roomStore.joinRoom(roomId)
    
    // Stop preview
    stopPreview()
    
    // Get user media with current settings
    await sfu.getUserMedia(deviceSettings.microphone, deviceSettings.camera)
    
    // Join SFU room
    await sfu.joinSFURoom(roomId)
    
    // Set local video
    if (localVideo.value && sfu.localStream.value) {
      localVideo.value.srcObject = sfu.localStream.value
    }
    
    hasJoined.value = true
    
    if ($toast && typeof $toast.success === 'function') {
      $toast.success('Đã tham gia cuộc họp')
    }
  } catch (error: any) {
    console.error('Error joining meeting:', error)
    if ($toast && typeof $toast.error === 'function') {
      $toast.error(error.message || 'Không thể tham gia cuộc họp')
    }
  } finally {
    joining.value = false
  }
}

const leaveRoom = async () => {
  if (hasJoined.value) {
    sfu.leaveSFURoom()
    await roomStore.leaveRoom(roomId)
  }
  
  await router.push('/dashboard')
}

const toggleCamera = async () => {
  if (hasJoined.value) {
    await sfu.toggleVideo()
    deviceSettings.camera = sfu.mediaState.value.isVideoEnabled
  } else {
    await togglePreviewCamera()
  }
}

const toggleMicrophone = async () => {
  if (hasJoined.value) {
    await sfu.toggleAudio()
    deviceSettings.microphone = sfu.mediaState.value.isAudioEnabled
  } else {
    togglePreviewMicrophone()
  }
}

const toggleScreenShare = async () => {
  if (hasJoined.value) {
    await sfu.toggleScreenShare()
  }
}

const copyRoomLink = () => {
  const url = `${window.location.origin}/room/${roomId}`
  navigator.clipboard.writeText(url)
  if ($toast && typeof $toast.success === 'function') {
    $toast.success('Đã sao chép link phòng')
  }
}

const onMessageSent = () => {
  // Reset unread count when user sends a message
  unreadMessages.value = 0
}

const getGridClass = (count: number) => {
  if (count <= 1) return 'grid-cols-1'
  if (count <= 4) return 'grid-cols-2'
  if (count <= 9) return 'grid-cols-3'
  return 'grid-cols-4'
}

const getParticipantName = (consumer: any) => {
  // For now return a default name, this should be mapped from SFU participant data
  return 'Người tham gia'
}

// Cleanup
onUnmounted(() => {
  if (hasJoined.value) {
    sfu.disconnectSFU()
  }
  stopPreview()
})

// Watch for chat visibility to reset unread count
watch(showChat, (isVisible) => {
  if (isVisible) {
    unreadMessages.value = 0
  }
})

// Watch SFU participants and update remote videos
watch(() => sfu.consumers.value, (consumers) => {
  nextTick(() => {
    consumers.forEach((consumer, consumerId) => {
      if (consumer.track) {
        const stream = new MediaStream([consumer.track])
        const videoElement = document.querySelector(`video[data-consumer-id="${consumerId}"]`) as HTMLVideoElement
        if (videoElement) {
          videoElement.srcObject = stream
        }
      }
    })
  })
}, { deep: true })
</script>
