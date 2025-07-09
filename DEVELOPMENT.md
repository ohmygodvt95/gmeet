# GMeeting Development Guide

## 🚀 Quick Start

### 1. Install Dependencies
```bash
chmod +x install-deps.sh
./install-deps.sh
```

### 2. Start Database
```bash
chmod +x start-db.sh
./start-db.sh
```

### 3. Start Development Servers
Open 3 separate terminals:

**Terminal 1 - Backend:**
```bash
cd backend
npm run dev
```

**Terminal 2 - SFU Server:**
```bash
cd sfu-server
npm run dev
```

**Terminal 3 - Frontend:**
```bash
cd frontend
npm run dev
```

### 4. Access Application
- Frontend: http://localhost:3000
- Backend: http://localhost:3001
- SFU: http://localhost:3002

## 🛠️ Available Scripts

| Script | Description |
|--------|-------------|
| `./install-deps.sh` | Install all dependencies |
| `./start-db.sh` | Start database services only |
| `./stop-db.sh` | Stop database services |
| `./quick-start.sh` | Show development guide |
| `./test-app.sh` | Test application health |

## 🗄️ Database Management

### Start Database Only
```bash
./start-db.sh
```

### Stop Database
```bash
./stop-db.sh
```

### Reset Database (Delete all data)
```bash
docker-compose -f docker-compose.db.yml down -v
./start-db.sh
```

### View Database Logs
```bash
docker-compose -f docker-compose.db.yml logs -f
```

## 🔧 Development Tips

### Environment Variables
- Database runs in Docker: `localhost:3306`
- Redis runs in Docker: `localhost:6379`
- Services run on host machine

### Common Issues
1. **Port conflicts**: Make sure ports 3000, 3001, 3002, 3306, 6379 are free
2. **Node.js version**: Use Node.js 18+ (preferably 20+)
3. **Docker not running**: Start Docker Desktop
4. **Permission errors**: Use `chmod +x` for scripts

### Testing
```bash
# Test database connectivity
./test-app.sh

# Test individual services
curl http://localhost:3001/health
curl http://localhost:3002/health
curl http://localhost:3000
```

## 📱 Application Usage

1. **Register**: Create new account at http://localhost:3000
2. **Login**: Use credentials or admin account
3. **Create Room**: Click "Create Room" 
4. **Join Meeting**: Share room link or join existing room
5. **Video Call**: Allow camera/microphone permissions

### Default Admin Account
- Email: `admin@gmeeting.com`
- Password: `admin123`

## 🐛 Troubleshooting

### Backend Issues
```bash
cd backend
npm run dev
# Check console for errors
```

### SFU Issues
```bash
cd sfu-server
npm run dev
# Check MediaSoup compilation
```

### Frontend Issues
```bash
cd frontend
npm run dev
# Check TypeScript errors
```

### Database Issues
```bash
# Restart database
./stop-db.sh
./start-db.sh

# Check database logs
docker logs gmeeting_mysql
docker logs gmeeting_redis
```

## 🔄 Restart Everything
```bash
# Stop all
./stop-db.sh
# Kill any remaining processes
killall node

# Start fresh
./start-db.sh
# Then start each service manually
```
