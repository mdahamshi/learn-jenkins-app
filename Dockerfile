# Stage 1 — Builder
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci          # install dependencies
COPY . .
RUN npm run build   # produces /app/build folder (HTML/CSS/JS)

# Stage 2 — Final image
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80