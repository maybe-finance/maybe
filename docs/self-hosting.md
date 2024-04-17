The fastest way to get your own version of Maybe running is a "one-click deploy". Below are the currently supported platforms:

## One-Click Deploys

### Render (recommended)

<a href="https://render.com/deploy?repo=https://github.com/maybe-finance/maybe">
<img src="https://render.com/images/deploy-to-render-button.svg" alt="Deploy to Render" />
</a>

1. Click the button above
2. Follow the instructions in the [Render self-hosting guide](self-hosting/render.md)

## Docker

0. Install docker (cf. the [docker guide](self-hosting/docker.md) for more
   info)

### Running the docker compose stack

1. Create a new folder inside your working directory (eg. your home directory
   or `/srv/docker`) named `maybe`

2. Move into the `maybe` folder and copy the `docker-compose.example.yml` file
   from the root of the repository to `docker-compose.yml`

3. Copy the `.env.example` file from the root of the repository and rename it
   to `.env`

4. Edit the `.env` file and adjust the `SELF_HOSTING_ENABLED` and
   `SECRET_KEY_BASE` variables

4. Run `docker-compose up -d` to bring up the stack

5. Navigate to http://localhost:3000 in your browser

### Running the standalone container

This method might be suitable if you already have a redis and postgres service
running and do not wish to run containers for them too.

2. Copy the `.env.example` file from the root of the repository and rename it
   to `.env`

3. Edit the `.env` file and adjust the `SELF_HOSTING_ENABLED` and
   `SECRET_KEY_BASE` variables. You might want to edit the `DB_HOST`,
`DB_PORT`, `POSTGRES_PASSWORD`, `POSTGRES_USER` variables as well

4. Run the `maybe` docker container
```bash
docker run -d \
    --name app \
    -p 3000:3000 \
    --restart unless-stopped \
    --env-file .env \
    -e HOSTING_PLATFORM=localhost \
    -e DISABLE_SSL=true \
    ghcr.io/maybe-finance/maybe:latest
```

### Deploying to commercial VPS

**Estimated cost:** $5-15 per month

The steps of deploying a commercial VPS instance provisioned with docker are
outlined in the [docker guide](self-hosting/docker.md).

## Self hosting disclaimer

While we attempt to provide cost-effective deployment options, please remember,
**self-hosting _may_ incur monthly charges on your hosting platform of
choice**. While we provide cost estimates for each deployment option, it is
your responsibility to manage these costs.
