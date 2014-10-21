
#
# Metrilyx bootstrap script
#   This script installs the required pre-requisites to install and run Metrilyx
#
# THIS IS STILL IN PROGRESS - SPECIFICALLY FOR DEBIAN BASED SYSTEMS
#

RPM_PKGS="git gcc gcc-c++ gcc-gfortran atlas-devel blas-devel libffi libffi-devel libuuid uuid python-setuptools python-devel";
DEB_PKGS="make g++ gfortran libuuid1 uuid-runtime python-setuptools python-dev libpython-dev git-core libffi-dev libatlas-dev libblas-dev python-numpy"

NGINX_PKG_URL="http://nginx.org/packages";
NGINX_CONF_DIR="/etc/nginx/conf.d"

DISTRO=""
## Redhat CentOS Oracle
[ -f "/etc/redhat-release" ] && DISTRO=$(cat /etc/redhat-release  | cut -f 1 -d ' ' | tr '[:upper:]' '[:lower:]')
## Debian
[ -f "/etc/debian_version" ] && DISTRO="debian"
## Ubuntu
grep "ubuntu" /etc/apt/sources.list && DISTRO="ubuntu" 

if [ "$DISTRO" == "" ];then 
    echo "Could not determine OS distribution: $DISTRO";
    exit 1;
else
    echo "Distribution: $DISTRO";
fi

install_nginx_rpm() {
    ## DISTRO: centos, oracle, rhel
    rpm -qa | grep 'nginx-release' || { 
        yum -y install "${NGINX_PKG_URL}/${DISTRO}/6/noarch/RPMS/nginx-release-${DISTRO}-6-0.el6.ngx.noarch.rpm" && yum -y install nginx;
        chkconfig nginx on;
    }
}

install_nginx_deb() {    
    ## TODO: prompt and read from stdin.
    echo "Please enter $DISTRO codename: "
    read CODENAME

    SOURCES_LIST="/etc/apt/sources.list";
    
    ## Add nginx repo key
    NGINX_KEY_NAME="nginx_signing.key";
    NGINX_SGN_KEY="http://nginx.org/keys/$NGINX_KEY_NAME";
    wget $NGINX_SGN_KEY && apt-key add $NGINX_KEY_NAME && rm -rf $NGINX_KEY_NAME;

    ## Add nginx repository
    grep "$NGINX_SRC_URL" $SOURCES_LIST || { 
        echo -e "\ndeb ${NGINX_PKG_URL}/${DISTRO}/ ${CODENAME} nginx\ndeb-src ${NGINX_PKG_URL}/${DISTRO}/ ${CODENAME} nginx\n" >> $SOURCES_LIST;
        apt-get update;
    }
    
    ## Install nginx
    apt-get install -y nginx;
}

install_nginx() {
    if [[ ( "$DISTRO" == "centos" ) || ( "$DISTRO" == "oracle" ) || ( "$DISTRO" == "rhel" ) || ( "$DISTRO" == "redhat" ) ]]; then
        install_nginx_rpm;
    else
        install_nginx_deb;
    fi
    [ -f "${NGINX_CONF_DIR}/default.conf" ] && mv ${NGINX_CONF_DIR}/default.conf ${NGINX_CONF_DIR}/default.conf.disabled;
}

bootstrap_metrilyx_rpm() {
    for PKG in $RPM_PKGS; do
        rpm -qa | grep $PKG || yum -y install $PKG
    done
}   

bootstrap_metrilyx_deb() {
    apt-get install -y $DEB_PKGS;
}

bootstrap_metrilyx() {
    if [[ ( "$DISTRO" == "centos" ) || ( "$DISTRO" == "oracle" ) || ( "$DISTRO" == "rhel" ) || ( "$DISTRO" == "redhat" ) ]]; then
        bootstrap_metrilyx_rpm;
        which pip || easy_install pip;
        pip install "numpy>=1.6.1";    
    else
        bootstrap_metrilyx_deb;
        which pip || easy_install pip;
    fi
}

install_metrilyx() {
    pip install git+https://github.com/Ticketmaster/metrilyx-2.0.git
}


#### Main ####

install_nginx;
bootstrap_metrilyx;

if [ "$1" == "install" ]; then
    echo " * Installing Metrilyx...";
    install_metrilyx;
fi
