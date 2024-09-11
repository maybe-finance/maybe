# Self Hosting Maybe with Docker

This guide will help you setup, update, and maintain your self-hosted Maybe application with Docker Compose. Docker Compose is the most popular and recommended way to self-host the Maybe app.

If you want a _less
technical_ way to host the Maybe app, you can [host on Render](/docs/hosting/one-click-deploy.md) as an
_**alternative** to Docker Compose_.

## Setup Guide

Follow the guide below to get your app running.

### Step 1: Install Docker

Complete the following steps:

1. Install Docker Engine by following [the official guide](https://docs.docker.com/engine/install/)
2. Start the Docker service on your machine
3. Verify that Docker is installed correctly and is running by opening up a terminal and running the following command:

```bash
# If Docker is setup correctly, this command will succeed
docker run hello-world
```

### Step 2: Configure your Docker Compose file and environnment

#### Create a directory for your app to run

Open your terminal and create a directory where your app will run. Below is an example command with a recommended directory:

```bash
# Create a directory on your computer for Docker files
mkdir -p ~/docker-apps/maybe

# Once created, navigate your current working directory to the new folder
cd ~/docker-apps/maybe
```

#### Copy our sample Docker Compose file

Make sure you are in the directory you just created and run the following command:

```bash
# Download the sample docker-compose.yml file from the Maybe Github repository
curl -o compose.yml https://raw.githubusercontent.com/maybe-finance/maybe/main/docker-compose.example.yml
```

This command will do the following:

1. Fetch the sample docker compose file from our public Github repository
2. Creates a file in your current directory called `compose.yml` with the contents of the example file

At this point, the only file in your current working directory should be `compose.yml`.

#### Create your environment file

In order to configure the app, you will need to create a file called `.env`, which is where Docker will read environment variables from.

To do this, run the following command:

```bash
touch .env
```

#### Generate the app secret key

The app requires an environment variable called `SECRET_KEY_BASE` to run.

We will first need to generate this in the terminal. If you have `openssl` installed on your computer, you can generate it with the following command:

```bash
openssl rand -hex 64
```

_Alternatively_, you can generate a key without openssl or any external dependencies by pasting the following bash command in your terminal and running it:

```bash
head -c 64 /dev/urandom | od -An -tx1 | tr -d ' \n' && echo
```

Once you have generated a key, save it and move on to the next step.

#### Fill in your environment file

Open the file named `.env` that we created in a prior step using your favorite text editor.

Fill in this file with the following variables:

```txt
SECRET_KEY_BASE="replacemewiththegeneratedstringfromthepriorstep"
POSTGRES_PASSWORD="replacemewithyourdesireddatabasepassword"
```

### Step 3: Test your app

You are now ready to run the app. Start with the following command to make sure everything is working:

```bash
docker compose up
```

This will pull our official Docker image and start the app. You will see logs in your terminal.

Open your browser, and navigate to `http://localhost:3000`.

If everything is working, you will see the Maybe login screen.

### Step 4: Create your account

The first time you run the app, you will need to register a new account by hitting "create your account" on the login page.

1. Enter your email
2. Enter a password

### Step 5: Run the app in the background

Most self-hosting users will want the Maybe app to run in the background on their computer so they can access it at all times. To do this, hit `Ctrl+C` to stop the running process, and then run the following command:

```bash
docker compose up -d
```

The `-d` flag will run Docker Compose in "detached" mode. To verify it is running, you can run the following command:

```
docker compose ls
```

### Step 6: Enjoy!

Your app is now set up. You can visit it at `http://localhost:3000` in your browser.

If you find bugs or have a feature request, be sure to read through our [contributing guide here](https://github.com/maybe-finance/maybe/wiki/How-to-Contribute-Effectively-to-this-Project).

## How to update your app

The mechanism that updates your self-hosted Maybe app is the GHCR (Github Container Registry) Docker image that you see in the `docker-compose.yml` file:

```yml
image: ghcr.io/maybe-finance/maybe:latest
```

We recommend using one of the following images, but you can pin your app to whatever version you'd like (see [packages](https://github.com/maybe-finance/maybe/pkgs/container/maybe)):

- `ghcr.io/maybe-finance/maybe:latest` (latest commit)
- `ghcr.io/maybe-finance/maybe:stable` (latest release)

By default, your app _will
NOT_ automatically update. To update your self-hosted app, run the following commands in your terminal:

```bash
cd ~/docker-apps/maybe # Navigate to whatever directory you configured the app in
docker compose pull # This pulls the "latest" published image from GHCR
docker compose build app # This rebuilds the app with updates
docker compose up --no-deps -d app # This restarts the app using the newest version
```

## How to change which updates your app receives

If you'd like to pin the app to a specific version or tag, all you need to do is edit the `docker-compose.yml` file:

```yml
image: ghcr.io/maybe-finance/maybe:stable
```

After doing this, make sure and restart the app:

```bash
docker compose pull # This pulls the "latest" published image from GHCR
docker compose build app # This rebuilds the app with updates
docker compose up --no-deps -d app # This restarts the app using the newest version
```

## Troubleshooting

This section will provide troubleshooting tips and solutions for common issues
encountered during deployment. Check back later for updates!

