FROM node:latest
WORKDIR /usr/src/app
# COPY src/package*.json .
COPY . .
WORKDIR /usr/src/app/src
RUN npm install

EXPOSE 3000
CMD ["npm", "start"]