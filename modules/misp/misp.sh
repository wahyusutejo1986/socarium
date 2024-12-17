#!/bin/bash

# Function to handle errors
error_handler() {
    local MESSAGE=$1
    echo "❌ Error: $MESSAGE. Exiting."
    exit 1
}

# Function to update or add a configuration in the .env file
update_env_var() {
    local key="$1"
    local value="$2"
    local env_file="/opt/socarium/MISP/.env"

    if grep -q "^$key=" "$env_file"; then
        sed -i "s|^$key=.*|$key=$value|" "$env_file"
    else
        echo "$key=$value" >> "$env_file"
    fi
}

# Function to set all variables in the .env file
set_all_env_vars() {
    local env_file="/opt/socarium/MISP/.env"
    echo "🔧 Setting all variables in the .env file..."

    declare -A ENV_VARS=(
        ["MYSQL_HOST"]="db"
        ["MYSQL_PORT"]="3306"
        ["MYSQL_DATABASE"]="misp"
        ["MYSQL_USER"]="misp"
        ["MYSQL_PASSWORD"]="socarium"
        ["MYSQL_ROOT_PASSWORD"]="socarium"
        ["CORE_COMMIT"]=""
        ["PYPI_REDIS_VERSION"]="==5.0.*"
        ["PYPI_LIEF_VERSION"]=">=0.13.1"
        ["PYPI_PYDEEP2_VERSION"]="==0.5.*"
        ["PYPI_PYTHON_MAGIC_VERSION"]="==0.4.*"
        ["PYPI_MISP_LIB_STIX2_VERSION"]="==3.0.*"
        ["PYPI_MAEC_VERSION"]="==4.1.*"
        ["PYPI_MIXBOX_VERSION"]="==1.0.*"
        ["PYPI_CYBOX_VERSION"]="==2.1.*"
        ["PYPI_PYMISP_VERSION"]="==2.4.178"
        ["PYPI_MISP_STIX_VERSION"]="==2.4.194"
        ["DISABLE_IPV6"]="false"
        ["DISABLE_SSL_REDIRECT"]="false"
        ["DEBUG"]="0"
        ["OIDC_ENABLE"]=""
        ["OIDC_PROVIDER_URL"]=""
        ["OIDC_CLIENT_ID"]=""
        ["OIDC_CLIENT_SECRET"]=""
        ["OIDC_ROLES_PROPERTY"]="roles"
        ["OIDC_ROLES_MAPPING"]="{}"
        ["OIDC_DEFAULT_ORG"]=""
        ["OIDC_LOGOUT_URL"]=""
        ["OIDC_SCOPES"]=""
        ["LDAP_ENABLE"]="false"
        ["LDAP_APACHE_ENV"]=""
        ["LDAP_SERVER"]=""
        ["LDAP_STARTTLS"]="false"
        ["LDAP_READER_USER"]=""
        ["LDAP_READER_PASSWORD"]=""
        ["LDAP_DN"]=""
        ["LDAP_SEARCH_FILTER"]=""
        ["LDAP_SEARCH_ATTRIBUTE"]=""
        ["LDAP_FILTER"]="[]"
        ["LDAP_DEFAULT_ROLE_ID"]=""
        ["LDAP_DEFAULT_ORG"]=""
        ["LDAP_EMAIL_FIELD"]="[]"
        ["LDAP_OPT_PROTOCOL_VERSION"]="3"
        ["LDAP_OPT_NETWORK_TIMEOUT"]="-1"
        ["LDAP_OPT_REFERRALS"]="false"
        ["AAD_ENABLE"]="false"
        ["AAD_CLIENT_ID"]=""
        ["AAD_TENANT_ID"]=""
        ["AAD_CLIENT_SECRET"]=""
        ["AAD_REDIRECT_URI"]=""
        ["AAD_PROVIDER"]=""
        ["AAD_PROVIDER_USER"]=""
        ["AAD_MISP_USER"]=""
        ["AAD_MISP_ORGADMIN"]=""
        ["AAD_MISP_SITEADMIN"]=""
        ["AAD_CHECK_GROUPS"]="false"
        ["NGINX_X_FORWARDED_FOR"]="false"
        ["NGINX_SET_REAL_IP_FROM"]=""
        ["PROXY_ENABLE"]="false"
        ["PROXY_HOST"]=""
        ["PROXY_PORT"]=""
        ["PROXY_METHOD"]=""
        ["PROXY_USER"]=""
        ["PROXY_PASSWORD"]=""
        ["SMTP_FQDN"]=""
        ["FASTCGI_STATUS_LISTEN"]=""
        ["PHP_SESSION_COOKIE_DOMAIN"]=""
        ["HSTS_MAX_AGE"]=""
        ["X_FRAME_OPTIONS"]="SAMEORIGIN"
        ["CONTENT_SECURITY_POLICY"]=""
    )

    for key in "${!ENV_VARS[@]}"; do
        update_env_var "$key" "${ENV_VARS[$key]}"
    done

    echo "✅ All variables set in the .env file."
}

# Function to remove the deprecated `version` attribute from docker-compose.yml
update_docker_compose_file() {
    local compose_file="/opt/socarium/MISP/docker-compose.yml"
    echo "🔧 Removing deprecated 'version' attribute from docker-compose.yml..."
    sed -i '/version:/d' "$compose_file"
    echo "✅ Updated docker-compose.yml."
}

# Function to initialize MySQL database
initialize_mysql() {
    echo "🚀 Initializing MySQL database..."

    # Wait for the database to be ready
    echo "⏳ Waiting for MySQL to start..."
    until docker exec misp-db-1 mysqladmin ping -u root --password=socarium --silent; do
        sleep 2
    done

    # Set up the database and user
    echo "🔧 Setting up the misp database and user..."
    docker exec -i misp-db-1 mysql -u root --password=socarium <<EOSQL
CREATE DATABASE IF NOT EXISTS misp;
CREATE USER IF NOT EXISTS 'misp'@'%' IDENTIFIED BY 'socarium';
GRANT ALL PRIVILEGES ON misp.* TO 'misp'@'%';
FLUSH PRIVILEGES;
EOSQL

    echo "✅ MySQL database and user setup completed."
}

# Function to configure the MISP .env file
configure_misp_env() {
    echo "🔧 Configuring MISP .env file..."
    set_all_env_vars
}

# Function to install or update MISP
install_misp() {
    echo "🚀 Installing MISP..."
    local BASE_DIR="/opt/socarium"
    local MISP_DIR="$BASE_DIR/MISP"
    local MISP_REPO="https://github.com/MISP/misp-docker.git"

    if [ -d "$MISP_DIR" ]; then
        echo "⚠️ Directory $MISP_DIR already exists. Updating repository..."
        cd "$MISP_DIR"
        git pull || error_handler "Updating MISP Repository"
    else
        echo "⚠️ Directory $MISP_DIR does not exist. Cloning repository..."
        git clone $MISP_REPO "$MISP_DIR" || error_handler "Cloning MISP Repository"
        cd "$MISP_DIR"
    fi

    # Copy the template environment file
    if [ ! -f .env ]; then
        cp template.env .env
    fi

    # Configure the MISP .env file
    configure_misp_env

    # Remove deprecated 'version' attribute from docker-compose.yml
    update_docker_compose_file

    # Pull and start the MISP containers
    sudo docker-compose pull
    sudo docker-compose up -d || error_handler "Starting MISP Containers"

    # Initialize the MySQL database
    initialize_mysql

    echo "✅ MISP installation or update completed successfully."
    cd -
}

# Run the installation function
install_misp