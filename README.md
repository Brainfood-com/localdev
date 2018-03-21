# Getting Started

* Clone the repo
* `docker-compose build`
* `docker-compose up -d`
* `docker-compose logs -f`, then wait

# This project provides the following services to help local development

* nginx-proxy, listening on `:80` and `:443`
* `letsencrypt` for auto-creating SSL certificates for public hostnames.
* `nexus`, a mirroring service for remote repositories; currently, maven is 100% working.

# Roadmap

* Add `squid`, or configure nexus/raw.
* Configure nexus/npm.
* Add some sort of continuous integration

