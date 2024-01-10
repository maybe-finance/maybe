#!/bin/bash

# Go to home directory
cd /home/ubuntu

# Install necessary packages
apt-get update 
apt-get install unzip jq -y 
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install 
export PATH="$(which aws):$PATH"
source ~/.bashrc
aws --version

# Initializes the Github runner
export RUNNER_ALLOW_RUNASROOT="1" # This allows the root user to set everything up
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.291.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.291.1/actions-runner-linux-x64-2.291.1.tar.gz
echo "1bde3f2baf514adda5f8cf2ce531edd2f6be52ed84b9b6733bf43006d36dcd4c  actions-runner-linux-x64-2.291.1.tar.gz" | shasum -a 256 -c
tar xzf ./actions-runner-linux-x64-2.291.1.tar.gz

# Grabs Github API key from Secure SSM param
# Make sure there is a secure parameter called '/github/api-token' in format githubusername:githubpersonalaccesstoken (with "repo" scopes enabled)
GITHUB_API_TOKEN=$(aws ssm get-parameter --name /github/api-token --region us-west-2 --with-decryption | jq -r '.Parameter.Value')

# Uses token to get a runner registration token, which is used to configure the runner
ADD_RUNNER_TOKEN=$(curl -u $GITHUB_API_TOKEN \
    -X POST \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/maybe-finance/maybe-app/actions/runners/registration-token | jq -r '.token')

./config.sh --url https://github.com/maybe-finance/maybe-app --labels aws --unattended --token $ADD_RUNNER_TOKEN 

./svc.sh install  

# Install Node v.16.15 and yarn
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

nvm install v16.15.0
nvm use v16.15.0
nvm alias default v16.15.0
npm install -g yarn

# Need to add these binaries to the runner's `.path` file, which is what the runner uses to locate packages
# https://github.com/actions/setup-node/issues/182#issuecomment-718233039
echo $PATH > .path 
echo -n ":/home/ubuntu/.nvm/versions/node/v16.15.0/bin" >> .path

# Install Docker
apt-get update
apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

# https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user
# Give non-root user ability to run docker commands
usermod -aG docker ubuntu 
newgrp docker

# Start the Github runner as a service 
sudo ./svc.sh start
