FROM python:3.11.9-slim-bookworm AS builder

# 開啟 debug breakpoint、並顯示 env variable 的數值
RUN set -xe

WORKDIR /code
# 安裝 Poetry
RUN apt update \
    && apt install -y curl \
    && curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:$PATH"

COPY pyproject.toml poetry.lock ./
COPY AmasOryClient AmasOryClient

# COPY AmasAiotAuth AmasAiotAuth 暫時註解，日後用到再取消註解

# 使用 Poetry 安裝套件
RUN poetry config virtualenvs.create false \
    && poetry install --only main

# 第二階段：移除 Poetry
FROM python:3.11.9-slim-bookworm

WORKDIR /code

# 安裝系統相依套件
RUN apt update \
    && apt install -y python3-dev gcc libc-dev libffi-dev libpq-dev \
    nano vim \
    libssl-dev libcrypto++-dev \
    docker.io gnupg2 pass\
    gettext

# 複製第一階段的檔案
RUN set -xe
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin/gunicorn /usr/local/bin/gunicorn

# 複製應用程式檔案
COPY . .

# 設定環境變數
ENV PYTHONPATH="/usr/local/lib/python3.11/site-packages:${PYTHONPATH}"
ENV PATH="/usr/local/bin/gunicorn:$PATH"

EXPOSE 8009

CMD ["/bin/bash", "init.sh"]