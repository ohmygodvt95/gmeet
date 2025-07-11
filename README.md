# GMeeting – Google Meet Clone with SFU Architecture

A video conferencing application similar to Google Meet, built with an SFU (Selective Forwarding Unit) architecture for optimized bandwidth and performance.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   SFU Server    │
│   (Nuxt.js)     │◄──►│   (Node.js)     │◄──►│  (MediaSoup)    │
│                 │    │                 │    │                 │
│- Authentication │    │- User Management│    │- Media Routing  │
│- Room Management│    │- Room Management│    │- WebRTC Handling│
│- UI/UX          │    │- Socket.IO      │    │- Bandwidth Opt. │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                   ┌─────────────────┐
                   │     Database    │
                   │  MySQL + Redis  │
                   │                 │
                   │  - User Data    │
                   │  - Room Data    │
                   │  - Sessions     │
                   └─────────────────┘
```

## 🌟 Features

* ✅ **User Registration/Login**
* ✅ **Create/Delete Meeting Rooms** with custom titles
* ✅ **Join Rooms** via shared links
* ✅ **High-Quality Video Calls** with SFU architecture
* ✅ **Audio/Video Controls** (mute/unmute mic and camera)
* ✅ **Screen Sharing**
* ✅ **Device Selection** (camera, mic, speaker)
* ✅ **Real-Time Chat** within the room
* ✅ **Responsive Design** with a modern interface
* ✅ **Auto Cleanup** on disconnect/leave

## 🛠️ Tech Stack

### Frontend

* **Nuxt.js 3** – Vue.js Framework
* **TypeScript** – Type Safety
* **TailwindCSS** – Styling
* **Pinia** – State Management
* **Socket.IO Client** – Real-Time Communication
* **MediaSoup Client** – WebRTC Client
* **Vite** – Build Tool

### Backend

* **Node.js** – Runtime
* **Express.js** – Web Framework
* **Socket.IO** – Real-Time Server
* **MySQL** – Primary Database
* **Redis** – Session Store & Caching
* **JWT** – Authentication
* **Bcrypt** – Password Hashing

### SFU Server

* **MediaSoup** – SFU Implementation
* **Node.js** – Runtime
* **Socket.IO** – Signaling Server

### Infrastructure

* **Docker & Docker Compose** – Containerization
* **MySQL 8.0** – Database
* **Redis 7** – Cache & Sessions

## 🚀 Installation & Running

### Prerequisites

* **Node.js 18+** (recommended 20+)
* **Docker & Docker Compose**
* **Git**

### Quick Start (Development)

```bash
# 1. Clone repository
git clone <repository-url>
cd gmeeting

# 2. Install dependencies for all services
chmod +x install-deps.sh
./install-deps.sh

# 3. Start database (MySQL + Redis) via Docker
chmod +x start-db.sh
./start-db.sh

# 4. Launch development servers
chmod +x start-dev.sh
./start-dev.sh
```

### Development Mode (Manual) – Recommended

This method offers finer control and easier debugging.

#### 1. Prepare Environment

```bash
# Verify Node.js version
node --version  # Must be >= 18.0.0

# Install dependencies
./install-deps.sh
```

#### 2. Start Database

```bash
# Only run MySQL and Redis in Docker
./start-db.sh

# Check service status
./test-services.sh

# Stop database if needed
./stop-db.sh
```

#### 3. Run Dev Servers (3 separate terminals)

**Terminal 1 – Backend:**

```bash
cd backend
npm run dev
# Runs at: http://localhost:3001
```

**Terminal 2 – SFU Server:**

```bash
cd sfu-server
npm run dev
# Runs at: http://localhost:3002
```

**Terminal 3 – Frontend:**

```bash
cd frontend
npm run dev
# Runs at: http://localhost:3000
```

#### 4. Verify Services

```bash
# Check all services
./test-services.sh

# Or individually
curl http://localhost:3001/health  # Backend
curl http://localhost:3002/health  # SFU
curl http://localhost:3000         # Frontend
```

#### 5. Stop Development

```bash
# Stop all background services
./stop-dev.sh

# Or Ctrl+C in each terminal
```

### Supporting Scripts

| Script                  | Description                           |
| ----------------------- | ------------------------------------- |
| `./install-deps.sh`     | Install dependencies for all services |
| `./start-db.sh`         | Start MySQL + Redis via Docker        |
| `./stop-db.sh`          | Stop database containers              |
| `./start-dev.sh`        | Guide/launch development mode         |
| `./start-dev-manual.sh` | Detailed manual development script    |
| `./stop-dev.sh`         | Stop all development services         |
| `./test-services.sh`    | Check status of all services          |
| `./quick-start.sh`      | Quick start guide and automation      |

### Access URLs

* **Frontend**: [http://localhost:3000](http://localhost:3000)
* **Backend API**: [http://localhost:3001](http://localhost:3001)
* **SFU Server**: [http://localhost:3002](http://localhost:3002)
* **Database**: MySQL at localhost:3306, Redis at localhost:6379

## 📱 Usage

1. **Open the App**
   Visit [http://localhost:3000](http://localhost:3000)

2. **Sign Up**

   * Click **Sign Up**
   * Enter: username, email, password, full name
   * Click **Create Account**

3. **Create a Room**

   * After login, click **Create Room**
   * Enter a room title
   * Click **Create Room**

4. **Join a Room**

   * Copy/share the room link
   * Or click **Join** from the room list
   * Allow camera & mic access
   * Test devices before joining

5. **In-Room Controls**

   * **Mute/Unmute Mic**: Click mic icon
   * **Turn On/Off Camera**: Click camera icon
   * **Screen Share**: Click screen-share icon
   * **Chat**: Use the chat panel on the right
   * **Leave**: Click **Leave** or close the tab

## 🎯 SFU Architecture & Bandwidth Optimization

### Why SFU?

* **Mesh Network (P2P)**

  * Every peer connects to all others
  * Bandwidth grows O(n²) with n participants
  * Not scalable beyond \~4–5 users

* **MCU (Multipoint Control Unit)**

  * Server mixes all streams into one
  * Stable bandwidth but high server CPU
  * Quality loss due to re-encoding

* **SFU (Selective Forwarding Unit)**

  * Server forwards streams without decoding
  * Linear bandwidth O(n)
  * High quality, efficient CPU usage
  * ✅ **Optimal choice for GMeeting**

### MediaSoup Bandwidth Techniques

1. **Simulcast**: Clients send multiple quality layers
2. **Adaptive Bitrate**: Automatic quality adjustment
3. **SVC (Scalable Video Coding)**: Layered resolution/FPS
4. **Bandwidth Estimation**: Monitor network conditions

## 🔧 API Documentation

### Authentication APIs

```
POST /api/auth/register     # Register
POST /api/auth/login        # Login
GET  /api/auth/profile      # Get user profile
```

### Room Management APIs

```
GET    /api/rooms           # List rooms
POST   /api/rooms           # Create a room
GET    /api/rooms/:id       # Get room details
PUT    /api/rooms/:id       # Update room
DELETE /api/rooms/:id       # Delete room
POST   /api/rooms/:id/join  # Join room
POST   /api/rooms/:id/leave # Leave room
```

### SFU Server APIs

```
GET /health                 # Health check
GET /stats                  # Server statistics
GET /rooms/:id/stats        # Room statistics
```

## 🔌 Socket Events

### Backend Socket Events

```javascript
// Client → Server
'join-room'         # Join room
'leave-room'        # Leave room
'chat-message'      # Send chat

// Server → Client
'room-joined'       # Joined room
'user-joined'       # Other user joined
'user-left'         # Other user left
'chat-message'      # New message
'room-deleted'      # Room deleted
```

### SFU Socket Events

```javascript
// Client → Server
'join-room'                  # Join SFU room
'get-router-rtp-capabilities'# Get RTP capabilities
'create-webrtc-transport'    # Create transport
'connect-transport'          # Connect transport
'produce'                    # Produce media
'consume'                    # Consume media

// Server → Client
'router-rtp-capabilities'    # RTP capabilities
'webrtc-transport-created'   # Transport created
'new-producer'               # New producer
'producer-closed'            # Producer closed
```

## 🐛 Troubleshooting

### 1. Database Connection Failed

```bash
# Check database containers
./test-services.sh

# Inspect MySQL logs
docker ps | grep mysql
docker logs gmeeting_mysql

# Inspect Redis logs
docker ps | grep redis
docker logs gmeeting_redis

# Reset database if needed
./stop-db.sh
docker volume rm gmeeting_mysql_data gmeeting_redis_data
./start-db.sh
```

### 2. Port Already in Use

```bash
# Find processes on ports
sudo lsof -i :3000  # Frontend
sudo lsof -i :3001  # Backend
sudo lsof -i :3002  # SFU
sudo lsof -i :3306  # MySQL
sudo lsof -i :6379  # Redis

# Kill process
sudo kill -9 <PID>

# Or use stop script
./stop-dev.sh
```

### 3. Node.js Version Issues

```bash
# Check versions
node --version
npm --version

# Install Node.js 20+ if needed
# Ubuntu/Debian:
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# macOS:
brew install node@20
```

### 4. Dependency Installation Failed

```bash
# Clear and reinstall
rm -rf backend/node_modules frontend/node_modules sfu-server/node_modules
rm -f **/package-lock.json
./install-deps.sh
```

### 5. MediaSoup Installation Failed

```bash
# Ensure Python and build tools
# Ubuntu/Debian:
sudo apt-get update
sudo apt-get install -y python3 python3-pip build-essential

# macOS:
brew install python@3.11
xcode-select --install

# Reinstall MediaSoup
cd sfu-server
npm install mediasoup --force
```

### 6. Script Permission Denied

```bash
# Make scripts executable
chmod +x *.sh

# Or run with bash
bash start-db.sh
bash start-dev.sh
```

### 7. Docker Issues

```bash
# Check Docker service
sudo systemctl status docker

# Start Docker
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker $USER
# Logout and log back in
```

### 8. Frontend Build Issues

```bash
# Clear Nuxt cache
cd frontend
rm -rf .nuxt .output dist
npm run dev
```

### 9. Environment Variables

```bash
# Verify .env exists
ls -la .env

# Copy from template if missing
cp .env.example .env

# Validate variables
./test-services.sh
```

### 10. Network/CORS Issues

```bash
# Check CORS in .env
grep CORS .env

# Test endpoints
curl -v http://localhost:3001/health
curl -v http://localhost:3002/health

# Ensure frontend can connect (use DevTools Network tab)
```

## 📊 Monitoring & Logs

### Log Levels

* **Backend**: `info`, `warn`, `error`
* **SFU**: `warn`, `error`, `info`, `ice`, `dtls`, `rtp`

### Monitoring Endpoints

```bash
# Backend health
curl http://localhost:3001/health

# SFU health
curl http://localhost:3002/health

# SFU statistics
curl http://localhost:3002/stats

# Room statistics
curl http://localhost:3002/rooms/{roomId}/stats
```

## 🔒 Security

### Authentication

* JWT tokens with expiration
* Bcrypt password hashing
* Rate limiting on APIs

### WebRTC Security

* DTLS encryption for media
* SRTP for audio/video streams
* ICE/STUN for NAT traversal

### Environment Security

* Sensitive data in `.env`
* Docker secrets for production
* Rotating database credentials

## 🚀 Production Deployment

### 1. Build Production Images

```bash
# Backend
docker build -t gmeeting-backend ./backend

# SFU server
docker build -t gmeeting-sfu ./sfu-server

# Frontend
cd frontend && npm run build
```

### 2. Environment Setup

```bash
NODE_ENV=production
ANNOUNCED_IP=<your-public-ip>
FRONTEND_URL=https://your-domain.com
BACKEND_URL=https://api.your-domain.com
```

### 3. SSL/TLS Setup

* MediaSoup requires HTTPS in production
* Use Let’s Encrypt or CloudFlare
* Configure reverse proxy (Nginx/Caddy)

### 4. Scaling Considerations

* Load balancer for multiple SFU instances
* Redis Cluster for session scaling
* Database replication
* CDN for static assets

## 📝 Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m "Add amazing feature"`
4. Push branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📄 License

MIT License – see [LICENSE](LICENSE) for details.

## 🙋‍♂️ Support

If you need help:

1. Check **Troubleshooting** above
2. Open an **Issue** on GitHub
3. Contact the team via email

