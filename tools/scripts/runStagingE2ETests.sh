#!/bin/bash

yarn nx run e2e:e2e \
    --baseUrl https://staging-app.maybe.co \
    --headed \
    --skip-nx-cache \
    --env.API_URL https://staging-api.maybe.co/v1 \
    --env.STRIPE_WEBHOOK_SECRET REPLACE_THIS
