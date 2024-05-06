# Self Hosting Maybe with Docker

## Quick Start

To quickly get the Maybe app up and running, follow these steps:

* clone the maybe repository to your local machine.
* navigate to the repository's root directory.
* copy the `.env.example` file to `.env` and configure the necessary
environment variables. Edit the `SELF_HOSTING_ENABLED` and `SECRET_KEY_BASE`
variables. You might want to edit the `DB_HOST`, `DB_PORT`,
`POSTGRES_PASSWORD`, `POSTGRES_USER` variables as well.
* run `docker-compose up -d` to start the maybe app in detached mode.
* access the maybe app by navigating to http://localhost:3000 in your web browser.

## Prerequisites and Setup

Install Docker on your machine by following the appropriate guide for your operating system. If you need a GUI, install [Docker Desktop](https://docs.docker.com/desktop/), otherwise innstall
[Docker Engine](https://docs.docker.com/engine/install/) (recommended for production).

Next, follow these steps (shared between docker-compose and standalone):

* clone the maybe repository to your local machine.
* navigate to the repository's root directory.
* copy the `.env.example` file to `.env` and configure the necessary
environment variables. Edit the `SELF_HOSTING_ENABLED` and `SECRET_KEY_BASE`
variables. You might want to edit the `DB_HOST`, `DB_PORT`,
`POSTGRES_PASSWORD`, `POSTGRES_USER` variables as well.

### Running the app with docker compose

* run `docker-compose up -d` to start the maybe app in detached mode.
* access the maybe app by navigating to http://localhost:3000 in your web browser.

### Running the standalone container

* run the `maybe` docker container

```bash
docker run -d \
    --name app \
    -p 3000:3000 \
    --restart unless-stopped \
    --env-file .env \
    -e RAILS_ENV=production \
    -e RAILS_FORCE_SSL=false \
    -e RAILS_ASSUME_SSL=false \
    ghcr.io/maybe-finance/maybe:latest
```

## Updating the App

To update the Maybe app to the latest version, follow these steps:

* Pull the latest changes from the Maybe repository if running the container in
standalone mode.
* If using Docker Compose, update the image field in the docker-compose.yml
file to point to the new Docker image version (not needed if running on the
`latest` tag, docker will automatically pull the latest image).
* Run `docker-compose pull` to pull the latest Docker image.
* Restart the Maybe app container using `docker-compose up -d`.

## Where should I host?

### Commercial VPS
### One-Click VPS
### Standalone Image

## Troubleshooting 

This section will provide troubleshooting tips and solutions for common issues
encountered during deployment. Check back later for updates!

