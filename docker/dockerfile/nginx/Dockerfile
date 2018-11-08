FROM nginx:latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nginx-extras \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

RUN rm /etc/nginx/sites-enabled/default