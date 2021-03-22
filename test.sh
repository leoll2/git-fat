#! /usr/bin/env bash

set -eux

function run_integration_test() {
  rm -rf fat-test fat-test2 /tmp/fat-store
  git init fat-test

  pushd fat-test
  {
    git fat init
    mv ../.gitfat .
    echo '*.fat filter=fat -crlf' >.gitattributes
    git add .gitattributes .gitfat
    git commit -m 'initial fat repository'

    ln -s /oe/dss-oe/dss-add-ons-testing-build/deploy/licenses/common-licenses/GPL-3 c
    git add c
    git commit -m 'add broken symlink'
    echo 'fat content a' >a.fat
    git add a.fat
    git commit -m 'add a.fat'
    echo 'fat content b' >b.fat
    git add b.fat
    git commit -m 'add b.fat'
    echo 'revise fat content a' >a.fat
    git commit -am 'revise a.fat'
    git fat push
  }
  popd

  git clone fat-test fat-test2
  pushd fat-test2
  {
    # checkout and pull should fail in repo not yet init'ed for git-fat
    git fat checkout && true
    if [ $? -eq 0 ]; then
      echo 'ERROR: "git fat checkout" in uninitialized repo should fail'
      exit 1
    fi
    git fat pull -- 'a.fa*' && true
    if [ $? -eq 0 ]; then
      echo 'ERROR: "git fat pull" in uninitialized repo should fail'
      exit 1
    fi
    git fat init
    git fat pull -- 'a.fa*'
    cat a.fat
    echo 'file which is committed and removed afterwards' >d
    git add d
    git commit -m 'add d with normal content'
    rm d
    git fat pull

    # Check verify command finds corrupt object
    mv .git/fat/objects/6e/cec2e21d3033e7ba53e2db63f69dbd3a011fa8 \
      .git/fat/objects/6e/cec2e21d3033e7ba53e2db63f69dbd3a011fa8.bak
    echo "Not the right data" >.git/fat/objects/6ecec2e21d3033e7ba53e2db63f69dbd3a011fa8
    git fat verify && true
    if [ $? -eq 0 ]; then
      echo "Verify did not detect invalid object"
      exit 1
    fi
    mv .git/fat/objects/6e/cec2e21d3033e7ba53e2db63f69dbd3a011fa8.bak \
      .git/fat/objects/6e/cec2e21d3033e7ba53e2db63f69dbd3a011fa8
  }
  popd
}

## ________________________________________
## RSYNC integration tests
echo "
[rsync]
remote = /tmp/fat-store
" | tee .gitfat
run_integration_test
rm -rf /tmp/fat-store

## ________________________________________
## RCLONE integration tests
mkdir -p /tmp/fat-store
echo "
[rclone]
remotedir = /tmp/fat-store
type = local
nounc = true
" | tee .gitfat
run_integration_test
rm -rf /tmp/fat-store

## ________________________________________
## AWS S3 integration tests
export AWS_ACCESS_KEY_ID=fat-test
export AWS_SECRET_ACCESS_KEY=fat-test
export AWS_DEFAULT_REGION=us-east-1
export MINIO_ACCESS_KEY=${AWS_ACCESS_KEY_ID}
export MINIO_SECRET_KEY=${AWS_SECRET_ACCESS_KEY}

pidof minio || nohup minio server /tmp/miniodata &
sleep 1

mkdir -p ~/.aws
echo "
[default]
aws_access_key_id = ${AWS_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
" | tee ~/.aws/credentials
echo "
[default]
region = us-east-1
s3 =
    endpoint_url=http://localhost:9000
    signature_version = s3v4
s3api =
    endpoint_url=http://localhost:9000

[plugins]
endpoint = awscli_plugin_endpoint
" | tee ~/.aws/config
aws s3 rb --force s3://test-bucket || true
aws s3 mb s3://test-bucket
echo "
[s3]
bucket = test-bucket
" | tee .gitfat
run_integration_test

pkill minio
