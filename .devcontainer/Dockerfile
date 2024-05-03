ARG RUBY_VERSION=3.3.1
FROM ruby:${RUBY_VERSION}-slim-bullseye

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
