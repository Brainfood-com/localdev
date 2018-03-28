ARG from
FROM ${from}

COPY healthcheck /srv/localdev/scripts/healthcheck
COPY entrypoint /srv/localdev/scripts/entrypoint
HEALTHCHECK --interval=15s CMD ["/srv/localdev/scripts/healthcheck"]
ENTRYPOINT ["/srv/localdev/scripts/entrypoint"]
