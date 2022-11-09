#!/bin/sh

while [[ ! "$domain" =~ ^[a-zA-Z0-9-]+$ ]]; do
  echo "Enter the name of the subdomain where your Nightscout will be available:"
  read domain
done
secret=$(cat /proc/sys/kernel/random/uuid)

cat >> docker-compose.yml <<EOF

  nightscout-${domain}:
    image: bjornoleh/nightscout:latest
    container_name: nightscout-${domain}
    restart: always
    depends_on:
      - mongo
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.nightscout-${domain}.rule=Host(\`${domain}.\${NS_DOMAIN}\`)'
      - 'traefik.http.routers.nightscout-${domain}.entrypoints=web'
      - 'traefik.http.routers.nightscout-${domain}.entrypoints=websecure'
      - 'traefik.http.routers.nightscout-${domain}.tls.certresolver=le'
    environment:
      <<: *ns-common-env
      MONGO_CONNECTION: mongodb://mongo:27017/ns-${domain}
      API_SECRET: '${secret}'
EOF

docker-compose up -d

echo "domain: $domain"
echo "secret: $secret"
