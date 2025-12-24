# Auth Service Dockerfile
# Build from backend root context to include shared folder

FROM node:20-alpine

WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy shared module first and install its dependencies
COPY shared/package*.json ./shared/
RUN cd shared && npm install --omit=dev

# Copy service package files
COPY services/auth-service/package*.json ./services/auth-service/

# Install service dependencies
RUN cd services/auth-service && npm install --omit=dev

# Copy shared source code
COPY shared/ ./shared/

# Copy service source code
COPY services/auth-service/ ./services/auth-service/

# Set working directory to service
WORKDIR /app/services/auth-service

# Change ownership
RUN chown -R nodejs:nodejs /app

# Set environment
ENV NODE_ENV=production
ENV PORT=3001

# Expose port
EXPOSE 3001

# Switch to non-root user
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1

# Start the application
CMD ["node", "src/server.js"]
