ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_ARCH
ARG FRP_VERSION

COPY bootstrap.sh /
COPY run.sh      /

RUN chmod +x /bootstrap.sh /run.sh \
 && /bootstrap.sh $BUILD_ARCH $FRP_VERSION

ENTRYPOINT [ "/run.sh" ]
