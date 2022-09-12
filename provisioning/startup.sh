#!/bin/bash

install_wget() {
    apt install wget -y
}

install_golang() {
    wget https://go.dev/dl/go1.18.2.linux-amd64.tar.gz
    rm -rf /usr/local/go && tar -C /usr/local -xzf go1.18.2.linux-amd64.tar.gz
    echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile
    source /etc/profile
}

install_docker() {
    apt-get remove docker docker-engine docker.io containerd runc -y
    apt-get update -y
    apt-get install ca-certificates curl gnupg lsb-release -y
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
    sleep 10 # Wait for docker to start
}

install_docker_compose() {
    apt install docker-compose -y
}

install_make() {
    apt install make gcc -y
}

install_git() {
    apt install git -y
}

install_dependencies() {
    apt update -y
    install_wget
    install_golang
    install_docker
    install_docker_compose
    install_make
    install_git
}

create_env_file() {
    ENV_FILE_PATH="$1/.env"

    if [ ! -e ${ENV_FILE_PATH}]; then
        touch $ENV_FILE_PATH
    fi

    if [ -z ${DB_HOSTNAME} ]; then
        echo DB_HOSTNAME=`curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/db_hostname" -H "Metadata-Flavor: Google"` >> ${ENV_FILE_PATH}
    fi

    if [ -z ${DB_PORT} ]; then
        echo DB_PORT=`curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/db_port" -H "Metadata-Flavor: Google"` >> ${ENV_FILE_PATH}
    fi

    if [ -z ${DB_USERNAME} ]; then
        echo DB_USERNAME=`curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/db_username" -H "Metadata-Flavor: Google"` >> ${ENV_FILE_PATH}
    fi

    if [ -z ${DB_PASSWORD} ]; then
        echo DB_PASSWORD=`curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/db_password" -H "Metadata-Flavor: Google"` >> ${ENV_FILE_PATH}
    fi

    if [ -z ${DB_NAME} ]; then
        echo DB_NAME=`curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/db_name" -H "Metadata-Flavor: Google"` >> ${ENV_FILE_PATH}
    fi

    if [ -z ${GOOGLE_CLOUD_PROJECT} ]; then
        echo GOOGLE_CLOUD_PROJECT=`curl "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google"` >> ${ENV_FILE_PATH}
    fi
}

deploy_roleplay_webapp() {
    CLONE_PATH="/root/role-play-webapp"
    git clone https://github.com/ryotat7/role-play-webapp.git $CLONE_PATH

    create_env_file $CLONE_PATH/webapp

    count=`ps -ef | grep dockerd | grep -v grep | wc -l`
    if [ ${count} = 0 ]; then
        systemctl start docker
    fi

    export GOCACHE=/usr/local/go/cache && \
    export GOBIN=/usr/local/go/bin && \
    export GOPATH=/usr/local/go && \
    cd $CLONE_PATH/webapp && \
    make upgrade-compose && \
    make all
}

install_dependencies
deploy_roleplay_webapp