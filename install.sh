#!/bin/bash
export ADVISOR_DEMO_HOME=$(echo $(pwd))
export BROADCOM_ARTIFACTORY_TOKEN

if [ $BROADCOM_ARTIFACTORY_TOKEN = ""] ;then
  printf "Broadcom Artifactory Access Token)? "
  read BROADCOM_ARTIFACTORY_TOKEN
fi

###### Advisor CLI Installation ########
if command -v advisor >&2; then
  echo "Advisor CLI exists"
else
  arch=$(uname -m)
  if [[ $arch == x86_64* ]]; then
    echo "X64 Architecture"
    curl -L -H "Authorization: Bearer $BROADCOM_ARTIFACTORY_TOKEN" -o advisor-cli.tar -X GET https://packages.broadcom.com/artifactory/spring-enterprise/com/vmware/tanzu/spring/application-advisor-cli-macos/1.1.0/application-advisor-cli-macos-1.1.0.tar
  elif  [[ $arch == arm* ]]; then
    echo "ARM Architecture"
    curl -L -H "Authorization: Bearer $BROADCOM_ARTIFACTORY_TOKEN" -o advisor-cli.tar -X GET https://packages.broadcom.com/artifactory/spring-enterprise/com/vmware/tanzu/spring/application-advisor-cli-macos-arm64/1.1.0/application-advisor-cli-macos-arm64-1.1.0.tar
  fi
  tar -xf advisor-cli.tar --strip-components=1 --exclude=./META-INF
  echo "Installation of the Advisor CLI"
  sudo cp advisor /usr/local/bin/
fi

###### Advisor Server Download ########
curl -L -H "Authorization: Bearer $BROADCOM_ARTIFACTORY_TOKEN" -o spring-server.jar -X GET https://packages.broadcom.com/artifactory/spring-enterprise/com/vmware/tanzu/spring/tanzu-spring-server/1.1.0/tanzu-spring-server-1.1.0.jar
mkdir spring-server
mv ./spring-server.jar spring-server

######### Postgres Deployment ##########
docker run --name postgres -itd -e POSTGRES_USER=artifactory -e POSTGRES_PASSWORD=password -e POSTGRES_DB=artifactorydb -p 5432:5432 library/postgres
sleep 10

######### Artifactory Deployment ##########
export JFROG_HOME=$(echo $(pwd)/artifactory)

mkdir -p $JFROG_HOME/artifactory/var/etc/
cd $JFROG_HOME/artifactory/var/etc/
tee -a ./system.yaml << END
shared:
  database:
    driver: org.postgresql.Driver
    type: postgresql
    url: jdbc:postgresql://host.docker.internal:5432/artifactorydb
    username: artifactory
    password: password
END
chmod -R 777 $JFROG_HOME/artifactory/var
docker run --name artifactory -v $JFROG_HOME/artifactory/var/:/var/opt/jfrog/artifactory -d -p 8081:8081 -p 8082:8082 releases-docker.jfrog.io/jfrog/artifactory-oss:7.90.17
cd $ADVISOR_DEMO_HOME

##### Maven to local Artifactory settings ######
if test -f $HOME/.m2/settings.xml; then
  printf 'Maven settings.xml already exists, do you wish to replace your Maven settings.xml (Make a backup before proceeding) (y/n)? '
  read answer

  if [ "$answer" != "${answer#[Yy]}" ] ;then 
      cp settings.xml $HOME/.m2/settings.xml
  fi
else
  cp settings.xml $HOME/.m2/settings.xml
fi

######### Local GIT Server Deployment ##########
if ! test -f ~/.ssh/id_rsa.pub; then
  echo "public/private rsa key pair does not exist."
  ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa <<< y
fi

docker run --name git-server -itd -v git-repositories:/srv/git -v ~/.ssh/id_rsa.pub:/home/git/.ssh/authorized_keys -p 2222:22 rockstorm/git-server

until [ "`docker inspect -f {{.State.Status}} git-server`"=="running" ]; do
    echo "Waiting for GIT-Server"
    sleep 5;
done;

ssh git@localhost -p 2222 "mkdir /srv/git/spring-petclinic-local.git;"
ssh git@localhost -p 2222 "git-init --bare /srv/git/spring-petclinic-local.git"

######### Spring Advisor Server Deployment ##########
docker run --name spring-server -itd -p 9003:9003 -v ${PWD}/spring-server:/home/spring-server eclipse-temurin bash -c 'java -jar -Dserver.port=9003 /home/spring-server/spring-server.jar'

## Sample Application Cloning to local GIT-Server ###
git clone https://github.com/spring-projects/spring-petclinic
cd spring-petclinic
git branch advisor-demo 9ecdc1111e3da388a750ace41a125287d9620534
git checkout -f advisor-demo
git remote remove origin
git remote add 'origin' ssh://git@localhost:2222/srv/git/spring-petclinic-local.git
git push --set-upstream origin advisor-demo
cd $ADVISOR_DEMO_HOME

############# Advisor URL env variable ##############
if command -v direnv >&2; then
  echo "direnv exists"
else
  brew install direnv
fi

echo export ADVISOR_SERVER=http://localhost:9003 >> .envrc
echo '.envrc' >> ./spring-petclinic/.gitignore
mv .envrc ./spring-petclinic/
direnv allow spring-petclinic

############# Manual creation of repositories #######
echo ""
echo "Spring Advisor Server"
echo "http://localhost:9003/actuator/health"
echo ""
echo "Artifactory (Wait a few minutes)"
echo "http://localhost:8082"
echo ""

echo "Local Artifactory Credentials | User: admin, Password: password"
echo "Repository Key: spring-enterprise-mvn-remote (or preferred on-premise naming convention)"
echo "URL: https://packages.broadcom.com/artifactory/spring-enterprise"
echo "User Name: email address for this account"
echo "Password / Access Token: the value with the save Access Token file for attribute access_token"
echo ""

printf "Did configure the Maven repositories in the local Artifactory (See README.md) (y)? "
read answer

if [ "$answer" != "${answer#[Yy]}" ] ;then 
    echo ""
    echo "Spring-Petclinic sample - Commands Cheat Sheet:"
    echo ""
    echo "cd spring-petclinic"
    echo "advisor build-config get"
    echo "advisor build-config publish"
    echo "advisor upgrade-plan get"
    echo "advisor upgrade-plan apply"
    echo "git diff"
    echo "git add -A && git commit -m \"Java 8 to 11\""
    echo "git push"
fi