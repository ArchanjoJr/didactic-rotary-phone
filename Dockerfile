FROM node:latest
WORKDIR /usr/src/app
# COPY src/package*.json .
COPY . .
WORKDIR /usr/src/app/src
RUN npm install

EXPOSE 3000

RUN apt-get update && apt-get install -y --no-install-recommends curl

HEALTHCHECK CMD curl --fail http://localhost:3000/status || exit 1

CMD ["npm", "start"]