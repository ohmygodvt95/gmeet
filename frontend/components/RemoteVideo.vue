<template>
  <div class="relative bg-gray-800 rounded-lg overflow-hidden">
    <video
      ref="videoElement"
      autoplay
      playsinline
      class="w-full h-full object-cover"
      :class="{ 'opacity-50': !isVideoEnabled }"
    ></video>
    
    <!-- User Info Overlay -->
    <div class="absolute bottom-4 left-4 bg-black bg-opacity-50 text-white px-2 py-1 rounded text-sm">
      {{ participantName }}
    </div>
    
    <!-- Status Indicators -->
    <div class="absolute top-4 right-4 flex space-x-2">
      <div v-if="!isVideoEnabled" class="bg-red-600 p-1 rounded">
        <VideoCameraSlashIcon class="h-4 w-4 text-white" />
      </div>
      <div v-if="!isAudioEnabled" class="bg-red-600 p-1 rounded">
        <NoSymbolIcon class="h-4 w-4 text-white" />
      </div>
      <div v-if="isScreenSharing" class="bg-blue-600 p-1 rounded">
        <ComputerDesktopIcon class="h-4 w-4 text-white" />
      </div>
    </div>
    
    <!-- No Video Placeholder -->
    <div v-if="!isVideoEnabled" class="absolute inset-0 flex items-center justify-center bg-gray-800">
      <div class="text-center text-white">
        <div class="w-16 h-16 bg-gray-600 rounded-full flex items-center justify-center mx-auto mb-2">
          <span class="text-xl font-medium">{{ participantInitials }}</span>
        </div>
        <p class="text-sm">{{ participantName }}</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import {
  VideoCameraSlashIcon,
  NoSymbolIcon,
  ComputerDesktopIcon
} from '@heroicons/vue/24/outline'

interface Props {
  consumerId: string
  consumer: any
  participantName: string
  isVideoEnabled?: boolean
  isAudioEnabled?: boolean
  isScreenSharing?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  isVideoEnabled: true,
  isAudioEnabled: true,
  isScreenSharing: false
})

const videoElement = ref<HTMLVideoElement>()

const participantInitials = computed(() => {
  const names = props.participantName.split(' ')
  if (names.length >= 2) {
    return (names[0][0] + names[names.length - 1][0]).toUpperCase()
  }
  return props.participantName.slice(0, 2).toUpperCase()
})

// Set video stream when consumer changes
watch(() => props.consumer, (consumer) => {
  if (consumer && consumer.track && videoElement.value) {
    const stream = new MediaStream([consumer.track])
    videoElement.value.srcObject = stream
  }
}, { immediate: true })

onMounted(() => {
  if (props.consumer && props.consumer.track && videoElement.value) {
    const stream = new MediaStream([props.consumer.track])
    videoElement.value.srcObject = stream
  }
})

onUnmounted(() => {
  if (videoElement.value) {
    videoElement.value.srcObject = null
  }
})
</script>
