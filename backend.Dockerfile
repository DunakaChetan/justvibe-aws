FROM node:20-alpine

WORKDIR /app

RUN apk add --no-cache git \
  && git clone https://github.com/DunakaChetan/justvibe-backend-docker.git .

RUN npm install --production

ENV NODE_ENV=production
ENV PORT=8080

EXPOSE 8080

CMD ["node", "server.js"]

