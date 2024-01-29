ARG BASE_IMAGE=registry.access.redhat.com/ubi9/ubi-minimal

FROM $BASE_IMAGE as compile
ARG C_ICAP_VERSION=0.6.2
ARG SQUIDCLAM_VERSION=7.3
ARG LINUX_UPDATE=yes
ARG SPECIAL_CURL_ARGS=

USER root
COPY container_compile /
RUN /compile.sh

FROM $BASE_IMAGE as c-icap
ARG CONTAINER_IMAGE_VERSION=
ARG C_ICAP_VERSION=0.6.2
ARG SQUIDCLAM_VERSION=7.3
ARG LINUX_UPDATE=yes
ARG SPECIAL_CURL_ARGS=


COPY --from=compile /libicapapi.so /usr/lib64/libicapapi.so
COPY --from=compile /c-icap /usr/bin/c-icap
COPY --from=compile /c-icap-client /usr/bin/c-icap-client
COPY --from=compile /srv_echo.so /usr/lib64/c_icap/srv_echo.so
COPY --from=compile /squidclamav.so /usr/lib64/c_icap/squidclamav.so

#COPY squidclamav.so /usr/lib64/c_icap/squidclamav.so

COPY container_install /
RUN /install.sh && \
  rm -f /install

EXPOSE 1344 11344

HEALTHCHECK --interval=120s --timeout=10s --start-period=60s CMD /healthcheck.sh

ENTRYPOINT ["/entrypoint.sh"]

USER 1000

