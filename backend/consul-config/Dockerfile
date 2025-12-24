FROM node:20-alpine

WORKDIR /app

# Install curl for health checks
RUN apk add --no-cache curl bash

# Copy package files
COPY consul-config/package*.json ./consul-config/

# Install dependencies
RUN cd consul-config && npm install || true

# Copy seed script
COPY consul-config/ ./consul-config/

# Make shell scripts executable
RUN chmod +x ./consul-config/*.sh 2>/dev/null || true

WORKDIR /app/consul-config

CMD ["node", "seed-consul-config.js"]
