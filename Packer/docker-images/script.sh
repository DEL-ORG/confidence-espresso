#!/bin/bash

# To avoid any pop up windows while the scrip is running, update, upgrade and reboot the system to update the kernel before running the script
#     apt update
#    apt upgrade -y
# Reboot the system to load the new kernel version without prompting
#    reboot -y

# ubuntu = Ubuntu
# redhat = Red Hat Enterprise Linux
# centos = CentOS Linux
# amazon-ec2 = Amazon Linux

OS_NAME=$(cat /etc/*release |grep -w NAME |awk -F'"' '{print$2}')

function yum_os {
  echo "This is $OS_NAME OS"
  sleep 5
  yum update -y 
}

function apt_os {
    echo "This is $OS_NAME OS"
    sleep 5
    # List of packages to install
    packages=(
        curl      
        wget
        apt-utils
        vim
        openssh-client
        openssh-server
        python3
        nodejs
        build-essential
        npm
        ansible
        htop
        watch
        pip3 
        git 
        make
        mysql
        psql  
        python3-pip 
        openssl 
        rsync 
        jq 
        postgresql-client 
        mariadb-client 
        mysql-client 
        unzip 
        tree 
        default-jdk
        default-jre
        maven
        gnupg
    )

    # Update package list
    apt update -y
    apt upgrade -y
    # Install packages
    for package in "${packages[@]}"; do
        echo "Installing $package Please wait ................."
        sleep 3
        DEBIAN_FRONTEND=noninteractive apt install -y "$package"
    done
    echo "Package installation completed."
}

function apt_software {
    ## Install aws cli
    which aws
    if [ "$?" -eq 0 ]; then
        echo "AWS ClI is intalled already. Noting to do"
    else
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        ./aws/install
        rm -rf awscliv2.zip
        rm -rf aws
    fi

    # Install Terrafrom on Ubuntu Machine
    wget -O- https://apt.releases.hashicorp.com/gpg |    gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" |    tee /etc/apt/sources.list.d/hashicorp.list
    apt update &&    apt install terraform

    # Install Ansible
    apt update
    add-apt-repository --yes --update ppa:ansible/ansible
    apt install ansible
    
    ## Install kubectl
    curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.9/2020-08-04/bin/linux/amd64/kubectl 
    chmod +x ./kubectl 
    mv kubectl /usr/local/bin/

    ## INSTALL KUBECTX AND KUBENS
    wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx 
    wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens 
    chmod +x kubectx kubens 
    mv kubens kubectx /usr/local/bin

    ## Install Helm 3
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
     chmod 700 get_helm.sh
    ./get_helm.sh
    helm version

    ## Install Docker Coompose
    # https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-20-04
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    docker-compose --version

    ### TERRAGRUNT INSTALLATIN
    # https://terragrunt.gruntwork.io/docs/getting-started/supported-terraform-versions/
    TERRAGRUNT_VERSION="v0.38.0"
    wget https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 
    mv terragrunt_linux_amd64 terragrunt 
    chmod u+x terragrunt 
    mv terragrunt /usr/local/bin/terragrunt
    terragrunt --version

    ## Install Docker
    # https://docs.docker.com/engine/install/ubuntu/
    apt-get remove docker docker-engine docker.io containerd runc -y
    apt-get update
    apt-get install \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg |    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" |    tee /etc/apt/sources.list.d/docker.list > /dev/null
    chmod a+r /etc/apt/keyrings/docker.gpg
    apt-get update
    apt install docker-ce docker-ce-cli containerd.io -y
    systemctl start docker
    systemctl enable docker

    ## chmod the Docker socket. the Docker daemon does not have the necessary permissions to access the Docker socket file located at /var/run/docker.sock
    chown root:docker /var/run/docker.sock
    chmod 666 /var/run/docker.sock
}

function user_setup {
cat /tmp/users.txt

    username=$(cat /tmp/users.txt | tr '[A-Z]' '[a-z]')
    GROUP_NAME="tools"

    # cat /etc/group |grep -w tools &>/dev/nul ||    groupadd $GROUP_NAME

    if grep -q "^$GROUP_NAME:" /etc/group; then
        echo "Group '$GROUP_NAME' already exists."
    else
        groupadd "$GROUP_NAME"
        echo "Group '$GROUP_NAME' created."
    fi

    if    grep -q "^%$GROUP_NAME" /etc   ers; then
        echo "Group '$GROUP_NAME' is already in   ers."
    else
        echo "%$GROUP_NAME ALL=(ALL) NOPASSWD: ALL" |    tee -a /etc   ers
        echo "Group '$GROUP_NAME' added to   ers with NOPASSWD: ALL."
    fi

    ## allow automation tools to access docker
    for i in $username
    do 
        if grep -q "^$i" /etc   ers; then
            echo "User '$i' is already in   ers."
        else
            echo "$i ALL=(ALL) NOPASSWD: /usr/bin/docker" |    tee -a /etc   ers
        fi
    done

    for users in $username
    do
        ls /home |grep -w $users &>/dev/nul || mkdir -p /home/$users
        cat /etc/passwd |awk -F: '{print$1}' |grep -w $users &>/dev/nul ||  useradd $users
        chown -R $users:$users /home/$users
        usermod -s /bin/bash -aG tools $users
        usermod -s /bin/bash -aG docker $users
        echo -e "$users\n$users" |passwd "$users"
    done

    ## Set vim as default text editor
    update-alternatives --set editor /usr/bin/vim.basic
    update-alternatives --set vi /usr/bin/vim.basic
}

function enable_password_authentication {
    # Check if password authentication is already enabled
    if grep -q "PasswordAuthentication yes" /etc/ssh/sshd_config; then
        echo "Password authentication is already enabled."
    else
        # Enable password authentication by modifying the SSH configuration file
        sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
        echo "Password authentication has been enabled in /etc/ssh/sshd_config."

        # Restart the SSH service to apply changes
        systemctl restart ssh
        echo "SSH service has been restarted."
    fi
}

if [[ $OS_NAME == "Red Hat Enterprise Linux" ]] || [[ $OS_NAME == "CentOS Linux" ]] || [[ $OS_NAME == "Amazon Linux" ]] 
then
    yum_os
elif [[ $OS_NAME == "Ubuntu" ]] 
then
    export DEBIAN_FRONTEND=noninteractive
    apt_os
    apt_software
    user_setup
    enable_password_authentication
else
    echo "HUMMMMMMMMMM. I don't know this OS"
    exit
fi