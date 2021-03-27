FROM ubuntu

COPY entrypoint.sh /entrypoint.sh

RUN apt-get update -qq && apt-get upgrade -y && apt-get install -y software-properties-common && add-apt-repository universe

RUN apt-get install -y --no-install-recommends \
  curl \
  git \
  groff \
  less \
  python-dev \
  python3-pip \
  rsync \
  unzip \
  wamerican \
  && rm -rf /var/lib/apt/lists/*

# pip2
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py \
  && python2 get-pip.py

RUN pip2 install --upgrade --user \
  awscli \
  awscli-plugin-endpoint

RUN pip3 install --upgrade --user \
  awscli \
  awscli-plugin-endpoint

RUN ln -s /root/.local/bin/aws /usr/local/bin/aws

# MinIO, self-hosted S3 storage
RUN curl -L https://dl.min.io/server/minio/release/linux-amd64/minio -o /usr/local/bin/minio \
  && chmod +x /usr/local/bin/minio

# rclone
RUN curl https://rclone.org/install.sh | bash

RUN git config --global user.email "test@test.com" \
  && git config --global user.name "test test"

ENTRYPOINT ["/entrypoint.sh"]
