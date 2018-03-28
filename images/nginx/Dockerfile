FROM nginx

COPY files /tmp/files
RUN ["/tmp/files/configure"]

ENTRYPOINT ["/srv/localdev/scripts/entrypoint"]
HEALTHCHECK --interval=15s CMD ["/srv/localdev/scripts/healthcheck"]

