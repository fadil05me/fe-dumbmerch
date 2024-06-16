FROM node:16-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

FROM node:16-alpine

WORKDIR /app

COPY --from=build /app .

RUN npm install --only=production

EXPOSE 3000

CMD ["npm", "start"]
