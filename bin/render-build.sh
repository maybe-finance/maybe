#!/usr/bin/env bash
# exit on error
set -o errexit

echo "Installing gems..."
bundle install

echo "Precompiling assets..."
./bin/rails assets:precompile
./bin/rails assets:clean

echo "Build complete"
