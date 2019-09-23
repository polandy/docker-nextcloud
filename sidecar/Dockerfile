#FROM alpine:latest
FROM ruby:2.5.5-buster

MAINTAINER Andy Pollari <dev@pollari.ch>

RUN apt-get update
RUN apt-get install -y postgresql-client vim

# install docker
RUN wget 'https://get.docker.com/builds/Linux/x86_64/docker-1.11.0.tgz' \
 && tar -zxf docker-1.11.0.tgz \
 && mv docker/* /usr/local/bin/. \
 && chmod u+x /usr/local/bin/docker* \
 && rm -f docker-1.11.0.tgz
RUN /usr/local/bin/docker --version

RUN echo 'gem: --no-document' > /etc/gemrc

RUN gem install bundler

COPY . /app
WORKDIR /app
RUN bundle install

CMD ["ruby", "/app/main.rb"]
#ENTRYPOINT ["ruby", "/app/main.rb"]
