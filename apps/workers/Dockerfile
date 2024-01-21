# ------------------------------------------
#                BUILD STAGE              
# ------------------------------------------ 
# Full Node image must be used for node_modules install 
# TODO - Upgrade to v18.x (LTS) when this issue is resolved - https://github.com/prisma/prisma/issues/10649#issuecomment-1249209025
FROM node:18-alpine3.18 as builder

WORKDIR /app
COPY ./dist/apps/workers ./yarn.lock ./prisma ./
RUN yarn install --production

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