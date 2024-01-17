# ------------------------------------------
#                BUILD STAGE              
# ------------------------------------------ 
# Full Node image must be used for node_modules install 
# TODO - Upgrade to v18.x (LTS) when this issue is resolved - https://github.com/prisma/prisma/issues/10649#issuecomment-1249209025
FROM node:16.18.1 as builder

WORKDIR /app
COPY ./dist/apps/client ./yarn.lock ./prisma ./
# Install dependencies
RUN yarn install --production=false && yarn add prosemirror-keymap @next/bundle-analyzer

# ------------------------------------------
#                PROD STAGE               
# ------------------------------------------ 
FROM node:16.18.1-slim as prod

# Used for container health checks
RUN apt-get update && apt-get install curl -y
WORKDIR /app
USER node 
COPY --from=builder /app  .

CMD ["npx", "next start"]
