FROM alpine:3.20

RUN apk add --no-cache openssh-client rsync bash

COPY pull.sh /app/pull.sh
COPY pull.conf /app/pull.conf

RUN chmod +x /app/pull.sh \
  && adduser -D -u 1000 pull \
  && mkdir -p /outputs /home/pull/.ssh \
  && chown -R pull:pull /home/pull /outputs

USER pull
WORKDIR /app

ENTRYPOINT ["/app/pull.sh"]
