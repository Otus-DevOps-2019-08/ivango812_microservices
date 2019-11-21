FROM ubuntu:16.04 

RUN apt-get update \
    && apt-get install -y --no-install-recommends ruby2.3 ruby2.3-dev build-essential \ 
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && gem install bundler:2.0.2 --no-ri --no-rdoc

ENV APP_HOME /app
RUN mkdir $APP_HOME 
WORKDIR $APP_HOME
COPY Gemfile* $APP_HOME/ 
RUN bundle install
COPY . $APP_HOME
ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment 
ENV COMMENT_SERVICE_PORT 9292 

CMD ["puma"]
