#!/bin/bash
set -euxo pipefail

apt-get update
apt-get install -y ca-certificates curl docker.io fontconfig openjdk-21-jre-headless gpg unzip

curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
unzip -q -o /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update

usermod -aG docker ubuntu
systemctl enable --now docker