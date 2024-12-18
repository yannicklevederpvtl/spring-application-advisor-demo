docker rm $(docker stop $(docker ps -a | grep "git-server" | cut -d " " -f 1))
docker rm $(docker stop $(docker ps -a | grep "artifactory-oss" | cut -d " " -f 1))
docker rm $(docker stop $(docker ps -a | grep "postgres" | cut -d " " -f 1))
docker rm $(docker stop $(docker ps -a | grep "spring-server" | cut -d " " -f 1))
rm -rf artifactory
rm -rf spring-server
rm -rf spring-petclinic
rm -rf repoesbackup
rm -r $HOME/.m2/repository