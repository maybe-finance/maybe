# ARG RUBY_VERSION=3.3.0
# FROM ruby:${RUBY_VERSION}-slim-bullseye

# TODO - Uncomment the lines above when 3.3.1 is released.
# This is a temporary fix for a bug found here (https://stackoverflow.com/questions/77725755/segmentation-fault-during-rails-assetsprecompile-on-apple-silicon-m3-with-rub)

FROM debian:bullseye-slim as base

# Install dependencies for building Ruby
RUN apt-get update && apt-get install -y build-essential wget autoconf

# Install ruby-install for installing Ruby
RUN wget https://github.com/postmodern/ruby-install/releases/download/v0.9.3/ruby-install-0.9.3.tar.gz \
  && tar -xzvf ruby-install-0.9.3.tar.gz \
  && cd ruby-install-0.9.3/ \
  && make install

# Install Ruby 3.3.0 with the https://github.com/ruby/ruby/pull/9371 patch
RUN ruby-install -p https://github.com/ruby/ruby/pull/9371.diff ruby 3.3.0

# Make the Ruby binary available on the PATH
ENV PATH="/opt/rubies/ruby-3.3.0/bin:${PATH}"

# End TODO

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y install --no-install-recommends \
  apt-utils \
  build-essential \
  curl \
  git \
  imagemagick \
  iproute2 \
  libpq-dev \
  openssh-client \
  postgresql-client \
  vim

RUN gem install bundler
RUN gem install foreman

WORKDIR /workspace
