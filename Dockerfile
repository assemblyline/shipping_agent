FROM quay.io/assemblyline/ruby:2.3.1

WORKDIR /usr/local/a10e.org/shipping_agent
COPY Gemfile ./
COPY Gemfile.lock ./

RUN bundle install --jobs=3 --retry=3

COPY . ./
