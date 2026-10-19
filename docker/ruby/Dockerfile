# 開発用イメージ。ソースはbind mountし、gemは名前付きボリューム(/usr/local/bundle)に保持する
FROM ruby:3.4-slim

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential default-libmysqlclient-dev default-mysql-client \
      git libyaml-dev pkg-config curl tzdata libvips42t64 && \
    rm -rf /var/lib/apt/lists/*

# ホスト側のユーザーと同じUID/GIDで実行し、rails g 等で生成したファイルがroot所有にならないようにする
ARG UID=1000
ARG GID=1000
RUN groupadd -g ${GID} app && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash app && \
    chown -R app:app /usr/local/bundle

ENV TZ=Asia/Tokyo \
    LANG=C.UTF-8

USER app
WORKDIR /app
EXPOSE 3000
