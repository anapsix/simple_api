# DOCKER-VERSION 0.5.3
FROM    ubuntu
MAINTAINER Anastas Semenov "asemenov@chitika.com"

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
# Install 
RUN apt-get install ruby1.9.1 ruby1.9.1-dev build-essential -y
RUN gem1.9.1 install sinatra json unicorn --no-ri --no-rdoc

# Bundle app source
#ADD . /srv/simple_api

#EXPOSE 8888:8888
#CMD ["/srv/simple_api/api_server.init", "restart"]
