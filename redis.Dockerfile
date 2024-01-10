FROM redis:6-alpine

COPY redis.conf .

ENTRYPOINT ["redis-server", "./redis.conf"]