import { io, Socket } from 'socket.io-client'
import { ref, onUnmounted } from 'vue'

interface MediaDevices {
  camera: MediaDeviceInfo[]
  microphone: MediaDeviceInfo[]
  speaker: MediaDeviceInfo[]
}

interface MediaState {
  isAudioEnabled: boolean
  isVideoEnabled: boolean
  isScreenSharing: boolean
}

interface Participant {
  userId: number
  username: string
  fullName: string
  stream?: MediaStream
  mediaState: MediaState
}

export const useWebRTC = () => {
  const socket = ref<Socket | null>(null)
  const localStream = ref<MediaStream | null>(null)
  const participants = ref<Map<number, Participant>>(new Map())
  const peerConnections = ref<Map<number, RTCPeerConnection>>(new Map())
  const isConnected = ref(false)
  const roomId = ref<string | null>(null)
  
  const mediaState = ref<MediaState>({
    isAudioEnabled: true,
    isVideoEnabled: true,
    isScreenSharing: false
  })

  const availableDevices = ref<MediaDevices>({
    camera: [],
    microphone: [],
    speaker: []
  })

  const selectedDevices = ref({
    camera: '',
    microphone: '',
    speaker: ''
  })

  // WebRTC configuration
  const rtcConfig = {
    iceServers: [
      { urls: 'stun:stun.l.google.com:19302' }
    ]
  }

  // Initialize socket connection
  const initSocket = (token: string) => {
    const config = useRuntimeConfig()
    
    socket.value = io(config.public.socketUrl, {
      auth: {
        token
      }
    })

    setupSocketListeners()
  }

  // Setup socket event listeners
  const setupSocketListeners = () => {
    if (!socket.value) return

    socket.value.on('connect', () => {
      isConnected.value = true
      console.log('Connected to socket server')
    })

    socket.value.on('disconnect', () => {
      isConnected.value = false
      console.log('Disconnected from socket server')
    })

    socket.value.on('room-joined', handleRoomJoined)
    socket.value.on('user-joined', handleUserJoined)
    socket.value.on('user-left', handleUserLeft)
    socket.value.on('offer', handleOffer)
    socket.value.on('answer', handleAnswer)
    socket.value.on('ice-candidate', handleIceCandidate)
    socket.value.on('user-audio-toggle', handleUserAudioToggle)
    socket.value.on('user-video-toggle', handleUserVideoToggle)
    socket.value.on('user-screen-share-toggle', handleUserScreenShareToggle)
    socket.value.on('room-deleted', handleRoomDeleted)
    socket.value.on('error', handleSocketError)
  }

  // Get available media devices
  const getAvailableDevices = async () => {
    try {
      const devices = await navigator.mediaDevices.enumerateDevices()
      
      availableDevices.value = {
        camera: devices.filter(device => device.kind === 'videoinput'),
        microphone: devices.filter(device => device.kind === 'audioinput'),
        speaker: devices.filter(device => device.kind === 'audiooutput')
      }

      // Set default devices
      if (availableDevices.value.camera.length > 0 && !selectedDevices.value.camera) {
        selectedDevices.value.camera = availableDevices.value.camera[0].deviceId
      }
      if (availableDevices.value.microphone.length > 0 && !selectedDevices.value.microphone) {
        selectedDevices.value.microphone = availableDevices.value.microphone[0].deviceId
      }
      if (availableDevices.value.speaker.length > 0 && !selectedDevices.value.speaker) {
        selectedDevices.value.speaker = availableDevices.value.speaker[0].deviceId
      }
    } catch (error) {
      console.error('Error getting media devices:', error)
    }
  }

  // Get user media
  const getUserMedia = async (audio = true, video = true) => {
    try {
      const constraints: MediaStreamConstraints = {
        audio: audio ? {
          deviceId: selectedDevices.value.microphone ? { exact: selectedDevices.value.microphone } : undefined
        } : false,
        video: video ? {
          deviceId: selectedDevices.value.camera ? { exact: selectedDevices.value.camera } : undefined,
          width: { ideal: 1280 },
          height: { ideal: 720 }
        } : false
      }

      localStream.value = await navigator.mediaDevices.getUserMedia(constraints)
      return localStream.value
    } catch (error) {
      console.error('Error accessing media devices:', error)
      throw error
    }
  }

  // Get screen share
  const getScreenShare = async () => {
    try {
      const screenStream = await navigator.mediaDevices.getDisplayMedia({
        video: true,
        audio: true
      })

      return screenStream
    } catch (error) {
      console.error('Error accessing screen share:', error)
      throw error
    }
  }

  // Join room
  const joinRoom = async (roomIdParam: string) => {
    if (!socket.value) {
      throw new Error('Socket not initialized')
    }

    roomId.value = roomIdParam
    
    // Get user media first
    await getUserMedia()
    
    // Join room via socket
    socket.value.emit('join-room', { roomId: roomIdParam })
  }

  // Leave room
  const leaveRoom = () => {
    if (socket.value && roomId.value) {
      socket.value.emit('leave-room', { roomId: roomId.value })
    }

    // Clean up
    cleanup()
  }

  // Create peer connection
  const createPeerConnection = (userId: number) => {
    const peerConnection = new RTCPeerConnection(rtcConfig)

    // Add local stream tracks
    if (localStream.value) {
      localStream.value.getTracks().forEach(track => {
        peerConnection.addTrack(track, localStream.value!)
      })
    }

    // Handle remote stream
    peerConnection.ontrack = (event) => {
      const participant = participants.value.get(userId)
      if (participant) {
        participant.stream = event.streams[0]
        participants.value.set(userId, participant)
      }
    }

    // Handle ICE candidates
    peerConnection.onicecandidate = (event) => {
      if (event.candidate && socket.value) {
        socket.value.emit('ice-candidate', {
          targetUserId: userId,
          candidate: event.candidate
        })
      }
    }

    peerConnections.value.set(userId, peerConnection)
    return peerConnection
  }

  // Socket event handlers
  const handleRoomJoined = (data: any) => {
    console.log('Joined room:', data)
    
    // Add existing participants
    data.participants.forEach((participant: any) => {
      if (participant.userId !== useAuthStore().user?.id) {
        participants.value.set(participant.userId, {
          userId: participant.userId,
          username: participant.username,
          fullName: participant.fullName || participant.username,
          mediaState: {
            isAudioEnabled: true,
            isVideoEnabled: true,
            isScreenSharing: false
          }
        })
      }
    })
  }

  const handleUserJoined = async (data: any) => {
    console.log('User joined:', data.user)
    
    const userId = data.user.userId
    participants.value.set(userId, {
      userId,
      username: data.user.username,
      fullName: data.user.fullName || data.user.username,
      mediaState: {
        isAudioEnabled: true,
        isVideoEnabled: true,
        isScreenSharing: false
      }
    })

    // Create peer connection and send offer
    const peerConnection = createPeerConnection(userId)
    
    try {
      const offer = await peerConnection.createOffer()
      await peerConnection.setLocalDescription(offer)
      
      if (socket.value) {
        socket.value.emit('offer', {
          roomId: roomId.value,
          targetUserId: userId,
          offer
        })
      }
    } catch (error) {
      console.error('Error creating offer:', error)
    }
  }

  const handleUserLeft = (data: any) => {
    console.log('User left:', data.user)
    
    const userId = data.user.userId
    
    // Close peer connection
    const peerConnection = peerConnections.value.get(userId)
    if (peerConnection) {
      peerConnection.close()
      peerConnections.value.delete(userId)
    }
    
    // Remove participant
    participants.value.delete(userId)
  }

  const handleOffer = async (data: any) => {
    console.log('Received offer from:', data.fromUser.username)
    
    const userId = data.from
    const peerConnection = createPeerConnection(userId)
    
    try {
      await peerConnection.setRemoteDescription(data.offer)
      const answer = await peerConnection.createAnswer()
      await peerConnection.setLocalDescription(answer)
      
      if (socket.value) {
        socket.value.emit('answer', {
          targetUserId: userId,
          answer
        })
      }
    } catch (error) {
      console.error('Error handling offer:', error)
    }
  }

  const handleAnswer = async (data: any) => {
    console.log('Received answer from:', data.fromUser.username)
    
    const userId = data.from
    const peerConnection = peerConnections.value.get(userId)
    
    if (peerConnection) {
      try {
        await peerConnection.setRemoteDescription(data.answer)
      } catch (error) {
        console.error('Error handling answer:', error)
      }
    }
  }

  const handleIceCandidate = async (data: any) => {
    const userId = data.from
    const peerConnection = peerConnections.value.get(userId)
    
    if (peerConnection) {
      try {
        await peerConnection.addIceCandidate(data.candidate)
      } catch (error) {
        console.error('Error adding ICE candidate:', error)
      }
    }
  }

  const handleUserAudioToggle = (data: any) => {
    const participant = participants.value.get(data.userId)
    if (participant) {
      participant.mediaState.isAudioEnabled = data.isEnabled
      participants.value.set(data.userId, participant)
    }
  }

  const handleUserVideoToggle = (data: any) => {
    const participant = participants.value.get(data.userId)
    if (participant) {
      participant.mediaState.isVideoEnabled = data.isEnabled
      participants.value.set(data.userId, participant)
    }
  }

  const handleUserScreenShareToggle = (data: any) => {
    const participant = participants.value.get(data.userId)
    if (participant) {
      participant.mediaState.isScreenSharing = data.isEnabled
      participants.value.set(data.userId, participant)
    }
  }

  const handleRoomDeleted = () => {
    console.log('Room was deleted')
    cleanup()
    navigateTo('/dashboard')
  }

  const handleSocketError = (data: any) => {
    console.error('Socket error:', data.message)
  }

  // Media controls
  const toggleAudio = () => {
    if (localStream.value) {
      const audioTrack = localStream.value.getAudioTracks()[0]
      if (audioTrack) {
        audioTrack.enabled = !audioTrack.enabled
        mediaState.value.isAudioEnabled = audioTrack.enabled
        
        if (socket.value && roomId.value) {
          socket.value.emit('toggle-audio', {
            roomId: roomId.value,
            isEnabled: audioTrack.enabled
          })
        }
      }
    }
  }

  const toggleVideo = () => {
    if (localStream.value) {
      const videoTrack = localStream.value.getVideoTracks()[0]
      if (videoTrack) {
        videoTrack.enabled = !videoTrack.enabled
        mediaState.value.isVideoEnabled = videoTrack.enabled
        
        if (socket.value && roomId.value) {
          socket.value.emit('toggle-video', {
            roomId: roomId.value,
            isEnabled: videoTrack.enabled
          })
        }
      }
    }
  }

  const toggleScreenShare = async () => {
    try {
      if (!mediaState.value.isScreenSharing) {
        // Start screen sharing
        const screenStream = await getScreenShare()
        const videoTrack = screenStream.getVideoTracks()[0]
        
        if (localStream.value && videoTrack) {
          // Replace video track in local stream
          const sender = Array.from(peerConnections.value.values()).map(pc => 
            pc.getSenders().find(s => s.track?.kind === 'video')
          ).filter(Boolean)
          
          await Promise.all(
            sender.map(s => s!.replaceTrack(videoTrack))
          )
          
          // Replace in local stream
          const oldVideoTrack = localStream.value.getVideoTracks()[0]
          if (oldVideoTrack) {
            localStream.value.removeTrack(oldVideoTrack)
            oldVideoTrack.stop()
          }
          
          localStream.value.addTrack(videoTrack)
          mediaState.value.isScreenSharing = true
          
          // Handle screen share end
          videoTrack.onended = () => {
            stopScreenShare()
          }
        }
      } else {
        // Stop screen sharing
        await stopScreenShare()
      }
      
      if (socket.value && roomId.value) {
        socket.value.emit('toggle-screen-share', {
          roomId: roomId.value,
          isEnabled: mediaState.value.isScreenSharing
        })
      }
    } catch (error) {
      console.error('Error toggling screen share:', error)
    }
  }

  const stopScreenShare = async () => {
    try {
      // Get camera stream again
      const cameraStream = await navigator.mediaDevices.getUserMedia({
        video: {
          deviceId: selectedDevices.value.camera ? { exact: selectedDevices.value.camera } : undefined
        }
      })
      
      const videoTrack = cameraStream.getVideoTracks()[0]
      
      if (localStream.value && videoTrack) {
        // Replace screen share track with camera track
        const sender = Array.from(peerConnections.value.values()).map(pc => 
          pc.getSenders().find(s => s.track?.kind === 'video')
        ).filter(Boolean)
        
        await Promise.all(
          sender.map(s => s!.replaceTrack(videoTrack))
        )
        
        // Replace in local stream
        const oldVideoTrack = localStream.value.getVideoTracks()[0]
        if (oldVideoTrack) {
          localStream.value.removeTrack(oldVideoTrack)
          oldVideoTrack.stop()
        }
        
        localStream.value.addTrack(videoTrack)
        mediaState.value.isScreenSharing = false
      }
    } catch (error) {
      console.error('Error stopping screen share:', error)
    }
  }

  // Change media devices
  const changeCamera = async (deviceId: string) => {
    selectedDevices.value.camera = deviceId
    
    try {
      const newStream = await navigator.mediaDevices.getUserMedia({
        video: { deviceId: { exact: deviceId } }
      })
      
      const newVideoTrack = newStream.getVideoTracks()[0]
      
      if (localStream.value && newVideoTrack) {
        // Replace video track in peer connections
        const sender = Array.from(peerConnections.value.values()).map(pc => 
          pc.getSenders().find(s => s.track?.kind === 'video')
        ).filter(Boolean)
        
        await Promise.all(
          sender.map(s => s!.replaceTrack(newVideoTrack))
        )
        
        // Replace in local stream
        const oldVideoTrack = localStream.value.getVideoTracks()[0]
        if (oldVideoTrack) {
          localStream.value.removeTrack(oldVideoTrack)
          oldVideoTrack.stop()
        }
        
        localStream.value.addTrack(newVideoTrack)
      }
    } catch (error) {
      console.error('Error changing camera:', error)
    }
  }

  const changeMicrophone = async (deviceId: string) => {
    selectedDevices.value.microphone = deviceId
    
    try {
      const newStream = await navigator.mediaDevices.getUserMedia({
        audio: { deviceId: { exact: deviceId } }
      })
      
      const newAudioTrack = newStream.getAudioTracks()[0]
      
      if (localStream.value && newAudioTrack) {
        // Replace audio track in peer connections
        const sender = Array.from(peerConnections.value.values()).map(pc => 
          pc.getSenders().find(s => s.track?.kind === 'audio')
        ).filter(Boolean)
        
        await Promise.all(
          sender.map(s => s!.replaceTrack(newAudioTrack))
        )
        
        // Replace in local stream
        const oldAudioTrack = localStream.value.getAudioTracks()[0]
        if (oldAudioTrack) {
          localStream.value.removeTrack(oldAudioTrack)
          oldAudioTrack.stop()
        }
        
        localStream.value.addTrack(newAudioTrack)
      }
    } catch (error) {
      console.error('Error changing microphone:', error)
    }
  }

  // Cleanup
  const cleanup = () => {
    // Stop local stream
    if (localStream.value) {
      localStream.value.getTracks().forEach(track => track.stop())
      localStream.value = null
    }

    // Close all peer connections
    peerConnections.value.forEach(pc => pc.close())
    peerConnections.value.clear()

    // Clear participants
    participants.value.clear()

    // Reset state
    roomId.value = null
    mediaState.value = {
      isAudioEnabled: true,
      isVideoEnabled: true,
      isScreenSharing: false
    }
  }

  // Disconnect socket
  const disconnect = () => {
    if (socket.value) {
      socket.value.disconnect()
      socket.value = null
      isConnected.value = false
    }
    cleanup()
  }

  // Cleanup on unmount
  onUnmounted(() => {
    disconnect()
  })

  return {
    // State
    socket: readonly(socket),
    localStream: readonly(localStream),
    participants: readonly(participants),
    isConnected: readonly(isConnected),
    mediaState: readonly(mediaState),
    availableDevices: readonly(availableDevices),
    selectedDevices: readonly(selectedDevices),
    roomId: readonly(roomId),

    // Methods
    initSocket,
    getAvailableDevices,
    getUserMedia,
    joinRoom,
    leaveRoom,
    toggleAudio,
    toggleVideo,
    toggleScreenShare,
    changeCamera,
    changeMicrophone,
    disconnect,
    cleanup
  }
}
