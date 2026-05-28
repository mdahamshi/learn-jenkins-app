# using jenkins already built app
FROM nginx:alpine
COPY build/ /usr/share/nginx/html
EXPOSE 80