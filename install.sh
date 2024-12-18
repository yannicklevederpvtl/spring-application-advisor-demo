#!/bin/bash
export ADVISOR_DEMO_HOME=$(echo $(pwd))

############# Advisor Environment Variables ##############
if command -v direnv >/dev/null 2>&1; then
  echo "direnv exists"
else
  brew install direnv
fi

############# Credentials ##############
if [ "$BROADCOM_ARTIFACTORY_EMAIL" = "" ] ;then
  read -p "Broadcom Support Portal Email? " BROADCOM_ARTIFACTORY_EMAIL

  if [ "$BROADCOM_ARTIFACTORY_TOKEN" = "" ] ;then
    read -p "Broadcom Artifactory Access Token? " BROADCOM_ARTIFACTORY_TOKEN    
  fi

  echo ""
  printf 'Would you like to save these credentials locally (y/n)? '
  read answer

  if [ "$answer" != "${answer#[Yy]}" ] ;then 
      if test -f .envrc; then
          rm .envrc
      fi
      echo "export BROADCOM_ARTIFACTORY_EMAIL=\"$BROADCOM_ARTIFACTORY_EMAIL\"" >> .envrc
      echo "export BROADCOM_ARTIFACTORY_TOKEN=\"$BROADCOM_ARTIFACTORY_TOKEN\"" >> .envrc
      direnv allow
  fi
fi

########## jq Installation #############
if command -v jq >/dev/null 2>&1; then
  echo "jq exists"
else
  brew install jq
fi

###### Advisor CLI Installation ########
if command -v advisor >/dev/null 2>&1; then
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
cd $ADVISOR_DEMO_HOME
tar -xzvf repoesbackup.zip
docker run --name artifactory -v $ADVISOR_DEMO_HOME/repoesbackup:/repoesbackup -v $JFROG_HOME/artifactory/var/:/var/opt/jfrog/artifactory -d -p 8081:8081 -p 8082:8082 releases-docker.jfrog.io/jfrog/artifactory-oss:7.98.11

while true
do
    status=$(curl --head -u admin:password  http://localhost:8082/artifactory/api/system/ping -o /dev/null -w '%{http_code}\n' -s)
    echo "Waiting for Artifactory to be ready"
    if [[ status -eq 200 ]]; then
        echo "Artifactory is ready"
        break
    fi
    sleep 20
done
jq ".remoteRepoConfigs[0].repoTypeConfig.password = \"$BROADCOM_ARTIFACTORY_TOKEN\"" ./repoesbackup/artifactory.repository.config.json > tmp1.json 
jq ".remoteRepoConfigs[0].repoTypeConfig.username = \"$BROADCOM_ARTIFACTORY_EMAIL\"" ./tmp1.json  > tmp2.json && mv tmp2.json ./repoesbackup/artifactory.repository.config.json
rm tmp1.json
curl -u admin:password -X POST http://localhost:8082/artifactory/api/system/decrypt
curl -u admin:password --header "Content-Type: application/json" -X POST http://localhost:8082/artifactory/api/import/system --data "{\"importPath\":\"/repoesbackup/\", \"includeMetadata\":true, \"verbose\":true, \"failOnError\":true, \"failIfEmpty\":true }" 

##### Maven to local Artifactory settings ######
if test -f $HOME/.m2/settings.xml; then
  echo ""
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

echo export ADVISOR_SERVER=http://localhost:9003 >> .envrc_sp
echo '.envrc' >> ./spring-petclinic/.gitignore
mv .envrc_sp ./spring-petclinic/.envrc
direnv allow spring-petclinic

############# Links & Commands Cheat Sheet  #######
echo ""
LB="\033[01;34m"
NC="\033[0m" 
echo -e "${LB}Spring Application Advisor Server${NC}"
echo -e "http://localhost:9003/actuator/health"
echo ""
echo -e "${LB}Artifactory"
echo -e "URL:${NC}  http://localhost:8082/ui/login/"
echo -e "${LB}Username:${NC} admin"
echo -e "${LB}Password:${NC} password"
echo ""
echo ""
echo -e "${LB}Spring-Petclinic sample - Commands Cheat Sheet:${NC}"
echo ""
echo "cd spring-petclinic"
echo "advisor build-config get"
echo "advisor build-config publish"
echo "advisor upgrade-plan get"
echo "advisor upgrade-plan apply"
echo "advisor build-config get && advisor upgrade-plan apply"
echo "git diff"
echo "git status"
echo "git diff src/main/java/org/springframework/samples/petclinic/owner/OwnerController.java"
echo "git add -A && git commit -m \"Java 8 to 11\""
echo "git push"
echo ""
