FROM node:20-alpine AS builder
WORKDIR /app

ARG API_BASE_URL=http://3.237.21.254:8080

RUN apk add --no-cache git \
  && git clone https://github.com/DunakaChetan/justvibe-docker.git .

RUN npm install
RUN printf "VITE_API_BASE_URL=%s\n" "$API_BASE_URL" > .env.production \
  && npm run build

FROM nginx:alpine
WORKDIR /usr/share/nginx/html

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.docker.conf /etc/nginx/conf.d/default.conf

COPY --from=builder /app/dist ./

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

