#! /bin/sh

#connect to root
#setup-alpine
#adding ssh to run ass default
rc-update add sshd default
#delete old vm ssh key if needec
ssh-keygen -f ~/.ssh/known_hosts -R "[localhost]:2222"
#add and config docker
#handle !cgroup !
#add docker to default
rc-update add docker default
