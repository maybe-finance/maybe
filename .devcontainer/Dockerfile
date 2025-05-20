ARG RUBY_VERSION=3.4.4
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
  libyaml-dev \
  libyaml-0-2 \
  openssh-client \
  postgresql-client \
  vim

RUN gem install bundler
RUN gem install foreman

# Install Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
&& apt-get install -y nodejs

WORKDIR /workspace
