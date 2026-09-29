#!/bin/bash
set -euxo pipefail

apt-get update
apt-get install -y ca-certificates curl fontconfig openjdk-21-jre-headless unzip

curl -fsSL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-6.2.1.4610-linux-x64.zip -o /tmp/sonar-scanner.zip
unzip -q -o /tmp/sonar-scanner.zip -d /opt
ln -sfn /opt/sonar-scanner-6.2.1.4610-linux-x64 /opt/sonar-scanner
ln -sfn /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner