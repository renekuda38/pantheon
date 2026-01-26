#!/bin/bash
# Universal entrypoint script for Jenkins agents (both inbound and ubuntu)
# Fixes docker.sock permissions before starting agent

# Fix docker socket permissions (must run as root initially)
                                                                                                                                                         
if [ -S /var/run/docker.sock ]; then                                                                                                                        
    sudo /bin/chown root:docker /var/run/docker.sock                                                                                                        
    sudo /bin/chmod 660 /var/run/docker.sock                                                                                                                
fi                                                                                                                                                          
                                                                                                                                                            
if command -v jenkins-agent >/dev/null 2>&1; then                                                                                                           
    exec jenkins-agent "$@"                                                                                                                                 
else                                                                                                                                                        
    exec java -jar /home/jenkins/agent.jar "$@"                                                                                                             
fi  