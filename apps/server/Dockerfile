# ------------------------------------------
#                BUILD STAGE              
# ------------------------------------------ 
FROM node:18-alpine3.18 as builder

WORKDIR /app
COPY ./dist/apps/server ./pnpm-lock.yaml ./prisma ./
RUN pnpm install --prod --frozen-lockfile && pnpm add ejs

# ------------------------------------------
#                PROD STAGE               
# ------------------------------------------ 
FROM node:18-alpine3.18 as prod

# Used for container health checks
RUN apk add --no-cache curl
WORKDIR /app
USER node 
COPY --from=builder /app  .

CMD ["node", "--es-module-specifier-resolution=node", "./main.js"]