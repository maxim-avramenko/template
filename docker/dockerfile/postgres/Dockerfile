FROM postgres

COPY ./utils /utils

RUN chmod +x -R /utils

RUN apt-get update && apt-get install -y \
    nano \
    zip \
    unzip \
    bsdmainutils \
    apt-utils\
    lbzip2 \
    libyaml-dev \
    libpython3-dev \
    python3-pip \
    curl \
    python3-swiftclient