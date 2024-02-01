# ------------------------------------------
#                BUILD STAGE              
# ------------------------------------------ 
FROM node:18-alpine3.18 as builder

WORKDIR /app
COPY ./dist/apps/client ./pnpm-lock.yaml ./prisma ./package.json ./
# Install dependencies
RUN npm install -g pnpm
RUN pnpm install --frozen-lockfile --production=false

# ------------------------------------------
#                PROD STAGE               
# ------------------------------------------ 
FROM node:18-alpine3.18 as prod

COPY ./apps/client/env.sh /env.sh
RUN chmod +x /env.sh

# Used for container health checks and env handling
RUN apk add --no-cache curl gawk bash
WORKDIR /app
USER node 
COPY --from=builder --chown=node:node /app  .

ENTRYPOINT ["/env.sh"]
CMD ["npx", "next", "start"]
