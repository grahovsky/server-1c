#!/bin/sh
docker rm -f onec 2> /dev/null
docker volume rm  1c-server-home 1c-server-logs 2> /dev/null

docker run --name onec \
  -it \
  --detach \
  --net my_app_net \
  -p 31540-31541:31540-31541 \
  -p 31560-31591:31560-31591 \
  -p 31545:31545 \
  --privileged \
  --volume 1c-server-logs:/var/log/1C \
  grahovsky/onec

#--volume 1c-server-home:/home/usr1cv8 \
#--net host \
#--net my_app_net \
#--volume /etc/localtime:/etc/localtime:ro \
#--user usr1cv8 \
#-p 2540-2541:2540-2541 \
#-p 2560-2591:2560-2591 \
#-p 1545:1545 \
