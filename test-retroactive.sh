#!/bin/bash 

set -eux

fullpath() { echo "$(pwd)/$1"; }

git init retro
pushd retro
cp /usr/share/dict/words words.big
chmod u+w words.big
git add words.big
git commit -m'Add big file without using git-fat'
sort words.big > sorted.big
git add sorted.big
git commit -m'Add sorted file without using git-fat'
cat > .gitattributes <<EOF
original-attributes -text
EOF
git add .gitattributes
echo 'truncated' > words.big
git commit -am'Truncated words.big and add .gitattributes'
git fat init
cat > .gitattributes <<EOF
*.big filter=fat -text
EOF
git add .gitattributes
git checkout .
git commit -am'Import big files into git-fat'

git log --stat

git fat find 10000 | awk '{print $1}' > fat-files
git filter-branch --index-filter "git fat index-filter $(fullpath fat-files) --manage-gitattributes" --tag-name-filter cat -- --all

git log --stat
git checkout HEAD^
rm ./*
git checkout .
ls -al

# Set up place to push
git checkout master
cat > .gitfat <<EOF
[rsync]
remote = $(fullpath ../retro-store)
EOF
git add .gitfat
git commit -m'Add .gitfat for local push'
git fat push

popd
git clone "file:///$(fullpath retro)" retro-clone
pushd retro-clone
git fat init
git fat pull
popd
