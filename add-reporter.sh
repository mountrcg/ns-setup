#!/bin/sh

while [[ ! "$subdomain" =~ ^[a-zA-Z0-9-]+$ ]]; do
  echo
  echo "Enter the name of the subdomain where your NS-Reporter will be available:"
  read subdomain
done
secret=$(cat /proc/sys/kernel/random/uuid)

cat >> docker-compose.yml <<EOF

grafana-${subdomain}:
	image: grafana/grafana-oss:latest
	container_name: grafana-${subdomain}
	restart: always
	depends_on:
		- influx-${subdomain}
	volumes:
		- data-grafana-ns:/var/lib/grafana
	labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.grafana-${subdomain}.rule=Host(\`${subdomain}.\${NS_DOMAIN}\`)'
      - 'traefik.http.routers.grafana-${subdomain}.entrypoints=web'
      - 'traefik.http.routers.grafana-${subdomain}.entrypoints=websecure'
      - 'traefik.http.routers.grafana-${subdomain}.tls.certresolver=le'
	ports:
		- 3000:3000

influx-${subdomain}:
	image: influxdb:latest
	container_name: influx-${subdomain}
	restart: always
	volumes:
		- data-influx-ns:/var/lib/influxdb2
labels:
	- 'traefik.enable=true'
	- 'traefik.http.routers.influx-${subdomain}.rule=Host(\`${subdomain}.\${NS_DOMAIN}\`)'
	- 'traefik.http.routers.influx-${subdomain}.entrypoints=web'
	- 'traefik.http.routers.influx-${subdomain}.entrypoints=websecure'
	- 'traefik.http.routers.influx-${subdomain}.tls.certresolver=le'
	ports:
		- 8086:8086

ns-${subdomain}:
	image: ns-exporter:latest
	container_name: ns-${subdomain}
	restart: unless-stopped
	environment:
		- NS_EXPORTER_MONGO_URI=${NS_EXPORTER_MONGO_URI:-mongodb://mongo:27017}
		- NS_EXPORTER_MONGO_DB=${NS_EXPORTER_MONGO_DB:-ns-rcg-loop}
		- NS_EXPORTER_INFLUX_URI=${NS_EXPORTER_INFLUX_URI:-http://influx-${subdomain}:8086}
		- NS_EXPORTER_INFLUX_TOKEN=${NS_EXPORTER_INFLUX_TOKEN?err}
		- NS_EXPORTER_LIMIT=3
		- NS_EXPORTER_SKIP=0
	depends_on:
		- influx-${subdomain}
	#    - mongo

EOF

sudo docker compose up -d

echo "After editing settings, re-launch your Nightscout by typing 'sudo docker compose up -d'"