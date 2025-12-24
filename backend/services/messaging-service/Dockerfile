# Messaging Service Dockerfile
FROM node:20-alpine
WORKDIR /app

RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

COPY shared/package*.json ./shared/
RUN cd shared && npm install --omit=dev

COPY services/messaging-service/package*.json ./services/messaging-service/
RUN cd services/messaging-service && npm install --omit=dev

COPY shared/ ./shared/
COPY services/messaging-service/ ./services/messaging-service/

WORKDIR /app/services/messaging-service
RUN chown -R nodejs:nodejs /app

ENV NODE_ENV=production
ENV PORT=3006
EXPOSE 3006
USER nodejs

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3006/health || exit 1

CMD ["node", "src/server.js"]
