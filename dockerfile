# THIS SPECIFIC FILE IS DISTRIBUTED UNDER THE UNLICENSE: http://unlicense.org.
# 
# YOU CAN FREELY USE THIS CODE EXAMPLE TO KICKSTART A PROJECT OF YOUR OWN.
# FEEL FREE TO REPLACE OR REMOVE THIS HEADER.
FROM node:13.10.1-alpine as base
RUN apk update
RUN apk --no-cache add shadow && \
    usermod -u 2000 node && \
    groupmod -g 2000 node && \
    find / -group 1000 -exec chgrp -h node {} && \
    find / -user 1000 -exec chown -h node {}

FROM scratch as user
COPY --from=base . .
ARG HOST_UID=${HOST_UID:-4000}
ARG HOST_USER=${HOST_USER:-nodummy}
RUN [ "${HOST_USER}" == "root" ] || \
    (adduser -h /home/${HOST_USER} -D -u ${HOST_UID} ${HOST_USER} \
    && chown -R "${HOST_UID}:${HOST_UID}" /home/${HOST_USER})

USER ${HOST_USER}
WORKDIR /home/${HOST_USER}

RUN yarn global add http-server
COPY package*.json ./
RUN yarn
COPY . .
RUN yarn run build