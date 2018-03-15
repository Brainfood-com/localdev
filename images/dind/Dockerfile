ARG from
FROM ${from}

COPY healthcheck.sh /srv/localdev/scripts/healthcheck
COPY entrypoint.sh /srv/localdev/scripts/entrypoint
HEALTHCHECK --interval=15s CMD ["/srv/localdev/scripts/healthcheck"]
ENTRYPOINT ["/srv/localdev/scripts/entrypoint"]
