#!/bin/bash

yarn nx run e2e:e2e \
    --baseUrl https://staging-app.maybe.co \
    --headed \
    --skip-nx-cache \
    --env.AUTH0_ID 'REPLACE_THIS' \
    --env.AUTH0_DOMAIN REPLACE_THIS \
    --env.API_URL https://staging-api.maybe.co/v1 \
    --env.AUTH0_CLIENT_ID REPLACE_THIS \
    --env.STRIPE_WEBHOOK_SECRET REPLACE_THIS