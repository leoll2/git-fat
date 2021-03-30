#!/bin/sh -l

cp git-fat /usr/local/bin/git-fat

git config --global user.email "test@test.com"
git config --global user.name "test test"

./run_test.py
