import { defineStore } from 'pinia'

interface Room {
  id: string
  title: string
  description: string
  created_by: number
  creator_username: string
  creator_name: string
  max_participants: number
  participant_count: number
  is_active: boolean
  created_at: string
  participants?: Participant[]
}

interface Participant {
  id: number
  room_id: string
  user_id: number
  username: string
  full_name: string
  avatar_url?: string
  joined_at: string
  is_active: boolean
}

interface RoomState {
  rooms: Room[]
  currentRoom: Room | null
  isLoading: boolean
  error: string | null
}

export const useRoomStore = defineStore('room', {
  state: (): RoomState => ({
    rooms: [],
    currentRoom: null,
    isLoading: false,
    error: null
  }),

  getters: {
    getRooms: (state) => state.rooms,
    getCurrentRoom: (state) => state.currentRoom,
    getParticipantCount: (state) => state.currentRoom?.participants?.length || 0
  },

  actions: {
    async fetchRooms() {
      this.isLoading = true
      this.error = null
      
      try {
        const { $api } = useNuxtApp()
        const response = await $api.get('/rooms')
        
        if (response.data.success) {
          this.rooms = response.data.data.rooms
        }
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch rooms'
        console.error('Error fetching rooms:', error)
      } finally {
        this.isLoading = false
      }
    },

    async createRoom(roomData: {
      title: string
      description: string
      maxParticipants?: number
    }) {
      this.isLoading = true
      this.error = null
      
      try {
        const { $api } = useNuxtApp()
        const response = await $api.post('/rooms', roomData)
        
        if (response.data.success) {
          await this.fetchRooms() // Refresh rooms list
          return { success: true, roomId: response.data.data.roomId }
        }
        
        return { success: false, message: response.data.message }
      } catch (error: any) {
        const message = error.response?.data?.message || 'Failed to create room'
        this.error = message
        return { success: false, message }
      } finally {
        this.isLoading = false
      }
    },

    async deleteRoom(roomId: string) {
      this.isLoading = true
      this.error = null
      
      try {
        const { $api } = useNuxtApp()
        const response = await $api.delete(`/rooms/${roomId}`)
        
        if (response.data.success) {
          // Remove room from local state
          this.rooms = this.rooms.filter(room => room.id !== roomId)
          
          // Clear current room if it was deleted
          if (this.currentRoom?.id === roomId) {
            this.currentRoom = null
          }
          
          return { success: true }
        }
        
        return { success: false, message: response.data.message }
      } catch (error: any) {
        const message = error.response?.data?.message || 'Failed to delete room'
        this.error = message
        return { success: false, message }
      } finally {
        this.isLoading = false
      }
    },

    async fetchRoom(roomId: string) {
      this.isLoading = true
      this.error = null
      
      try {
        const { $api } = useNuxtApp()
        const response = await $api.get(`/rooms/${roomId}`)
        
        if (response.data.success) {
          this.currentRoom = response.data.data.room
          return { success: true, room: response.data.data.room }
        }
        
        return { success: false, message: response.data.message }
      } catch (error: any) {
        const message = error.response?.data?.message || 'Room not found'
        this.error = message
        return { success: false, message }
      } finally {
        this.isLoading = false
      }
    },

    async joinRoom(roomId: string) {
      try {
        const { $api } = useNuxtApp()
        const response = await $api.post(`/rooms/${roomId}/join`)
        
        if (response.data.success) {
          this.currentRoom = response.data.data.room
          return { success: true }
        }
        
        return { success: false, message: response.data.message }
      } catch (error: any) {
        const message = error.response?.data?.message || 'Failed to join room'
        return { success: false, message }
      }
    },

    async leaveRoom(roomId: string) {
      try {
        const { $api } = useNuxtApp()
        const response = await $api.post(`/rooms/${roomId}/leave`)
        
        if (response.data.success) {
          this.currentRoom = null
          return { success: true }
        }
        
        return { success: false, message: response.data.message }
      } catch (error: any) {
        const message = error.response?.data?.message || 'Failed to leave room'
        return { success: false, message }
      }
    },

    clearCurrentRoom() {
      this.currentRoom = null
    },

    updateParticipants(participants: Participant[]) {
      if (this.currentRoom) {
        this.currentRoom.participants = participants
      }
    },

    addParticipant(participant: Participant) {
      if (this.currentRoom && this.currentRoom.participants) {
        const exists = this.currentRoom.participants.find(p => p.user_id === participant.user_id)
        if (!exists) {
          this.currentRoom.participants.push(participant)
        }
      }
    },

    removeParticipant(userId: number) {
      if (this.currentRoom && this.currentRoom.participants) {
        this.currentRoom.participants = this.currentRoom.participants.filter(
          p => p.user_id !== userId
        )
      }
    },

    async getRoomById(roomId: string) {
      try {
        const { $api } = useNuxtApp()
        const response = await $api.get(`/rooms/${roomId}`)
        
        if (response.data.success) {
          return response.data.data.room
        }
        
        return null
      } catch (error: any) {
        console.error('Error getting room:', error)
        return null
      }
    }
  }
})
