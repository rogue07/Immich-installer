# ram
# 23 jun, 2024

# Immich full installer
# v1.1


#!/bin/bash

# Prompt for the domain name
read -p "Enter your sub domain name (e.g., me.moooo.com): " DOMAIN_NAME

# Install the basics
sudo apt update -y
sudo apt upgrade -y
sudo apt install vim fail2ban curl openssh-server nginx certbot python3-certbot-nginx -y

# Install packages to allow apt to use a repository over HTTPS
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Set up the stable repository
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Update the apt package index again
sudo apt update -y

# Install the latest version of Docker Engine and containerd
sudo apt install docker-ce docker-ce-cli containerd.io -y

# Verify that Docker Engine is installed correctly
sudo docker run hello-world

# Check the Docker version
docker --version

mkdir ./immich-app
cd ./immich-app

wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
wget -O hwaccel.transcoding.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml
wget -O hwaccel.ml.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.ml.yml


# Upgrade Immich
docker compose pull


# Fix to transfer larger files
sudo python3 FileSize_Update.py

# Check if the Python script ran successfully
if [ $? -eq 0 ]; then
    echo "Python script executed successfully."
else
    echo "Python script failed."
fi

# Continue with the rest of your shell script
echo "Continuing with the rest of the shell script."



# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Check Nginx status
sudo systemctl status nginx

# Create the necessary directories
sudo mkdir -p /var/www/$DOMAIN_NAME/html

# Set permissions
sudo chown -R $USER:$USER /var/www/$DOMAIN_NAME/html
sudo chmod -R 755 /var/www

# Create necessary directories for Nginx configuration
sudo mkdir -p /etc/nginx/sites-available
sudo mkdir -p /etc/nginx/sites-enabled

# Define the file path
FILE_PATH="/etc/nginx/sites-available/$DOMAIN_NAME"

# Server block configuration content to be added
SERVER_BLOCK="
server {
    listen 80;
    listen [::]:80;

    # replace with your domain or subdomain
    server_name $DOMAIN_NAME;

    # https://github.com/immich-app/immich/blob/main/nginx/templates/default.conf.template#L28
    client_max_body_size 50000M;

    location / {
        proxy_pass http://localhost:2283;
        proxy_set_header Host              \\\$http_host;
        proxy_set_header X-Real-IP         \\\$remote_addr;
        proxy_set_header X-Forwarded-For   \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;

        # http://nginx.org/en/docs/http/websocket.html
        proxy_http_version 1.1;
        proxy_set_header   Upgrade    \\\$http_upgrade;
        proxy_set_header   Connection \"upgrade\";
        proxy_redirect off;
    }
}"

# Create or overwrite the file with the server block configuration
echo "$SERVER_BLOCK" | sudo tee $FILE_PATH > /dev/null

# Check if the file creation was successful
if [ $? -eq 0 ]; then
  echo "File $FILE_PATH created successfully!"
else
  echo "Failed to create file $FILE_PATH."
fi

# Create a symbolic link to enable the site
sudo ln -s /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/

# Allow traffic on ports 80 and 443
sudo ufw allow 80
sudo ufw allow 443

# Reload Nginx to apply the changes
sudo systemctl reload nginx

# Obtain SSL certificate using Certbot
sudo certbot --nginx -d $DOMAIN_NAME


