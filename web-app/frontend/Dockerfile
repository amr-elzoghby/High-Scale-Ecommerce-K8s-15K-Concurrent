# =============================================================================
#  Frontend — Static File Server (httpd / Apache)
#  Serves HTML, CSS, JS, and images only — no reverse proxy
# =============================================================================

FROM httpd:2.4-alpine

# Remove the default Apache welcome page
RUN rm -rf /usr/local/apache2/htdocs/*

# Copy static web assets into the document root
COPY index.html  /usr/local/apache2/htdocs/
COPY css/        /usr/local/apache2/htdocs/css/
COPY js/         /usr/local/apache2/htdocs/js/
COPY images/     /usr/local/apache2/htdocs/images/

EXPOSE 80
