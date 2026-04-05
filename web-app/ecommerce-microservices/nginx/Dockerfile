FROM nginx:stable-alpine


RUN rm /etc/nginx/conf.d/default.conf


COPY frontend/index.html   /usr/share/nginx/html/
COPY frontend/css/        /usr/share/nginx/html/css/
COPY frontend/js/         /usr/share/nginx/html/js/
COPY frontend/images/     /usr/share/nginx/html/images/


COPY nginx/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
