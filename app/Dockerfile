FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY ./html /usr/share/nginx/html

COPY .conf /etc/nginx/nginx.conf

ENTRYPOINT ["nginx", "-g", "daemon off;"]
