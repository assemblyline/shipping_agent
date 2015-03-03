FROM quay.io/assemblyline/ruby:2.1.5

WORKDIR /usr/src/shipping_agent
COPY Gemfile ./
COPY Gemfile.lock ./

RUN bundle install --jobs=3 --retry=3

COPY . ./
