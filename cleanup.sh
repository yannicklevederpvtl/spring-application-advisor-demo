docker rm $(docker stop $(docker ps -a | grep "git-server" | cut -d " " -f 1))
docker rm $(docker stop $(docker ps -a | grep "artifactory-oss" | cut -d " " -f 1))
docker rm $(docker stop $(docker ps -a | grep "postgres" | cut -d " " -f 1))
docker rm $(docker stop $(docker ps -a | grep "spring-server" | cut -d " " -f 1))
docker volume rm git-repositories
docker volume rm spring-server
docker image rm releases-docker.jfrog.io/jfrog/artifactory-oss:7.90.17
docker image rm eclipse-temurin:latest
docker image rm postgres:latest
docker image rm rockstorm/git-server:latest 
docker system prune
docker volume prune
rm advisor
rm advisor-cli.tar
rm -rf artifactory
rm -rf spring-server
rm -rf spring-petclinic
rm -r $HOME/.m2/repository
