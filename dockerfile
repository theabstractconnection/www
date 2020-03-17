FROM node:13.10.1-alpine

RUN yarn global add http-server

WORKDIR /app

COPY package*.json ./
RUN yarn

COPY . .
RUN yarn run build