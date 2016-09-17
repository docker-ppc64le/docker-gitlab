FROM ppc64le/debian:jessie
MAINTAINER sameer@damagehead.com

ENV GITLAB_VERSION=8.11.5 \
    RUBY_VERSION=2.1 \
    GOLANG_VERSION=1.5.3 \
    GITLAB_SHELL_VERSION=3.4.0 \
    GITLAB_WORKHORSE_VERSION=0.7.11 \
    GITLAB_USER="git" \
    GITLAB_HOME="/home/git" \
    GITLAB_LOG_DIR="/var/log/gitlab" \
    GITLAB_CACHE_DIR="/etc/docker-gitlab" \
    RAILS_ENV=production

ENV GITLAB_INSTALL_DIR="${GITLAB_HOME}/gitlab" \
    GITLAB_SHELL_INSTALL_DIR="${GITLAB_HOME}/gitlab-shell" \
    GITLAB_WORKHORSE_INSTALL_DIR="${GITLAB_HOME}/gitlab-workhorse" \
    GITLAB_DATA_DIR="${GITLAB_HOME}/data" \
    GITLAB_BUILD_DIR="${GITLAB_CACHE_DIR}/build" \
    GITLAB_RUNTIME_DIR="${GITLAB_CACHE_DIR}/runtime"

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y sudo supervisor logrotate locales curl \
      openssh-server mysql-client postgresql-client redis-tools \
      git-core ruby python2.7 python-docutils gettext-base \
      libmysqlclient18 libpq5 zlib1g libyaml-0-2 libssl1.0.0 \
      libgdbm3 libreadline6 libncurses5 libffi6 \
      libxml2 libxslt1.1 libcurl3 libicu52 

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -t jessie-backports nginx \
 && update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
 && locale-gen en_US.UTF-8 \
 && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales \
 && gem install --no-document bundler \
 && rm -rf /var/lib/apt/lists/*

RUN curl https://nodejs.org/dist/v6.6.0/node-v6.6.0-linux-ppc64le.tar.gz | tar xz \
 && cp node-v6.6.0-linux-ppc64le/bin/node /usr/local/bin \
 && cp node-v6.6.0-linux-ppc64le/bin/npm /usr/local/bin

COPY assets/build/ ${GITLAB_BUILD_DIR}/
RUN bash ${GITLAB_BUILD_DIR}/install.sh

COPY assets/runtime/ ${GITLAB_RUNTIME_DIR}/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 22/tcp 80/tcp 443/tcp

VOLUME ["${GITLAB_DATA_DIR}", "${GITLAB_LOG_DIR}"]
WORKDIR ${GITLAB_INSTALL_DIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:start"]
