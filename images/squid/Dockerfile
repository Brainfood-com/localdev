FROM debian:stretch

EXPOSE 3128

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y squid \
	&& apt-get clean \
	&& find /var/cache/apt /var/lib/apt -type f -delete \
	&& true

RUN mkdir /etc/squid/squid.conf.d

ENV SQUID_cache_dir_size 10240
COPY entrypoint.sh /srv/localdev/scripts/entrypoint

ENTRYPOINT ["/srv/localdev/scripts/entrypoint"]
