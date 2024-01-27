ARG BASE_IMAGE=quay.io/centos/centos:stream9

FROM $BASE_IMAGE as squidclamav
USER root
COPY compile.sh /
RUN /compile.sh

FROM $BASE_IMAGE as c-icap

COPY --from=squidclamav /squidclamav.so /usr/lib64/c_icap/squidclamav.so
#COPY squidclamav.so /usr/lib64/c_icap/squidclamav.so
COPY /install /

RUN /install.sh && \
  rm -f /install

EXPOSE 1344 11344

ENTRYPOINT ["/entrypoint.sh"]

USER 1000
