#!/bin/sh
set -e
JENKINS_VERSION=$(curl -s -L https://updates.jenkins.io/stable/latestCore.txt)
echo "$JENKINS_VERSION"
