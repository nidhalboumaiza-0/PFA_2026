# API Gateway Dockerfile
FROM node:20-alpine
WORKDIR /app

RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

COPY shared/package*.json ./shared/
RUN cd shared && npm install --omit=dev

COPY api-gateway/package*.json ./api-gateway/
RUN cd api-gateway && npm install --omit=dev

COPY shared/ ./shared/
COPY api-gateway/ ./api-gateway/

WORKDIR /app/api-gateway
RUN chown -R nodejs:nodejs /app

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000
USER nodejs

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "src/server.js"]
