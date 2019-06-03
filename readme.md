
docker-compose -f trainee.yml up


Remove failed docker builds:

sudo docker rm $(docker ps -aq)
sudo docker rmi $(docker images | grep "^<none>" | awk '{print $3}')

Remove all docker images:

sudo docker system prune -a



ssh connection and tunnel
- ssh-copy-id docker@CONTAINERIP
- ssh oStrictHostKeyChecking=no -L 5901:localhost:5901 docker@CONTAINERIP


Mongo Initial Setup:
Comment out mongod in supervisor.conf file
Uncomment the createusers part in entrypoint.sh

Uncomment mongod section, comment the createusers part in entrypoint.sh and restart docker