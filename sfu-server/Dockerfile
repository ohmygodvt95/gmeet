FROM node:20-alpine

# Install Python and build tools for MediaSoup
RUN apk add --no-cache python3 py3-pip make g++ linux-headers libc6-compat

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# Change ownership
RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 3002
EXPOSE 10000-10100/udp

CMD ["npm", "start"]
