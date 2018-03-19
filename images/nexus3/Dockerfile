ARG from
FROM ${from}

COPY healthcheck.py /srv/localdev/scripts/healthcheck
HEALTHCHECK --interval=15s CMD ["/srv/localdev/scripts/healthcheck"]
