ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_ARCH
ARG FRP_VERSION

# Устанавливаем утилиты
RUN apk add --no-cache bash jq curl

COPY bootstrap.sh /
COPY run.sh      /

RUN chmod +x /bootstrap.sh /run.sh \
 && /bootstrap.sh $BUILD_ARCH $FRP_VERSION

CMD [ "/run.sh" ]
