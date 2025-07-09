<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <header class="bg-white shadow-sm border-b">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between items-center h-16">
          <div class="flex items-center">
            <h1 class="text-2xl font-bold text-gray-900">GMeeting</h1>
          </div>
          <div class="flex items-center space-x-4">
            <span class="text-sm text-gray-700">{{ user?.fullName || user?.username }}</span>
            <button
              @click="logout"
              class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors"
            >
              Đăng xuất
            </button>
          </div>
        </div>
      </div>
    </header>

    <!-- Main Content -->
    <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
      <div class="px-4 py-6 sm:px-0">
        <!-- Quick Actions -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
          <!-- Create Room -->
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-6">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <PlusIcon class="h-8 w-8 text-blue-600" />
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Tạo phòng họp</dt>
                    <dd class="text-lg font-medium text-gray-900">Bắt đầu ngay</dd>
                  </dl>
                </div>
              </div>
              <div class="mt-4">
                <button
                  @click="showCreateRoomModal = true"
                  class="w-full bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors"
                >
                  Tạo phòng mới
                </button>
              </div>
            </div>
          </div>

          <!-- Join Room -->
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-6">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <ArrowRightOnRectangleIcon class="h-8 w-8 text-green-600" />
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Tham gia phòng</dt>
                    <dd class="text-lg font-medium text-gray-900">Bằng mã phòng</dd>
                  </dl>
                </div>
              </div>
              <div class="mt-4">
                <button
                  @click="showJoinRoomModal = true"
                  class="w-full bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors"
                >
                  Tham gia phòng
                </button>
              </div>
            </div>
          </div>

          <!-- Device Check -->
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-6">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <CogIcon class="h-8 w-8 text-purple-600" />
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Kiểm tra thiết bị</dt>
                    <dd class="text-lg font-medium text-gray-900">Camera & Mic</dd>
                  </dl>
                </div>
              </div>
              <div class="mt-4">
                <button
                  @click="showDeviceCheck = true"
                  class="w-full bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors"
                >
                  Kiểm tra thiết bị
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Room List -->
        <div class="bg-white shadow rounded-lg">
          <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-medium text-gray-900">Phòng họp của bạn</h3>
          </div>
          <div class="px-6 py-4">
            <div v-if="loading" class="text-center">
              <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            </div>
            <div v-else-if="rooms.length === 0" class="text-center text-gray-500 py-8">
              <VideoCameraSlashIcon class="mx-auto h-12 w-12 text-gray-400" />
              <h3 class="mt-2 text-sm font-medium text-gray-900">Chưa có phòng họp nào</h3>
              <p class="mt-1 text-sm text-gray-500">Tạo phòng họp đầu tiên của bạn</p>
            </div>
            <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <div
                v-for="room in rooms"
                :key="room.id"
                class="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
              >
                <div class="flex items-center justify-between mb-2">
                  <h4 class="font-medium text-gray-900">{{ room.title }}</h4>
                  <div class="flex space-x-2">
                    <button
                      @click="joinRoom(room.id)"
                      class="text-blue-600 hover:text-blue-800"
                      title="Tham gia"
                    >
                      <ArrowRightOnRectangleIcon class="h-5 w-5" />
                    </button>
                    <button
                      @click="deleteRoom(room.id)"
                      class="text-red-600 hover:text-red-800"
                      title="Xóa"
                    >
                      <TrashIcon class="h-5 w-5" />
                    </button>
                  </div>
                </div>
                <p class="text-sm text-gray-600 mb-2">{{ room.description || 'Không có mô tả' }}</p>
                <div class="flex items-center justify-between text-xs text-gray-500">
                  <span>ID: {{ room.id.slice(0, 8) }}</span>
                  <span>{{ room.participants?.length || 0 }} người</span>
                </div>
                <div class="mt-2">
                  <span class="text-xs text-gray-500">Tạo: {{ formatDate(room.created_at) }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- Modals -->
    <CreateRoomModal
      v-if="showCreateRoomModal"
      @close="showCreateRoomModal = false"
      @created="onRoomCreated"
    />
    <JoinRoomModal
      v-if="showJoinRoomModal"
      @close="showJoinRoomModal = false"
      @joined="onRoomJoined"
    />
    <DeviceCheckModal
      v-if="showDeviceCheck"
      @close="showDeviceCheck = false"
    />
  </div>
</template>

<script setup lang="ts">
import {
  PlusIcon,
  ArrowRightOnRectangleIcon,
  CogIcon,
  VideoCameraSlashIcon,
  TrashIcon
} from '@heroicons/vue/24/outline'

// Auth middleware
definePageMeta({
  middleware: 'auth'
})

// Stores
const authStore = useAuthStore()
const roomStore = useRoomStore()
const { $toast } = useNuxtApp()

// Reactive data
const user = computed(() => authStore.user)
const rooms = computed(() => roomStore.rooms)
const loading = ref(false)
const showCreateRoomModal = ref(false)
const showJoinRoomModal = ref(false)
const showDeviceCheck = ref(false)

// Lifecycle
onMounted(async () => {
  await fetchRooms()
})

// Methods
const fetchRooms = async () => {
  loading.value = true
  try {
    await roomStore.fetchRooms()
  } catch (error) {
    console.error('Error fetching rooms:', error)
    $toast.error('Không thể tải danh sách phòng họp')
  } finally {
    loading.value = false
  }
}

const logout = async () => {
  try {
    await authStore.logout()
    await navigateTo('/')
  } catch (error) {
    console.error('Logout error:', error)
    $toast.error('Đăng xuất thất bại')
  }
}

const joinRoom = async (roomId: string) => {
  await navigateTo(`/room/${roomId}`)
}

const deleteRoom = async (roomId: string) => {
  if (!confirm('Bạn có chắc chắn muốn xóa phòng này?')) return
  
  try {
    await roomStore.deleteRoom(roomId)
    $toast.success('Xóa phòng thành công')
    await fetchRooms()
  } catch (error) {
    console.error('Error deleting room:', error)
    $toast.error('Không thể xóa phòng')
  }
}

const onRoomCreated = async (room: any) => {
  showCreateRoomModal.value = false
  $toast.success('Tạo phòng thành công')
  await fetchRooms()
  await navigateTo(`/room/${room.id}`)
}

const onRoomJoined = async (roomId: string) => {
  showJoinRoomModal.value = false
  await navigateTo(`/room/${roomId}`)
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('vi-VN', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}
</script>
