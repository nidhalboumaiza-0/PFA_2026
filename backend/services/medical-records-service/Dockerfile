# Medical Records Service Dockerfile
FROM node:20-alpine
WORKDIR /app

RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

COPY shared/package*.json ./shared/
RUN cd shared && npm install --omit=dev

COPY services/medical-records-service/package*.json ./services/medical-records-service/
RUN cd services/medical-records-service && npm install --omit=dev

COPY shared/ ./shared/
COPY services/medical-records-service/ ./services/medical-records-service/

WORKDIR /app/services/medical-records-service
RUN chown -R nodejs:nodejs /app

ENV NODE_ENV=production
ENV PORT=3004
EXPOSE 3004
USER nodejs

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3004/health || exit 1

CMD ["node", "src/server.js"]
