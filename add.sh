#!/bin/sh

while [[ ! "$subdomain" =~ ^[a-zA-Z0-9-]+$ ]]; do
  echo
  echo "Enter the name of the 1st subdomain where your Nightscout will be available:"
  read subdomain
done
secret=$(cat /proc/sys/kernel/random/uuid)

cat >> docker-compose.yml <<EOF

  nightscout-${subdomain}:
    image: mmountrcg/cgm-remote-monitor:latest_dev
    container_name: ${subdomain}
    restart: always
    depends_on:
      - mongo
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.${subdomain}.rule=Host(\`${subdomain}.\${NS_DOMAIN}\`)'
      - 'traefik.http.routers.${subdomain}.entrypoints=web'
      - 'traefik.http.routers.${subdomain}.entrypoints=websecure'
      - 'traefik.http.routers.${subdomain}.tls.certresolver=le'
    environment:
      <<: *ns-common-env
      CUSTOM_TITLE: ${subdomain}
      AUTH_DEFAULT_ROLES: readable
      API_SECRET: '${secret}'
      MONGO_CONNECTION: mongodb://mongo:27017/${subdomain}
      ENABLE: basal bridge iob cob boluscalc cage sage iage bage pump openaps bgi food rawbg dbsize
      SHOW_PLUGINS: iob cob careportal basal override sage cage openaps dbsize

EOF

sudo docker compose up -d

echo "URL: $subdomain.$domain"
echo "API_SECRET: $secret"
echo
echo "You can view and edit your API_SECRET and other configurations by 'nano docker-compose.yml'"
echo "Email and domain variables are stored in '.env'"
echo
echo "To add more Nightscout instances, please run 'bash <(wget -qO- https://raw.githubusercontent.com/mountrcg/ns-setup/bo-multi/add.sh)'"
echo "To add a NS-Reporter Grafana Dashboard , please run 'bash <(wget -qO- https://raw.githubusercontent.com/mountrcg/ns-setup/bo-multi/add-reporter.sh)'"
echo
echo "After editing settings, re-launch your Nightscout by typing 'sudo docker compose up -d'"