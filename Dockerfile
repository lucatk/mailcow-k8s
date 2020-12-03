FROM docker:stable

RUN apk add --no-cache bash git py-pip python3-dev libffi-dev openssl-dev gcc libc-dev make

RUN pip install docker-compose
#COPY --from=docker/compose:alpine-1.27.4 /usr/local/bin/docker-compose /usr/local/bin/

RUN git clone https://github.com/mailcow/mailcow-dockerized /src

RUN mkdir /project
WORKDIR /project

COPY startup.sh startup.sh
RUN chmod +x startup.sh

RUN apk add --no-cache grep coreutils openssl curl

VOLUME /opt/mailcow

ENTRYPOINT ["/project/startup.sh"]
