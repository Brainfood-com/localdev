# Getting Started

* Clone the repo: `git clone --recursive $REPO_URL`
* `docker-compose build`
* `docker-compose up -d`
* `docker-compose logs -f`, then wait; you'll want to see the line `Everything has been built and brought online; localdev is ready.`

# This project provides the following services to help local development

* nginx-proxy, listening on `:80` and `:443`
* `letsencrypt` for auto-creating SSL certificates for public hostnames.
* `squid`, answering on `http://http-proxy:3128/`
* `nexus`, a mirroring service for remote repositories
  * maven is supported
  * npm is supported

# Roadmap

* Add some sort of continuous integration
* Add email capture service.
