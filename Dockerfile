FROM ubuntu

ADD git-fat /usr/local/bin/git-fat
ADD test.sh .

RUN apt-get update -qq \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends python3 python3-pip python3-setuptools git curl groff less rsync \
  && pip3 install wheel --upgrade --user \
  && pip3 install awscli --upgrade --user \
  && pip3 install awscli-plugin-endpoint --upgrade --user \
  && ln -s /root/.local/bin/aws /usr/local/bin/aws \
  && curl -L https://dl.min.io/server/minio/release/linux-amd64/minio -o /usr/local/bin/minio \
  && chmod +x /usr/local/bin/minio \
  && git config --global user.email "test@test.com" \
  && git config --global user.name "test test"
