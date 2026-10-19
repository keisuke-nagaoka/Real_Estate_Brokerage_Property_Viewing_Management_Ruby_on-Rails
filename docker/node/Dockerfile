# フロントエンド(React + Vite)の開発用イメージ
FROM node:24-slim

# ホスト側のユーザーと同じUID/GIDで実行し、生成ファイルがroot所有にならないようにする
ARG UID=1000
ARG GID=1000
RUN if [ "${UID}" != "1000" ]; then \
      groupmod -g ${GID} node && usermod -u ${UID} -g ${GID} node && chown -R node:node /home/node; \
    fi && \
    mkdir -p /app/node_modules && chown -R node:node /app

USER node
WORKDIR /app
EXPOSE 5173
