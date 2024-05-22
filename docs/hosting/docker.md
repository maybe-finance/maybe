# Self Hosting Maybe with Docker

## Quick Start

_The below quickstart assumes you're running on Mac or Linux. Windows will
be different._

Make sure [Docker is installed](https://docs.docker.com/engine/install/) and
setup your local environment:

```bash
# Create a directory on your computer for Docker files
mkdir -p ~/docker-apps/maybe
cd ~/docker-apps/maybe

# Download the sample docker-compose.yml file from the Maybe Github repository
curl -o docker-compose.yml https://raw.githubusercontent.com/maybe-finance/maybe/main/docker-compose.example.yml

# Create an .env file (make sure to fill in empty variables manually)
cat << EOF > .env
# Use "openssl rand -hex 64" to generate this
SECRET_KEY_BASE=

# Can be any value, set to what you'd like
POSTGRES_PASSWORD=
EOF
```

Make sure to generate your `SECRET_KEY_BASE` value and save the `.env` file.
Then you're ready to run the app, which will be available at
`http://localhost:3000` in your browser:

```bash
docker compose -f docker-compose.example.yml up -d
```

Lastly, go to `http://localhost:3000` in your browser, **create a new
account**, and you're ready to start tracking your finances!

## Detailed Setup Guide

### Prerequisites

- Install Docker Engine by
  following [the official guide](https://docs.docker.com/engine/install/)
- Start the Docker service on your machine

### App Setup

1. Create a new directory on your machine (we suggest something like
   `$HOME/docker-apps/maybe`)
2. Create a `docker-compose.yml` file (we suggest
   using [our example](/docker-compose.example.yml)
   if
   you're new to self-hosting and Docker)
3. Create a `.env` file and add the required variables. Currently,
   `SECRET_KEY_BASE` is the only required variable, but you can take a look
   at our [.env.example](/.env.example) file to see all available options.

### Run app with Docker Compose

1. Run `docker-compose up -d` to start the maybe app in detached mode.
2. Access the Maybe app by navigating to http://localhost:3000 in your web
   browser.

### Updating the App

The mechanism that updates your self-hosted Maybe app is the GHCR (Github
Container Registry) Docker image that you see in the `docker-compose.yml` file:

```yml
image: ghcr.io/maybe-finance/maybe:latest
```

We recommend using one of the following images, but you can pin your app to
whatever version you'd like (
see [packages](https://github.com/maybe-finance/maybe/pkgs/container/maybe)):

- `ghcr.io/maybe-finance/maybe:latest` (latest commit)
- `ghcr.io/maybe-finance/maybe:stable` (latest release)

By default, your app _will NOT_ automatically update. To update your
self-hosted app, you must run the following commands:

```bash
docker-compose pull # This pulls the "latest" published image from GHCR

docker-compose up -d # Restarts the app
```

#### Changing the image

If you'd like to pin the app to a specific version or tag, all you need to do is
edit the `docker-compose.yml` file:

```yml
image: ghcr.io/maybe-finance/maybe:stable
```

## Troubleshooting

This section will provide troubleshooting tips and solutions for common issues
encountered during deployment. Check back later for updates!

