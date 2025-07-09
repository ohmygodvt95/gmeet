import { io, Socket } from 'socket.io-client'
import { Device } from 'mediasoup-client'
import { ref, onUnmounted } from 'vue'

interface SFUParticipant {
  peerId: string
  userId: number
  username: string
  audioProducerId?: string
  videoProducerId?: string
  audioConsumer?: any
  videoConsumer?: any
  audioEnabled: boolean
  videoEnabled: boolean
  isScreenSharing: boolean
}

export const useSFU = () => {
  const sfuSocket = ref<Socket | null>(null)
  const device = ref<Device | null>(null)
  const isConnected = ref(false)
  const isJoined = ref(false)
  const roomId = ref<string | null>(null)
  
  const localStream = ref<MediaStream | null>(null)
  const participants = ref<Map<string, SFUParticipant>>(new Map())
  
  const sendTransport = ref<any>(null)
  const recvTransport = ref<any>(null)
  const producers = ref<Map<string, any>>(new Map()) // kind -> producer
  const consumers = ref<Map<string, any>>(new Map()) // consumerId -> consumer
  
  const mediaState = ref({
    isAudioEnabled: true,
    isVideoEnabled: true,
    isScreenSharing: false
  })

  const availableDevices = ref({
    camera: [] as MediaDeviceInfo[],
    microphone: [] as MediaDeviceInfo[],
    speaker: [] as MediaDeviceInfo[]
  })

  const selectedDevices = ref({
    camera: '',
    microphone: '',
    speaker: ''
  })

  // Initialize SFU connection
  const initSFU = async (token: string) => {
    try {
      const config = useRuntimeConfig()
      
      // Connect to SFU server
      sfuSocket.value = io(config.public.sfuUrl, {
        auth: { token }
      })

      // Create MediaSoup device
      device.value = new Device()

      setupSFUEventListeners()

      console.log('🎬 SFU initialization started')
    } catch (error) {
      console.error('❌ Failed to initialize SFU:', error)
      throw error
    }
  }

  // Setup SFU socket event listeners
  const setupSFUEventListeners = () => {
    if (!sfuSocket.value) return

    sfuSocket.value.on('connect', () => {
      isConnected.value = true
      console.log('✅ Connected to SFU server')
    })

    sfuSocket.value.on('disconnect', () => {
      isConnected.value = false
      isJoined.value = false
      console.log('❌ Disconnected from SFU server')
    })

    sfuSocket.value.on('joined-room', handleJoinedRoom)
    sfuSocket.value.on('peer-joined', handlePeerJoined)
    sfuSocket.value.on('peer-left', handlePeerLeft)
    sfuSocket.value.on('router-rtp-capabilities', handleRouterRtpCapabilities)
    sfuSocket.value.on('webrtc-transport-created', handleWebRtcTransportCreated)
    sfuSocket.value.on('transport-connected', handleTransportConnected)
    sfuSocket.value.on('produced', handleProduced)
    sfuSocket.value.on('consumed', handleConsumed)
    sfuSocket.value.on('new-producer', handleNewProducer)
    sfuSocket.value.on('producer-closed', handleProducerClosed)
    sfuSocket.value.on('producers', handleProducers)
    sfuSocket.value.on('error', handleSFUError)
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
          deviceId: selectedDevices.value.microphone ? { exact: selectedDevices.value.microphone } : undefined,
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true
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

  // Join SFU room
  const joinSFURoom = async (roomIdParam: string) => {
    if (!sfuSocket.value || !device.value) {
      throw new Error('SFU not initialized')
    }

    roomId.value = roomIdParam

    // Get user media
    await getUserMedia()

    // Join room
    sfuSocket.value.emit('join-room', { roomId: roomIdParam })

    // Get router RTP capabilities
    sfuSocket.value.emit('get-router-rtp-capabilities', { roomId: roomIdParam })
    
    // Start the media check interval for auto-retry
    startMediaCheckInterval()
  }

  // Leave SFU room
  const leaveSFURoom = () => {
    if (sfuSocket.value) {
      sfuSocket.value.emit('leave-room')
    }

    // Stop the media check interval
    stopMediaCheckInterval()
    
    cleanupSFU()
  }

  // Create send transport
  const createSendTransport = () => {
    if (!sfuSocket.value) return

    sfuSocket.value.emit('create-webrtc-transport', { direction: 'send' })
  }

  // Create receive transport
  const createRecvTransport = () => {
    if (!sfuSocket.value) return

    sfuSocket.value.emit('create-webrtc-transport', { direction: 'recv' })
  }

  // Produce audio/video
  const produce = async (kind: 'audio' | 'video') => {
    try {
      // Debug check
      const readiness = checkProduceReadiness(kind)
      if (!readiness.localStream || !readiness.sendTransport) {
        console.error(`Cannot produce ${kind}: missing localStream or sendTransport`)
        return
      }

      if (!readiness.transportConnected) {
        console.error(`Cannot produce ${kind}: transport not connected (state: ${sendTransport.value?.connectionState})`)
        return
      }

      if (!readiness.deviceLoaded) {
        console.error(`Cannot produce ${kind}: device not loaded`)
        return
      }

      if (!readiness.canProduce) {
        console.error(`Cannot produce ${kind}: device cannot produce ${kind}`)
        console.log('Device RTP capabilities:', device.value?.rtpCapabilities)
        return
      }

      if (!readiness.hasTrack) {
        console.error(`Cannot produce ${kind}: no ${kind} track available`)
        return
      }

      if (!readiness.trackLive) {
        console.error(`Cannot produce ${kind}: track is not live`)
        return
      }

      // Check if device can produce this kind of media
      if (!device.value?.canProduce(kind)) {
        console.error(`Cannot produce ${kind}: device does not support ${kind} production`)
        console.log('Device RTP capabilities:', device.value?.rtpCapabilities)
        return
      }

      const track = kind === 'audio' 
        ? localStream.value!.getAudioTracks()[0]
        : localStream.value!.getVideoTracks()[0]

      console.log(`🎬 Starting to produce ${kind}, track:`, {
        id: track.id,
        kind: track.kind,
        enabled: track.enabled,
        readyState: track.readyState,
        muted: track.muted
      })

      const producer = await sendTransport.value!.produce({
        track,
        encodings: kind === 'video' ? [
          { maxBitrate: 100000 },
          { maxBitrate: 300000 },
          { maxBitrate: 900000 }
        ] : undefined,
        codecOptions: kind === 'video' ? {
          videoGoogleStartBitrate: 1000
        } : undefined
      })

      producers.value.set(kind, producer)

      producer.on('trackended', () => {
        console.log(`${kind} track ended`)
      })

      producer.on('transportclose', () => {
        console.log(`${kind} producer transport closed`)
      })

      console.log(`📡 ${kind} producer created:`, producer.id)

    } catch (error) {
      console.error(`Error producing ${kind}:`, error)
      // Log more detailed error information
      if (error instanceof Error && error.name === 'UnsupportedError') {
        console.error('UnsupportedError details:', {
          message: error.message,
          localStream: !!localStream.value,
          sendTransport: !!sendTransport.value,
          transportState: sendTransport.value?.connectionState,
          device: !!device.value,
          deviceLoaded: device.value?.loaded
        })
      }
    }
  }

  // Retry produce with exponential backoff
  const retryProduce = async (kind: 'audio' | 'video', maxRetries = 3) => {
    let retries = 0;
    let lastError = null;
    
    while (retries < maxRetries) {
      try {
        // Check readiness before attempting
        const readiness = checkProduceReadiness(kind);
        console.log(`🔄 Retry ${retries + 1}/${maxRetries} for ${kind} production, readiness:`, readiness);
        
        if (!readiness.transportConnected || !readiness.canProduce || !readiness.hasTrack) {
          console.error(`Cannot retry produce ${kind}: prerequisites not met`);
          await new Promise(resolve => setTimeout(resolve, 1000 * (retries + 1))); // Wait longer between retries
          retries++;
          continue;
        }
        
        // Try to produce
        await produce(kind);
        return true; // Success
      } catch (error) {
        lastError = error;
        console.error(`Retry ${retries + 1}/${maxRetries} failed for ${kind}:`, error);
        await new Promise(resolve => setTimeout(resolve, 1000 * (retries + 1))); // Wait longer between retries
        retries++;
      }
    }
    
    console.error(`Failed to produce ${kind} after ${maxRetries} retries. Last error:`, lastError);
    return false;
  }

  // Debug function to check if we can produce
  const checkProduceReadiness = (kind: 'audio' | 'video') => {
    const checks = {
      localStream: !!localStream.value,
      sendTransport: !!sendTransport.value,
      transportConnected: sendTransport.value?.connectionState === 'connected',
      device: !!device.value,
      deviceLoaded: device.value?.loaded,
      canProduce: device.value?.canProduce(kind),
      hasTrack: false,
      trackLive: false
    }

    if (localStream.value) {
      const track = kind === 'audio' 
        ? localStream.value.getAudioTracks()[0]
        : localStream.value.getVideoTracks()[0]
      
      checks.hasTrack = !!track
      checks.trackLive = track?.readyState === 'live'
    }

    console.log(`🔍 Produce readiness check for ${kind}:`, checks)
    return checks
  }

  // Consume media from other peers
  const consume = async (producerId: string) => {
    try {
      if (!device.value || !recvTransport.value) return

      sfuSocket.value?.emit('consume', {
        producerId,
        rtpCapabilities: device.value.rtpCapabilities
      })

    } catch (error) {
      console.error('Error consuming:', error)
    }
  }

  // Toggle audio
  const toggleAudio = async () => {
    if (!localStream.value) return

    const audioTrack = localStream.value.getAudioTracks()[0]
    if (!audioTrack) return

    audioTrack.enabled = !audioTrack.enabled
    mediaState.value.isAudioEnabled = audioTrack.enabled

    // Update producer if exists
    const audioProducer = producers.value.get('audio')
    if (audioProducer) {
      if (audioTrack.enabled) {
        await audioProducer.resume()
      } else {
        await audioProducer.pause()
      }
    }
  }

  // Toggle video
  const toggleVideo = async () => {
    if (!localStream.value) return

    const videoTrack = localStream.value.getVideoTracks()[0]
    if (!videoTrack) return

    videoTrack.enabled = !videoTrack.enabled
    mediaState.value.isVideoEnabled = videoTrack.enabled

    // Update producer if exists
    const videoProducer = producers.value.get('video')
    if (videoProducer) {
      if (videoTrack.enabled) {
        await videoProducer.resume()
      } else {
        await videoProducer.pause()
      }
    }
  }

  // Toggle screen share
  const toggleScreenShare = async () => {
    try {
      if (!mediaState.value.isScreenSharing) {
        // Start screen sharing
        const screenStream = await navigator.mediaDevices.getDisplayMedia({
          video: true,
          audio: true
        })

        const videoTrack = screenStream.getVideoTracks()[0]
        if (videoTrack && sendTransport.value) {
          // Replace video track
          const videoProducer = producers.value.get('video')
          if (videoProducer) {
            await videoProducer.replaceTrack({ track: videoTrack })
          }

          // Update local stream
          if (localStream.value) {
            const oldVideoTrack = localStream.value.getVideoTracks()[0]
            if (oldVideoTrack) {
              localStream.value.removeTrack(oldVideoTrack)
              oldVideoTrack.stop()
            }
            localStream.value.addTrack(videoTrack)
          }

          mediaState.value.isScreenSharing = true

          // Handle screen share end
          videoTrack.onended = () => {
            stopScreenShare()
          }
        }
      } else {
        await stopScreenShare()
      }
    } catch (error) {
      console.error('Error toggling screen share:', error)
    }
  }

  // Stop screen share
  const stopScreenShare = async () => {
    try {
      // Get camera stream back
      const cameraStream = await navigator.mediaDevices.getUserMedia({
        video: {
          deviceId: selectedDevices.value.camera ? { exact: selectedDevices.value.camera } : undefined
        }
      })

      const videoTrack = cameraStream.getVideoTracks()[0]
      if (videoTrack && sendTransport.value) {
        // Replace video track
        const videoProducer = producers.value.get('video')
        if (videoProducer) {
          await videoProducer.replaceTrack({ track: videoTrack })
        }

        // Update local stream
        if (localStream.value) {
          const oldVideoTrack = localStream.value.getVideoTracks()[0]
          if (oldVideoTrack) {
            localStream.value.removeTrack(oldVideoTrack)
            oldVideoTrack.stop()
          }
          localStream.value.addTrack(videoTrack)
        }

        mediaState.value.isScreenSharing = false
      }
    } catch (error) {
      console.error('Error stopping screen share:', error)
    }
  }

  // Event handlers
  const handleJoinedRoom = (data: any) => {
    isJoined.value = true
    console.log('✅ Joined SFU room:', data.roomId)
  }

  const handlePeerJoined = (data: any) => {
    console.log('👤 Peer joined:', data)
    
    participants.value.set(data.peerId, {
      peerId: data.peerId,
      userId: data.userId || 0,
      username: data.username,
      audioEnabled: true,
      videoEnabled: true,
      isScreenSharing: false
    })
  }

  const handlePeerLeft = (data: any) => {
    console.log('👋 Peer left:', data)
    participants.value.delete(data.peerId)
  }

  const handleRouterRtpCapabilities = async (data: any) => {
    try {
      if (!device.value) return

      await device.value.load({ routerRtpCapabilities: data.rtpCapabilities })
      console.log('📱 Device loaded with RTP capabilities')

      // Create transports
      createSendTransport()
      createRecvTransport()

    } catch (error) {
      console.error('Error loading device:', error)
    }
  }

  const handleWebRtcTransportCreated = async (data: any) => {
    try {
      if (!device.value) return

      const { direction, id, iceParameters, iceCandidates, dtlsParameters } = data

      if (direction === 'send') {
        sendTransport.value = device.value.createSendTransport({
          id,
          iceParameters,
          iceCandidates,
          dtlsParameters
        })

        sendTransport.value.on('connect', async ({ dtlsParameters }: any, callback: any, errback: any) => {
          try {
            console.log('🔗 Send transport connecting...')
            sfuSocket.value?.emit('connect-transport', {
              transportId: id,
              dtlsParameters
            })
            
            // Just call the callback but don't try to produce here
            // We'll wait for the 'transport-connected' event from the server
            callback()
            console.log('🔗 Send transport connect callback called, waiting for transport-connected event')
            
          } catch (error) {
            console.error('❌ Error connecting send transport:', error)
            errback(error)
          }
        })

        sendTransport.value.on('produce', async (parameters: any, callback: any, errback: any) => {
          try {
            console.log(`🎯 Transport produce event triggered for ${parameters.kind}`, {
              transportId: id,
              connectionState: sendTransport.value.connectionState
            })

            sfuSocket.value?.emit('produce', {
              transportId: id,
              kind: parameters.kind,
              rtpParameters: parameters.rtpParameters,
              appData: parameters.appData
            })

            console.log(`🎯 Produce ${parameters.kind} request sent to server`)

            // Callback will be handled in 'produced' event
            sendTransport.value._produceCallback = callback
            
            // Store callback for debugging
            sendTransport.value._lastProduceInfo = {
              kind: parameters.kind,
              time: new Date().toISOString()
            }
          } catch (error) {
            console.error(`❌ Error in produce event handler for ${parameters.kind}:`, error)
            errback(error)
          }
        })

        console.log('📤 Send transport created')

      } else {
        recvTransport.value = device.value.createRecvTransport({
          id,
          iceParameters,
          iceCandidates,
          dtlsParameters
        })

        recvTransport.value.on('connect', async ({ dtlsParameters }: any, callback: any, errback: any) => {
          try {
            sfuSocket.value?.emit('connect-transport', {
              transportId: id,
              dtlsParameters
            })
            callback()
          } catch (error) {
            errback(error)
          }
        })

        console.log('📥 Recv transport created')

        // Get existing producers
        sfuSocket.value?.emit('get-producers')
      }

    } catch (error) {
      console.error('Error creating transport:', error)
    }
  }

  const handleTransportConnected = (data: any) => {
    console.log('🔗 Transport connected:', data.transportId)
    
    // If this is our send transport that got connected, start producing
    if (sendTransport.value && sendTransport.value.id === data.transportId) {
      console.log('🔗 Send transport connected via socket event, starting media production')
      
      // Start producing with a small delay to ensure everything is ready
      setTimeout(async () => {
        if (localStream.value) {
          // Check transport state directly before trying to produce
          console.log('🎬 Send transport state before producing:', sendTransport.value?.connectionState)
          
          // Use retry logic instead of simple produce
          console.log('🎤 Starting audio production with retry logic')
          const audioSuccess = await retryProduce('audio')
          
          if (audioSuccess) {
            console.log('🎤 Audio production successful, now starting video')
            await retryProduce('video')
          } else {
            console.error('� Failed to produce audio, trying video anyway')
            await retryProduce('video')
          }
        }
      }, 800) // Longer delay to ensure everything is ready
    }
  }

  const handleProduced = (data: any) => {
    console.log('📡 Server confirmed production:', data)
    
    // Get the kind of media that was produced
    const kind = sendTransport.value?._lastProduceInfo?.kind || 'unknown'
    const timeTaken = sendTransport.value?._lastProduceInfo 
      ? new Date().getTime() - new Date(sendTransport.value._lastProduceInfo.time).getTime() 
      : 'unknown'
    
    if (sendTransport.value?._produceCallback) {
      console.log(`📡 Calling produce callback for ${kind} (took ${timeTaken}ms)`)
      sendTransport.value._produceCallback({ id: data.id })
      delete sendTransport.value._produceCallback
      delete sendTransport.value._lastProduceInfo
    } else {
      console.warn('📡 Received produced event but no callback was registered')
    }
    
    console.log(`📡 ${kind} producer is now active with ID: ${data.id}`)
  }

  const handleConsumed = async (data: any) => {
    try {
      if (!recvTransport.value) return

      const consumer = await recvTransport.value.consume({
        id: data.id,
        producerId: data.producerId,
        kind: data.kind,
        rtpParameters: data.rtpParameters
      })

      consumers.value.set(data.id, consumer)

      // Resume consumer
      sfuSocket.value?.emit('resume-consumer', { consumerId: data.id })

      console.log('🍽️ Consumed:', data)

    } catch (error) {
      console.error('Error handling consumed:', error)
    }
  }

  const handleNewProducer = async (data: any) => {
    console.log('🆕 New producer:', data)
    await consume(data.producerId)
  }

  const handleProducerClosed = (data: any) => {
    console.log('🚫 Producer closed:', data)
    
    // Find and close related consumers
    consumers.value.forEach((consumer, consumerId) => {
      if (consumer.producerId === data.producerId) {
        consumer.close()
        consumers.value.delete(consumerId)
      }
    })
  }

  const handleProducers = async (data: any) => {
    console.log('📋 Available producers:', data.producers)
    
    // Consume all available producers
    for (const producer of data.producers) {
      await consume(producer.id)
    }

    // Note: We don't produce here anymore, we wait for send transport to connect
    console.log('📋 Waiting for send transport to connect before producing...')
  }

  const handleSFUError = (data: any) => {
    console.error('🚨 SFU Error:', data.message)
  }

  // Fix for "no media appears in room" issue
  const checkAndRetryMediaProduction = async () => {
    console.log('🔍 Checking if media is properly produced...');
    
    // Check if we have any active producers
    const hasAudioProducer = producers.value.has('audio');
    const hasVideoProducer = producers.value.has('video');
    
    console.log(`🔍 Active producers: audio=${hasAudioProducer}, video=${hasVideoProducer}`);
    
    if (!localStream.value) {
      console.log('🔍 No local stream available');
      return;
    }
    
    // If we don't have producers but should have them, retry
    if (!hasAudioProducer && localStream.value.getAudioTracks().length > 0) {
      console.log('🔄 No audio producer found but audio track exists, retrying...');
      await retryProduce('audio');
    }
    
    if (!hasVideoProducer && localStream.value.getVideoTracks().length > 0) {
      console.log('🔄 No video producer found but video track exists, retrying...');
      await retryProduce('video');
    }
  }

  // Auto-check interval
  let mediaCheckInterval: ReturnType<typeof setInterval> | null = null;

  // Start auto-check for media production
  const startMediaCheckInterval = () => {
    if (mediaCheckInterval) clearInterval(mediaCheckInterval);
    
    // Check every 5 seconds if we have active producers
    mediaCheckInterval = setInterval(async () => {
      if (isJoined.value && sendTransport.value?.connectionState === 'connected') {
        await checkAndRetryMediaProduction();
      }
    }, 5000);
    
    console.log('🔄 Started auto-check for media production');
  };

  // Stop auto-check
  const stopMediaCheckInterval = () => {
    if (mediaCheckInterval) {
      clearInterval(mediaCheckInterval);
      mediaCheckInterval = null;
      console.log('🛑 Stopped auto-check for media production');
    }
  };
  
  // Cleanup
  const cleanupSFU = () => {
    // Stop media check interval if running
    stopMediaCheckInterval()
    
    // Close producers
    producers.value.forEach(producer => {
      producer.close()
    })
    producers.value.clear()

    // Close consumers
    consumers.value.forEach(consumer => {
      consumer.close()
    })
    consumers.value.clear()

    // Close transports
    if (sendTransport.value) {
      sendTransport.value.close()
      sendTransport.value = null
    }
    if (recvTransport.value) {
      recvTransport.value.close()
      recvTransport.value = null
    }

    // Stop local stream
    if (localStream.value) {
      localStream.value.getTracks().forEach(track => track.stop())
      localStream.value = null
    }

    // Clear participants
    participants.value.clear()

    // Reset state
    isJoined.value = false
    roomId.value = null
    mediaState.value = {
      isAudioEnabled: true,
      isVideoEnabled: true,
      isScreenSharing: false
    }
  }

  // Disconnect SFU
  const disconnectSFU = () => {
    if (sfuSocket.value) {
      sfuSocket.value.disconnect()
      sfuSocket.value = null
      isConnected.value = false
    }
    cleanupSFU()
  }

  // Cleanup on unmount
  onUnmounted(() => {
    disconnectSFU()
  })

  return {
    // State
    sfuSocket: readonly(sfuSocket),
    device: readonly(device),
    isConnected: readonly(isConnected),
    isJoined: readonly(isJoined),
    localStream: readonly(localStream),
    participants: readonly(participants),
    mediaState: readonly(mediaState),
    availableDevices: readonly(availableDevices),
    selectedDevices: readonly(selectedDevices),
    roomId: readonly(roomId),
    producers: readonly(producers),
    consumers: readonly(consumers),

    // Methods
    initSFU,
    getAvailableDevices,
    getUserMedia,
    joinSFURoom,
    leaveSFURoom,
    toggleAudio,
    toggleVideo,
    toggleScreenShare,
    disconnectSFU,
    cleanupSFU,
    
    // Debug methods
    checkProduceReadiness,
    produce,
    retryProduce,
    checkAndRetryMediaProduction
  }
}
