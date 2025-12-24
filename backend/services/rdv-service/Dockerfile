# RDV Service Dockerfile
FROM node:20-alpine
WORKDIR /app

RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

COPY shared/package*.json ./shared/
RUN cd shared && npm install --omit=dev

COPY services/rdv-service/package*.json ./services/rdv-service/
RUN cd services/rdv-service && npm install --omit=dev

COPY shared/ ./shared/
COPY services/rdv-service/ ./services/rdv-service/

WORKDIR /app/services/rdv-service
RUN chown -R nodejs:nodejs /app

ENV NODE_ENV=production
ENV PORT=3003
EXPOSE 3003
USER nodejs

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3003/health || exit 1

CMD ["node", "src/server.js"]
