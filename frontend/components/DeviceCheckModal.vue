<template>
  <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
    <div class="relative top-10 mx-auto p-5 border w-full max-w-4xl shadow-lg rounded-md bg-white">
      <div class="mt-3">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-medium text-gray-900">Kiểm tra thiết bị</h3>
          <button
            @click="$emit('close')"
            class="text-gray-400 hover:text-gray-600"
          >
            <XMarkIcon class="h-6 w-6" />
          </button>
        </div>
        
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Camera Preview -->
          <div class="space-y-4">
            <h4 class="text-md font-medium text-gray-900">Camera</h4>
            <div class="relative bg-gray-900 rounded-lg overflow-hidden" style="aspect-ratio: 16/9;">
              <video
                ref="videoPreview"
                autoplay
                muted
                playsinline
                class="w-full h-full object-cover"
              ></video>
              <div v-if="!cameraEnabled" class="absolute inset-0 flex items-center justify-center bg-gray-800">
                <div class="text-center text-white">
                  <VideoCameraSlashIcon class="h-12 w-12 mx-auto mb-2 opacity-50" />
                  <p class="text-sm">Camera đã tắt</p>
                </div>
              </div>
            </div>
            
            <div class="flex items-center justify-between">
              <select
                v-model="selectedVideoDevice"
                @change="changeVideoDevice"
                class="flex-1 mr-2 border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="">Chọn camera</option>
                <option
                  v-for="device in videoDevices"
                  :key="device.deviceId"
                  :value="device.deviceId"
                >
                  {{ device.label || `Camera ${device.deviceId.slice(0, 8)}` }}
                </option>
              </select>
              <button
                @click="toggleCamera"
                :class="[
                  'px-4 py-2 rounded-md text-sm font-medium transition-colors',
                  cameraEnabled 
                    ? 'bg-red-600 hover:bg-red-700 text-white' 
                    : 'bg-green-600 hover:bg-green-700 text-white'
                ]"
              >
                {{ cameraEnabled ? 'Tắt camera' : 'Bật camera' }}
              </button>
            </div>
          </div>
          
          <!-- Audio Test -->
          <div class="space-y-4">
            <h4 class="text-md font-medium text-gray-900">Microphone</h4>
            
            <!-- Audio Level Indicator -->
            <div class="bg-gray-100 rounded-lg p-4">
              <div class="flex items-center space-x-2 mb-2">
                <MicrophoneIcon v-if="micEnabled" class="h-5 w-5 text-green-600" />
                <NoSymbolIcon v-else class="h-5 w-5 text-red-600" />
                <span class="text-sm text-gray-700">
                  {{ micEnabled ? 'Microphone đang hoạt động' : 'Microphone đã tắt' }}
                </span>
              </div>
              
              <!-- Audio Level Bar -->
              <div class="w-full bg-gray-200 rounded-full h-3 mb-2">
                <div
                  class="bg-green-500 h-3 rounded-full transition-all duration-100"
                  :style="{ width: `${audioLevel}%` }"
                ></div>
              </div>
              
              <p class="text-xs text-gray-500">
                Nói thử để kiểm tra microphone. Thanh màu xanh sẽ thay đổi theo âm thanh.
              </p>
            </div>
            
            <div class="flex items-center justify-between">
              <select
                v-model="selectedAudioDevice"
                @change="changeAudioDevice"
                class="flex-1 mr-2 border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="">Chọn microphone</option>
                <option
                  v-for="device in audioDevices"
                  :key="device.deviceId"
                  :value="device.deviceId"
                >
                  {{ device.label || `Microphone ${device.deviceId.slice(0, 8)}` }}
                </option>
              </select>
              <button
                @click="toggleMicrophone"
                :class="[
                  'px-4 py-2 rounded-md text-sm font-medium transition-colors',
                  micEnabled 
                    ? 'bg-red-600 hover:bg-red-700 text-white' 
                    : 'bg-green-600 hover:bg-green-700 text-white'
                ]"
              >
                {{ micEnabled ? 'Tắt mic' : 'Bật mic' }}
              </button>
            </div>
            
            <!-- Speaker Test -->
            <div class="border-t pt-4">
              <h5 class="text-sm font-medium text-gray-900 mb-2">Kiểm tra loa</h5>
              <div class="flex items-center space-x-2">
                <button
                  @click="playTestSound"
                  class="px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md text-sm font-medium transition-colors"
                >
                  Phát âm thanh thử
                </button>
                <span class="text-xs text-gray-500">Bạn có nghe thấy âm thanh không?</span>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Connection Status -->
        <div class="mt-6 pt-6 border-t">
          <h4 class="text-md font-medium text-gray-900 mb-3">Trạng thái kết nối</h4>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="flex items-center space-x-2">
              <div :class="[
                'w-3 h-3 rounded-full',
                networkStatus.online ? 'bg-green-500' : 'bg-red-500'
              ]"></div>
              <span class="text-sm text-gray-700">
                {{ networkStatus.online ? 'Trực tuyến' : 'Ngoại tuyến' }}
              </span>
            </div>
            <div class="flex items-center space-x-2">
              <div :class="[
                'w-3 h-3 rounded-full',
                networkStatus.speed > 1 ? 'bg-green-500' : 'bg-yellow-500'
              ]"></div>
              <span class="text-sm text-gray-700">
                Tốc độ: {{ networkStatus.speed.toFixed(1) }} Mbps
              </span>
            </div>
            <div class="flex items-center space-x-2">
              <div :class="[
                'w-3 h-3 rounded-full',
                networkStatus.latency < 100 ? 'bg-green-500' : 'bg-yellow-500'
              ]"></div>
              <span class="text-sm text-gray-700">
                Ping: {{ networkStatus.latency }}ms
              </span>
            </div>
          </div>
        </div>
        
        <div class="flex justify-end space-x-3 pt-6 border-t mt-6">
          <button
            @click="$emit('close')"
            class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md transition-colors"
          >
            Đóng
          </button>
          <button
            @click="saveSettings"
            class="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-md transition-colors"
          >
            Lưu cài đặt
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import {
  XMarkIcon,
  VideoCameraSlashIcon,
  MicrophoneIcon,
  NoSymbolIcon
} from '@heroicons/vue/24/outline'

// Events
const emit = defineEmits<{
  close: []
}>()

// Reactive data
const videoPreview = ref<HTMLVideoElement>()
const videoDevices = ref<MediaDeviceInfo[]>([])
const audioDevices = ref<MediaDeviceInfo[]>([])
const selectedVideoDevice = ref('')
const selectedAudioDevice = ref('')
const cameraEnabled = ref(true)
const micEnabled = ref(true)
const audioLevel = ref(0)
const currentStream = ref<MediaStream>()
const audioContext = ref<AudioContext>()
const analyser = ref<AnalyserNode>()
const networkStatus = reactive({
  online: navigator.onLine,
  speed: 0,
  latency: 0
})

// Lifecycle
onMounted(async () => {
  await loadDevices()
  await startCamera()
  startAudioLevelDetection()
  checkNetworkStatus()
})

onUnmounted(() => {
  stopStream()
  if (audioContext.value) {
    audioContext.value.close()
  }
})

// Methods
const loadDevices = async () => {
  try {
    const devices = await navigator.mediaDevices.enumerateDevices()
    videoDevices.value = devices.filter(device => device.kind === 'videoinput')
    audioDevices.value = devices.filter(device => device.kind === 'audioinput')
    
    if (videoDevices.value.length > 0) {
      selectedVideoDevice.value = videoDevices.value[0].deviceId
    }
    if (audioDevices.value.length > 0) {
      selectedAudioDevice.value = audioDevices.value[0].deviceId
    }
  } catch (error) {
    console.error('Error loading devices:', error)
  }
}

const startCamera = async () => {
  try {
    const constraints: MediaStreamConstraints = {
      video: selectedVideoDevice.value ? { deviceId: selectedVideoDevice.value } : true,
      audio: selectedAudioDevice.value ? { deviceId: selectedAudioDevice.value } : true
    }
    
    currentStream.value = await navigator.mediaDevices.getUserMedia(constraints)
    
    if (videoPreview.value) {
      videoPreview.value.srcObject = currentStream.value
    }
  } catch (error) {
    console.error('Error starting camera:', error)
    cameraEnabled.value = false
    micEnabled.value = false
  }
}

const stopStream = () => {
  if (currentStream.value) {
    currentStream.value.getTracks().forEach(track => track.stop())
    currentStream.value = undefined
  }
}

const toggleCamera = async () => {
  if (cameraEnabled.value) {
    // Turn off camera
    if (currentStream.value) {
      const videoTracks = currentStream.value.getVideoTracks()
      videoTracks.forEach(track => track.stop())
    }
    cameraEnabled.value = false
  } else {
    // Turn on camera
    await changeVideoDevice()
    cameraEnabled.value = true
  }
}

const toggleMicrophone = () => {
  if (currentStream.value) {
    const audioTracks = currentStream.value.getAudioTracks()
    audioTracks.forEach(track => {
      track.enabled = !micEnabled.value
    })
  }
  micEnabled.value = !micEnabled.value
}

const changeVideoDevice = async () => {
  if (!selectedVideoDevice.value) return
  
  stopStream()
  await startCamera()
}

const changeAudioDevice = async () => {
  if (!selectedAudioDevice.value) return
  
  stopStream()
  await startCamera()
  startAudioLevelDetection()
}

const startAudioLevelDetection = () => {
  if (!currentStream.value) return
  
  try {
    audioContext.value = new AudioContext()
    analyser.value = audioContext.value.createAnalyser()
    
    const source = audioContext.value.createMediaStreamSource(currentStream.value)
    source.connect(analyser.value)
    
    analyser.value.fftSize = 256
    const bufferLength = analyser.value.frequencyBinCount
    const dataArray = new Uint8Array(bufferLength)
    
    const updateAudioLevel = () => {
      if (!analyser.value) return
      
      analyser.value.getByteFrequencyData(dataArray)
      const average = dataArray.reduce((sum, value) => sum + value, 0) / bufferLength
      audioLevel.value = Math.min(100, (average / 255) * 100 * 3) // Amplify for better visualization
      
      requestAnimationFrame(updateAudioLevel)
    }
    
    updateAudioLevel()
  } catch (error) {
    console.error('Error setting up audio level detection:', error)
  }
}

const playTestSound = () => {
  // Create a simple beep sound
  if (!audioContext.value) {
    audioContext.value = new AudioContext()
  }
  
  const oscillator = audioContext.value.createOscillator()
  const gainNode = audioContext.value.createGain()
  
  oscillator.connect(gainNode)
  gainNode.connect(audioContext.value.destination)
  
  oscillator.frequency.value = 800
  oscillator.type = 'sine'
  
  gainNode.gain.setValueAtTime(0.3, audioContext.value.currentTime)
  gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.value.currentTime + 0.5)
  
  oscillator.start(audioContext.value.currentTime)
  oscillator.stop(audioContext.value.currentTime + 0.5)
}

const checkNetworkStatus = async () => {
  // Update online status
  networkStatus.online = navigator.onLine
  
  // Simple network speed test
  try {
    const start = performance.now()
    const response = await fetch('/api/ping', { method: 'HEAD' })
    const end = performance.now()
    
    networkStatus.latency = Math.round(end - start)
    
    // Estimate speed (very rough)
    if (networkStatus.latency < 50) {
      networkStatus.speed = 10
    } else if (networkStatus.latency < 100) {
      networkStatus.speed = 5
    } else {
      networkStatus.speed = 1
    }
  } catch (error) {
    networkStatus.latency = 999
    networkStatus.speed = 0
  }
}

const saveSettings = () => {
  // Save device preferences to localStorage
  const settings = {
    videoDevice: selectedVideoDevice.value,
    audioDevice: selectedAudioDevice.value,
    cameraEnabled: cameraEnabled.value,
    micEnabled: micEnabled.value
  }
  
  localStorage.setItem('deviceSettings', JSON.stringify(settings))
  emit('close')
}

// Listen for network status changes
window.addEventListener('online', () => {
  networkStatus.online = true
})

window.addEventListener('offline', () => {
  networkStatus.online = false
})
</script>
