# ------------------------------------------
#                BUILD STAGE              
# ------------------------------------------ 
# Full Node image must be used for node_modules install 
# TODO - Upgrade to v18.x (LTS) when this issue is resolved - https://github.com/prisma/prisma/issues/10649#issuecomment-1249209025
FROM node:16.18.1 as builder

WORKDIR /app
COPY ./dist/apps/client ./yarn.lock ./prisma ./package.json ./apps/client/env.sh ./
RUN chmod +x ./env.sh
# Install dependencies
RUN yarn install --production=false

# ------------------------------------------
#                PROD STAGE               
# ------------------------------------------ 
FROM node:16.18.1-slim as prod

# Used for container health checks and env handling
RUN apt-get update && apt-get install curl gawk -y
WORKDIR /app
USER node 
COPY --from=builder --chown=node:node /app  .

CMD ["./env.sh", "npx", "next", "start"]
