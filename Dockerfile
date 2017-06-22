FROM quay.io/assemblyline/alpine:3.5

WORKDIR /app

COPY Gemfile Gemfile.lock .ruby-version ./

RUN apk add --no-cache --virtual .builddeps \
        build-base \
        ca-certificates \
        ruby$(cat .ruby-version) \
        ruby$(cat .ruby-version)-dev \
    && bundle install -j4 -r3 --deployment \
    && runDeps="$( \
      scanelf --needed --nobanner --recursive vendor \
        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
        | sort -u \
        | xargs -r apk info --installed \
        | sort -u \
      )" \
    && apk add --no-cache --virtual .rundeps \
        $runDeps \
        ruby$(cat .ruby-version) \
        ca-certificates \
        bash \
    && apk del --no-cache .builddeps

COPY . .
