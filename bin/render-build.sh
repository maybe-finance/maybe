#!/usr/bin/env bash
# exit on error
set -o errexit

echo "Installing gems..."
bundle install

echo "Precompiling assets..."
./bin/rails assets:precompile
./bin/rails assets:clean

echo "Build complete"

# Self Hosters:
#
# By default, one-click deploys are free-tier instances (to avoid unexpected charges)
# Render does NOT allow free-tier instances to use the `preDeployCommand` feature, so 
# database migrations must be run in the build step.
#
# If you're on a paid Render plan, you can remove the `RUN_DB_MIGRATIONS_IN_BUILD_STEP` (or set to `false`)
if [ "$RUN_DB_MIGRATIONS_IN_BUILD_STEP" = "true" ]; then
  echo "Initiating database migrations for the free tier..."
  bundle exec rails db:migrate
  echo "Database migrations completed. Reminder: If you've moved to a Render paid plan, you can remove the RUN_DB_MIGRATIONS_IN_BUILD_STEP environment variable to utilize the `preDeployCommand` feature for migrations."
fi
