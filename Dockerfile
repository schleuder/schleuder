FROM ruby:2.4
MAINTAINER Friedrich Lindenberg <pudo@occrp.org>, Michał "rysiek" Woźniak <rysiek@occrp.org>
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y \
    libmagic-dev \
    libgpgme11-dev \
    wget \
    git \
    git-core \
    inotify-tools \
    --no-install-recommends && rm -rf /var/lib/apt/lists/*

# install schleuder
WORKDIR /opt/schleuder
ADD . /opt/schleuder
RUN cd /opt/schleuder && \
    bundle install

# get and install schleuder-cli
# not required, but helpful for CLI-based list administration
RUN git clone https://0xacab.org/schleuder/schleuder-cli.git /opt/schleuder-cli && \
    cd /opt/schleuder-cli && \
    bundle install

# entrypoint script
COPY docker/entrypoint.sh /sbin/entrypoint.sh
RUN chmod a+x /sbin/entrypoint.sh

# we need to be able to mount the code into other containers
# like the SMTPD container
# so that schleuder work can be run if needed
VOLUME ["/usr/local/bundle", "/etc/schleuder", "/var/lib/schleuder/lists"]

# final config
EXPOSE 4443
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["schleuder-api-daemon"]
