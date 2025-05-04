ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_ARCH
ARG FRP_VERSION

# Установим зависимости
RUN apk add --no-cache bash jq curl

# Скопируем скрипты и запустим bootstrap
COPY bootstrap.sh /
COPY run.sh /

RUN chmod +x /bootstrap.sh /run.sh \
 && /bootstrap.sh $BUILD_ARCH $FRP_VERSION

CMD [ "/run.sh" ]
