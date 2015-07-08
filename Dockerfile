FROM debian
MAINTAINER R.I.Pienaar "rip@devco.net"

RUN apt-get update && apt-get install -y \
    ruby2.1 bundler git curl && \
    update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby2.1 1

RUN curl -SL https://github.com/ripienaar/docker_registry_maintainer/archive/master.tar.gz | tar -xzC /srv

WORKDIR /srv/docker_registry_maintainer-master

RUN bundle install

ENTRYPOINT ["bin/mainain_repositories.rb"]
