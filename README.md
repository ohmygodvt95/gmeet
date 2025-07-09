# GMeeting - Google Meet Clone với SFU Architecture

Ứng dụng video conference tương tự Google Meet được xây dựng với kiến trúc SFU (Selective Forwarding Unit) để tối ưu băng thông và hiệu suất.

## 🏗️ Kiến trúc

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   SFU Server    │
│   (Nuxt.js)     │◄──►│   (Node.js)     │◄──►│  (MediaSoup)    │
│                 │    │                 │    │                 │
│  - Authentication   │    │  - User Management  │    │  - Media Routing    │
│  - Room Management  │    │  - Room Management  │    │  - WebRTC Handling  │
│  - UI/UX           │    │  - Socket.IO        │    │  - Bandwidth Opt.   │
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

## 🌟 Tính năng

- ✅ **Đăng ký/Đăng nhập** người dùng
- ✅ **Tạo/Xóa phòng họp** với tiêu đề tùy chỉnh
- ✅ **Tham gia phòng họp** qua link chia sẻ
- ✅ **Video call chất lượng cao** với SFU architecture
- ✅ **Audio/Video controls** (bật/tắt mic, camera)
- ✅ **Screen sharing** chia sẻ màn hình
- ✅ **Device selection** chọn camera, mic, loa
- ✅ **Chat realtime** trong phòng họp
- ✅ **Responsive design** giao diện đẹp, hiện đại
- ✅ **Auto cleanup** khi disconnect/leave room

## 🛠️ Tech Stack

### Frontend
- **Nuxt.js 3** - Vue.js framework
- **TypeScript** - Type safety
- **TailwindCSS** - Styling
- **Pinia** - State management
- **Socket.IO Client** - Realtime communication
- **MediaSoup Client** - WebRTC client
- **Vite** - Build tool

### Backend
- **Node.js** - Runtime
- **Express.js** - Web framework
- **Socket.IO** - Realtime server
- **MySQL** - Primary database
- **Redis** - Session store & caching
- **JWT** - Authentication
- **Bcrypt** - Password hashing

### SFU Server
- **MediaSoup** - SFU implementation
- **Node.js** - Runtime
- **Socket.IO** - Signaling server

### Infrastructure
- **Docker & Docker Compose** - Containerization
- **MySQL 8.0** - Database
- **Redis 7** - Cache & sessions

## 🚀 Cài đặt và Chạy

### Prerequisites
- **Node.js 18+** (khuyến nghị 20+)
- **Docker & Docker Compose**
- **Git**

### Quick Start (Development)

```bash
# 1. Clone repository
git clone <repository-url>
cd gmeeting

# 2. Cài đặt dependencies cho tất cả services
chmod +x install-deps.sh
./install-deps.sh

# 3. Khởi động database (MySQL + Redis) bằng Docker
chmod +x start-db.sh
./start-db.sh

# 4. Chạy development servers
chmod +x start-dev.sh
./start-dev.sh
```

### Development Mode (Manual) - Khuyến nghị

Phương pháp này cho phép kiểm soát tốt hơn và debug dễ dàng hơn.

#### 1. Chuẩn bị môi trường
```bash
# Kiểm tra Node.js version
node --version  # Cần >= 18.0.0

# Cài đặt dependencies
./install-deps.sh
```

#### 2. Khởi động Database
```bash
# Chỉ chạy MySQL và Redis trong Docker
./start-db.sh

# Kiểm tra trạng thái database
./test-services.sh

# Dừng database khi cần
./stop-db.sh
```

#### 3. Chạy Development Servers (3 terminals riêng biệt)

**Terminal 1 - Backend:**
```bash
cd backend
npm run dev
# Chạy tại: http://localhost:3001
```

**Terminal 2 - SFU Server:**
```bash
cd sfu-server  
npm run dev
# Chạy tại: http://localhost:3002
```

**Terminal 3 - Frontend:**
```bash
cd frontend
npm run dev
# Chạy tại: http://localhost:3000
```

#### 4. Kiểm tra services
```bash
# Kiểm tra tất cả services
./test-services.sh

# Hoặc kiểm tra từng service
curl http://localhost:3001/health  # Backend
curl http://localhost:3002/health  # SFU
curl http://localhost:3000         # Frontend
```

#### 5. Dừng development
```bash
# Dừng tất cả services chạy nền
./stop-dev.sh

# Hoặc Ctrl+C trong từng terminal
```

### Các Scripts Hỗ trợ

| Script | Mô tả |
|--------|-------|
| `./install-deps.sh` | Cài đặt dependencies cho tất cả services |
| `./start-db.sh` | Khởi động MySQL + Redis bằng Docker |
| `./stop-db.sh` | Dừng database containers |
| `./start-dev.sh` | Hướng dẫn/khởi chạy development mode |
| `./start-dev-manual.sh` | Script chi tiết cho development thủ công |
| `./stop-dev.sh` | Dừng tất cả services development |
| `./test-services.sh` | Kiểm tra trạng thái các services |
| `./quick-start.sh` | Quick start guide và automation |

### Access Application
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:3001
- **SFU Server**: http://localhost:3002
- **Database**: MySQL tại localhost:3306, Redis tại localhost:6379

## 📱 Sử dụng

### 1. Truy cập ứng dụng
Mở trình duyệt và truy cập: http://localhost:3000

### 2. Đăng ký tài khoản
- Click "Sign Up"
- Nhập thông tin: username, email, password, full name
- Click "Create Account"

### 3. Tạo phòng họp
- Sau khi đăng nhập, click "Create Room"
- Nhập tiêu đề phòng họp
- Click "Create Room"

### 4. Tham gia phòng họp
- Copy link phòng họp và chia sẻ
- Hoặc click "Join" trên danh sách phòng
- Cho phép truy cập camera và microphone
- Kiểm tra thiết bị trước khi join

### 5. Trong phòng họp
- **Bật/tắt mic**: Click icon microphone
- **Bật/tắt camera**: Click icon video
- **Chia sẻ màn hình**: Click icon screen share
- **Chat**: Sử dụng panel chat bên phải
- **Rời phòng**: Click "Leave" hoặc đóng tab

## 🎯 Kiến trúc SFU và Tối ưu băng thông

### Tại sao chọn SFU?

**Mesh Network (P2P):**
- Mỗi peer kết nối trực tiếp với tất cả peers khác
- Băng thông tăng theo O(n²) với n participants
- Không phù hợp cho > 4-5 người

**MCU (Multipoint Control Unit):**
- Server mix tất cả streams thành 1 stream
- Băng thông ổn định nhưng tốn CPU server
- Chất lượng bị giảm do encode/decode

**SFU (Selective Forwarding Unit):**
- Server forward streams mà không decode
- Băng thông tuyến tính O(n)
- Chất lượng cao, CPU hiệu quả
- ✅ **Lựa chọn tối ưu cho GMeeting**

### Tối ưu băng thông với MediaSoup

1. **Simulcast**: Client gửi nhiều quality streams
2. **Adaptive bitrate**: Tự động điều chỉnh chất lượng
3. **SVC (Scalable Video Coding)**: Chia layer theo resolution/fps
4. **Bandwidth estimation**: Theo dõi network conditions

## 🔧 API Documentation

### Authentication APIs
```
POST /api/auth/register     # Đăng ký
POST /api/auth/login        # Đăng nhập
GET  /api/auth/profile      # Lấy thông tin user
```

### Room Management APIs
```
GET    /api/rooms           # Lấy danh sách phòng
POST   /api/rooms           # Tạo phòng mới
GET    /api/rooms/:id       # Lấy thông tin phòng
PUT    /api/rooms/:id       # Cập nhật phòng
DELETE /api/rooms/:id       # Xóa phòng
POST   /api/rooms/:id/join  # Tham gia phòng
POST   /api/rooms/:id/leave # Rời phòng
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
// Client -> Server
'join-room'         # Tham gia phòng
'leave-room'        # Rời phòng
'chat-message'      # Gửi tin nhắn

// Server -> Client
'room-joined'       # Đã tham gia phòng
'user-joined'       # User khác join
'user-left'         # User khác leave
'chat-message'      # Tin nhắn mới
'room-deleted'      # Phòng bị xóa
```

### SFU Socket Events
```javascript
// Client -> Server
'join-room'                 # Join SFU room
'get-router-rtp-capabilities' # Lấy RTP capabilities
'create-webrtc-transport'   # Tạo WebRTC transport
'connect-transport'         # Kết nối transport
'produce'                   # Produce media
'consume'                   # Consume media

// Server -> Client
'router-rtp-capabilities'   # RTP capabilities
'webrtc-transport-created'  # Transport đã tạo
'new-producer'              # Producer mới
'producer-closed'           # Producer đã đóng
```

## 🐛 Troubleshooting

### Development Issues

#### 1. Database Connection Failed
```bash
# Kiểm tra database containers
./test-services.sh

# Kiểm tra MySQL container
docker ps | grep mysql
docker logs gmeeting_mysql

# Kiểm tra Redis container  
docker ps | grep redis
docker logs gmeeting_redis

# Reset database nếu cần
./stop-db.sh
docker volume rm gmeeting_mysql_data gmeeting_redis_data
./start-db.sh
```

#### 2. Port Already in Use
```bash
# Kiểm tra port đang được sử dụng
sudo lsof -i :3000  # Frontend
sudo lsof -i :3001  # Backend
sudo lsof -i :3002  # SFU
sudo lsof -i :3306  # MySQL
sudo lsof -i :6379  # Redis

# Kill process nếu cần
sudo kill -9 <PID>

# Hoặc dùng script stop
./stop-dev.sh
```

#### 3. Node.js Version Issues
```bash
# Kiểm tra version
node --version
npm --version

# Cài đặt Node.js 20+ nếu cần
# Ubuntu/Debian:
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# macOS:
brew install node@20
```

#### 4. Dependencies Installation Failed
```bash
# Clear cache và reinstall
rm -rf backend/node_modules
rm -rf frontend/node_modules  
rm -rf sfu-server/node_modules
rm -f backend/package-lock.json
rm -f frontend/package-lock.json
rm -f sfu-server/package-lock.json

# Reinstall
./install-deps.sh
```

#### 5. MediaSoup Installation Failed
```bash
# MediaSoup cần Python và build tools
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

#### 6. Permission Denied on Scripts
```bash
# Cấp quyền execute cho scripts
chmod +x *.sh

# Hoặc chạy với bash
bash start-db.sh
bash start-dev.sh
```

#### 7. Docker Issues
```bash
# Kiểm tra Docker service
sudo systemctl status docker

# Start Docker nếu cần
sudo systemctl start docker

# Add user to docker group (Linux)
sudo usermod -aG docker $USER
# Logout và login lại
```

#### 8. Frontend Build Issues
```bash
# Clear Nuxt cache
cd frontend
rm -rf .nuxt .output dist
npm run dev
```

#### 9. Environment Variables
```bash
# Kiểm tra .env file tồn tại
ls -la .env

# Copy từ template nếu cần
cp .env.example .env

# Kiểm tra biến môi trường
./test-services.sh
```

#### 10. Network/CORS Issues
```bash
# Kiểm tra CORS settings trong .env
grep CORS .env

# Test API endpoints
curl -v http://localhost:3001/health
curl -v http://localhost:3002/health

# Kiểm tra frontend có thể connect backend
# Mở browser dev tools → Network tab
```

### Common Error Messages

#### "ECONNREFUSED" Database
- Database chưa được khởi động
- Chạy `./start-db.sh` và chờ database ready

#### "EADDRINUSE" Port Conflict
- Port đã được sử dụng bởi process khác
- Dùng `./stop-dev.sh` hoặc kill manual

#### "gyp ERR!" MediaSoup Build
- Thiếu Python hoặc build tools
- Cài đặt Python 3.8+ và build-essential

#### "Permission denied" Scripts
- Script chưa có quyền execute
- Chạy `chmod +x *.sh`

#### "Cannot find module" Dependencies
- Dependencies chưa được cài đặt đúng
- Chạy `./install-deps.sh`

### Getting Help

Nếu vẫn gặp vấn đề:

1. **Kiểm tra logs chi tiết:**
```bash
# Backend logs
cd backend && npm run dev 2>&1 | tee ../logs/backend.log

# SFU logs  
cd sfu-server && npm run dev 2>&1 | tee ../logs/sfu.log

# Frontend logs
cd frontend && npm run dev 2>&1 | tee ../logs/frontend.log
```

2. **Kiểm tra trạng thái system:**
```bash
./test-services.sh
docker ps
docker logs gmeeting_mysql
docker logs gmeeting_redis
```

3. **Reset toàn bộ:**
```bash
./stop-dev.sh
./stop-db.sh
docker system prune -f
./start-db.sh
./install-deps.sh
./start-dev.sh
```

## 📊 Monitoring và Logs

### Log levels
- **Backend**: `info`, `warn`, `error`
- **SFU**: `warn`, `error`, `info`, `ice`, `dtls`, `rtp`

### Monitoring endpoints
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
- JWT tokens với expiration
- Bcrypt password hashing
- Rate limiting on APIs

### WebRTC Security
- DTLS encryption cho media
- SRTP cho audio/video streams
- ICE/STUN cho NAT traversal

### Environment Security
- Sensitive data trong `.env`
- Docker secrets cho production
- Database credentials rotation

## 🚀 Production Deployment

### 1. Build production images
```bash
# Build backend
docker build -t gmeeting-backend ./backend

# Build SFU server
docker build -t gmeeting-sfu ./sfu-server

# Build frontend
cd frontend && npm run build
```

### 2. Environment setup
```bash
# Production .env
NODE_ENV=production
ANNOUNCED_IP=<your-public-ip>
FRONTEND_URL=https://your-domain.com
BACKEND_URL=https://api.your-domain.com
```

### 3. SSL/TLS setup
- MediaSoup requires HTTPS in production
- Use Let's Encrypt hoặc CloudFlare
- Configure reverse proxy (Nginx/Caddy)

### 4. Scaling considerations
- Load balancer cho multiple SFU instances
- Redis Cluster cho session scaling
- Database replication
- CDN cho static assets

## 📝 Contributing

1. Fork repository
2. Tạo feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push branch: `git push origin feature/amazing-feature`
5. Tạo Pull Request

## 📄 License

MIT License - xem file [LICENSE](LICENSE) để biết thêm chi tiết.

## 🙋‍♂️ Support

Nếu gặp vấn đề, vui lòng:
1. Kiểm tra [Troubleshooting](#-troubleshooting)
2. Tạo [Issue](issues) trên GitHub
3. Liên hệ team qua email

## 🎉 Credits

- [MediaSoup](https://mediasoup.org/) - Excellent SFU library
- [Nuxt.js](https://nuxt.com/) - Amazing Vue.js framework
- [TailwindCSS](https://tailwindcss.com/) - Beautiful styling
- [Socket.IO](https://socket.io/) - Reliable WebSocket library

---

## 🚀 TL;DR - Super Quick Start

```bash
# Clone and setup
git clone <repository-url>
cd gmeeting

# One-command setup
./quick-start.sh
# Choose option 3: "🔧 Full Setup"

# Or manual step-by-step
./health-check.sh          # Check environment
./setup-permissions.sh     # Fix permissions
./start-db.sh             # Start database
./install-deps.sh         # Install dependencies
./start-dev.sh            # Start development
```

**Access at:** http://localhost:3000

**Need help?** Run `./health-check.sh` or check the troubleshooting section above.

---

*Happy coding with GMeeting! 🎥✨*

### Các Scripts Hỗ trợ Development

Dự án cung cấp các scripts để quản lý development dễ dàng:

#### Core Scripts
```bash
./health-check.sh        # Kiểm tra tổng thể môi trường development
./setup-permissions.sh   # Thiết lập quyền files và thư mục
./install-deps.sh        # Cài đặt dependencies cho tất cả services
./start-db.sh           # Khởi động MySQL + Redis bằng Docker
./stop-db.sh            # Dừng database containers
```

#### Development Scripts
```bash
./start-dev.sh          # Script chính: hướng dẫn chạy development
./start-dev-manual.sh   # Script chi tiết cho development thủ công
./stop-dev.sh           # Dừng tất cả development services
./test-services.sh      # Kiểm tra trạng thái các services
./quick-start.sh        # Quick start guide với automation
```

### Script Usage Examples

#### Workflow Hoàn chỉnh
```bash
# Bước 1: Kiểm tra môi trường
./health-check.sh

# Bước 2: Thiết lập quyền (nếu cần)
./setup-permissions.sh

# Bước 3: Cài đặt dependencies
./install-deps.sh

# Bước 4: Khởi động database
./start-db.sh

# Bước 5: Kiểm tra services
./test-services.sh

# Bước 6: Chạy development
./start-dev.sh
# Chọn: manual/auto/guided

# Bước 7: Dừng khi xong
./stop-dev.sh
./stop-db.sh
```

#### Quick Testing
```bash
# Kiểm tra nhanh tất cả services
./test-services.sh

# Output hiển thị trạng thái:
# ✅ MySQL: Connected
# ✅ Redis: Connected  
# ✅ Backend: Running (http://localhost:3001)
# ✅ Frontend: Running (http://localhost:3000)
# ✅ SFU Server: Running (http://localhost:3002)
```

#### Troubleshooting Workflow
```bash
# Khi gặp vấn đề, chạy health check
./health-check.sh

# Sửa permissions nếu cần
./setup-permissions.sh

# Reset môi trường
./stop-dev.sh
./stop-db.sh
docker system prune -f

# Khởi động lại
./start-db.sh
./start-dev.sh
```

### Script Features

- **Health Check**: Kiểm tra Node.js, Docker, cấu trúc project, ports
- **Auto-detection**: Tự động kiểm tra version, dependencies, services
- **Error handling**: Báo lỗi rõ ràng và hướng dẫn khắc phục
- **Cross-platform**: Hoạt động trên Linux, macOS, WSL
- **Process management**: Kill processes theo PID và port cleanup
- **Logging**: Tạo logs trong thư mục `logs/` khi chạy auto mode

### Advanced Usage

#### Chạy với auto mode
```bash
# Health check trước khi start
./start-dev.sh
# Chọn health check: Y
# Chọn mode: auto

# Xem logs realtime
tail -f logs/backend.log
tail -f logs/sfu.log  
tail -f logs/frontend.log
```

#### Debug specific service
```bash
# Chỉ khởi động database
./start-db.sh

# Chạy từng service riêng để debug
cd backend && npm run dev
cd sfu-server && npm run dev
cd frontend && npm run dev
```

#### Environment Reset
```bash
# Reset hoàn toàn
./stop-dev.sh
./stop-db.sh
docker system prune -f
rm -rf */node_modules
./install-deps.sh
./start-db.sh
./start-dev.sh
```
