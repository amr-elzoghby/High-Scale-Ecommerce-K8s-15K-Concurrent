FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json .

RUN npm install

COPY . .

FROM node:18-alpine

WORKDIR /app

COPY package*.json .

RUN npm ci --omit=dev

COPY --from=builder /app .

USER node

COPY --chown=node:node . .

EXPOSE 3001

CMD ["node","server.js"]