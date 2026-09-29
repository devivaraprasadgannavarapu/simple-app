#!/bin/bash
set -euxo pipefail

apt-get update
apt-get install -y ca-certificates curl fontconfig gpg docker.io unzip

curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
unzip -q -o /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update

install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key | tee /etc/apt/keyrings/jenkins-keyring.asc >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" >/etc/apt/sources.list.d/jenkins.list
apt-get update
apt-get install -y fontconfig openjdk-21-jre-headless jenkins

curl -fsSL https://dl.k8s.io/release/stable.txt -o /tmp/kubernetes-version
curl -fsSL "https://dl.k8s.io/release/$(cat /tmp/kubernetes-version)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
chmod 0755 /usr/local/bin/kubectl

usermod -aG docker jenkins
systemctl enable --now docker
systemctl enable --now jenkins