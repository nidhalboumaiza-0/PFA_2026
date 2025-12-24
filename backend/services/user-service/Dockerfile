# User Service Dockerfile
FROM node:20-alpine
WORKDIR /app

RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

COPY shared/package*.json ./shared/
RUN cd shared && npm install --omit=dev

COPY services/user-service/package*.json ./services/user-service/
RUN cd services/user-service && npm install --omit=dev

COPY shared/ ./shared/
COPY services/user-service/ ./services/user-service/

WORKDIR /app/services/user-service
RUN chown -R nodejs:nodejs /app

ENV NODE_ENV=production
ENV PORT=3002
EXPOSE 3002
USER nodejs

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3002/health || exit 1

CMD ["node", "src/server.js"]
