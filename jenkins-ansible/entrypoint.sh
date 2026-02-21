#!/bin/bash
set -e

# Fix permissions for the mounted host volumes
# This ensures Jenkins can read/write to the mounted /site-data and /var/lib/jenkins
# We only chown if the folder isn't already owned by jenkins (uid 1000) to speed up startup
for dir in /site-data /var/lib/jenkins /etc/ansible; do
  if [ -d "$dir" ] && [ "$(stat -c '%u' "$dir" 2>/dev/null)" != "1000" ]; then
    echo "Updating permissions for $dir..."
    chown -R jenkins:jenkins "$dir"
  fi
done

# Start Jenkins as the jenkins user
# Using 'runuser' or 'sudo -u' ensures the process starts as jenkins, not root
exec sudo -u jenkins java -DJENKINS_HOME=/var/lib/jenkins -jar /usr/share/java/jenkins.war

# # Start the Jenkins service
# echo "Starting Jenkins service..."
# service jenkins start

# # Keep the container running
# exec tail -f /var/log/jenkins/jenkins.log