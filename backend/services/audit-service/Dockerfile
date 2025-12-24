# Audit Service Dockerfile
FROM node:20-alpine
WORKDIR /app

RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

COPY shared/package*.json ./shared/
RUN cd shared && npm install --omit=dev

COPY services/audit-service/package*.json ./services/audit-service/
RUN cd services/audit-service && npm install --omit=dev

COPY shared/ ./shared/
COPY services/audit-service/ ./services/audit-service/

WORKDIR /app/services/audit-service
RUN chown -R nodejs:nodejs /app

ENV NODE_ENV=production
ENV PORT=3008
EXPOSE 3008
USER nodejs

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3008/health || exit 1

CMD ["node", "src/server.js"]
