# Referral Service Dockerfile
FROM node:20-alpine
WORKDIR /app

RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

COPY shared/package*.json ./shared/
RUN cd shared && npm install --omit=dev

COPY services/referral-service/package*.json ./services/referral-service/
RUN cd services/referral-service && npm install --omit=dev

COPY shared/ ./shared/
COPY services/referral-service/ ./services/referral-service/

WORKDIR /app/services/referral-service
RUN chown -R nodejs:nodejs /app

ENV NODE_ENV=production
ENV PORT=3005
EXPOSE 3005
USER nodejs

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3005/health || exit 1

CMD ["node", "src/server.js"]
