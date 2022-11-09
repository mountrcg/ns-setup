#!/bin/sh

while [[ ! "$subdomain" =~ ^[a-zA-Z0-9-]+$ ]]; do
  echo "Enter the name of the subdomain where your Nightscout will be available:"
  read subdomain
done
secret=$(cat /proc/sys/kernel/random/uuid)

cat >> docker-compose.yml <<EOF

  nightscout-${subdomain}:
    image: bjornoleh/nightscout:latest
    container_name: nightscout-${subdomain}
    restart: always
    depends_on:
      - mongo
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.nightscout-${subdomain}.rule=Host(\`${subdomain}.\${NS_DOMAIN}\`)'
      - 'traefik.http.routers.nightscout-${subdomain}.entrypoints=web'
      - 'traefik.http.routers.nightscout-${subdomain}.entrypoints=websecure'
      - 'traefik.http.routers.nightscout-${subdomain}.tls.certresolver=le'
    environment:
      <<: *ns-common-env
      CUSTOM_TITLE:
      API_SECRET: '${secret}'
      BRIDGE_USER_NAME:
      BRIDGE_PASSWORD:
      MONGO_CONNECTION: mongodb://mongo:27017/ns-${subdomain}

EOF

sudo docker compose up -d

echo "URL: $subdomain.${NS_DOMAIN}"
echo "secret: $secret"
echo
echo "You can view your API_SECRET and edit configurations by 'nano docker-compose.yml'"
echo "Email and domain variables are stored in '.env'"
echo
echo "To add more Nightscout instances, please run 'sudo bash <(wget -qO- https://raw.githubusercontent.com/bjornoleh/ns-setup/bo-multi/add.sh)'"
echo
echo "After editing settings, re-launch your Nightscout by typing 'sudo docker compose up -d'"