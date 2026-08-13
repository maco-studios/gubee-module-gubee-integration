#!/usr/bin/env bash
#
# Installs a Magento instance inside the container (if one isn't already
# present), wires it up to the docker-compose services, and requires this
# module into it via Composer. Idempotent: safe to run on every container
# boot, only does real work the first time.

set -euo pipefail

MAGENTO_ROOT="/var/www/html"
MODULE_ROOT="/module"
MAGENTO_VERSION="${MAGENTO_VERSION:-2.4.8}"
MAGE_OS_REPO="https://repo.mage-os.org/"

log() {
    echo "[setup-magento] $*"
}

wait_for_tcp() {
    local name="$1" host="$2" port="$3" tries=60

    log "Waiting for ${name} (${host}:${port})..."
    until (exec 3<>"/dev/tcp/${host}/${port}") 2>/dev/null; do
        tries=$((tries - 1))
        if [ "${tries}" -le 0 ]; then
            log "Timed out waiting for ${name} at ${host}:${port}"
            exit 1
        fi
        sleep 2
    done
    exec 3>&- 3<&- 2>/dev/null || true
    log "${name} is reachable."
}

wait_for_tcp "MySQL" mysql 3306
wait_for_tcp "Redis" redis 6379
wait_for_tcp "RabbitMQ" rabbitmq 5672
wait_for_tcp "OpenSearch" opensearch 9200
wait_for_tcp "MinIO" minio 9000

# github.com isn't in the container's known_hosts yet; without this, the
# private gubee-php-sdk clone below hangs on an interactive host-key prompt.
mkdir -p "${HOME}/.ssh"
if ! grep -q "^github.com " "${HOME}/.ssh/known_hosts" 2>/dev/null; then
    ssh-keyscan -H github.com >>"${HOME}/.ssh/known_hosts" 2>/dev/null || true
fi

if [ ! -f "${MAGENTO_ROOT}/bin/magento" ]; then
    # Mage-OS doesn't publish "magento/project-community-edition"; it mirrors
    # Magento core under its own package/version namespace
    # ("mage-os/project-community-edition") with version numbers that don't
    # match Magento's. The real Magento version each release corresponds to
    # is recorded in mage-os/product-community-edition's "extra.magento_version".
    log "Resolving Mage-OS package version for Magento ${MAGENTO_VERSION}..."
    # Mage-OS only ships patched releases (e.g. "2.4.7-p4"), never the bare
    # "2.4.7", so match by prefix and take the highest (last, since entries
    # are ascending) matching patch release.
    MAGE_OS_PACKAGE_VERSION="$(curl -fsSL "${MAGE_OS_REPO}p2/mage-os/product-community-edition.json" | php -r '
        $data = json_decode(stream_get_contents(STDIN), true);
        $match = null;
        foreach ($data["packages"]["mage-os/product-community-edition"] as $pkg) {
            $magentoVersion = $pkg["extra"]["magento_version"] ?? "";
            if ($magentoVersion === $argv[1] || str_starts_with($magentoVersion, $argv[1] . "-")) {
                $match = $pkg["version"];
            }
        }
        echo $match;
    ' "${MAGENTO_VERSION}")"

    if [ -z "${MAGE_OS_PACKAGE_VERSION}" ]; then
        log "No Mage-OS release found for Magento ${MAGENTO_VERSION}. See https://repo.mage-os.org/p2/mage-os/product-community-edition.json for available versions."
        exit 1
    fi

    log "Creating Magento project (${MAGENTO_VERSION} via mage-os/project-community-edition=${MAGE_OS_PACKAGE_VERSION})..."
    composer create-project \
        --repository-url="${MAGE_OS_REPO}" \
        --no-interaction \
        --prefer-dist \
        "mage-os/project-community-edition=${MAGE_OS_PACKAGE_VERSION}" \
        "${MAGENTO_ROOT}" -vvv
else
    log "Magento already present at ${MAGENTO_ROOT}, skipping create-project."
fi

cd "${MAGENTO_ROOT}"

# The module's own composer.json declares the "gubee-sdk" VCS repository,
# but Composer only reads "repositories" from the *root* project, so it has
# to be registered here too or the private SDK dependency won't resolve.
# "no-api": true forces Composer to clone over git/SSH instead of going
# through the GitHub API for metadata, which needs its own OAuth token and
# fails here since we only have an SSH key, not a token.
if ! composer config repositories.gubee-module >/dev/null 2>&1; then
    log "Registering local module path repository..."
    composer config repositories.gubee-module path "${MODULE_ROOT}"
fi
if [ "$(composer config repositories.gubee-sdk 2>/dev/null)" != '{"type":"vcs","url":"git@github.com:maco-studios/gubee-php-sdk.git","no-api":true}' ]; then
    log "Registering gubee-php-sdk VCS repository..."
    composer config repositories.gubee-sdk '{"type": "vcs", "url": "git@github.com:maco-studios/gubee-php-sdk.git", "no-api": true}'
fi

# gubee-marketplace/php-sdk is only published as a "dev-main" branch (no
# tagged releases), which Magento's default "stable" minimum-stability
# rejects even though it's an unambiguous, exact version constraint.
composer config minimum-stability dev
composer config prefer-stable true

if [ ! -d "${MAGENTO_ROOT}/vendor/gubee-marketplace/integration-module" ]; then
    log "Requiring gubee-marketplace/integration-module..."
    composer require --no-interaction gubee-marketplace/integration-module:@dev
else
    log "Module already required, running composer update for it..."
    composer update --no-interaction gubee-marketplace/integration-module gubee-marketplace/php-sdk
fi

if [ ! -f "${MAGENTO_ROOT}/app/etc/env.php" ]; then
    log "Running bin/magento setup:install..."
    php bin/magento setup:install \
        --base-url="http://localhost:${APP_PORT:-80}/" \
        --db-host=mysql \
        --db-name="${DB_DATABASE:-magento}" \
        --db-user="${DB_USERNAME:-magento}" \
        --db-password="${DB_PASSWORD:-magento}" \
        --admin-firstname=Gubee \
        --admin-lastname=Admin \
        --admin-email="${MAGENTO_ADMIN_EMAIL:-admin@example.com}" \
        --admin-user="${MAGENTO_ADMIN_USER:-admin}" \
        --admin-password="${MAGENTO_ADMIN_PASSWORD:-Admin123!}" \
        --language=en_US \
        --currency=USD \
        --timezone=America/Sao_Paulo \
        --use-rewrites=1 \
        --search-engine=opensearch \
        --opensearch-host=opensearch \
        --opensearch-port=9200 \
        --session-save=redis \
        --session-save-redis-host=redis \
        --session-save-redis-port=6379 \
        --session-save-redis-db=2 \
        --cache-backend=redis \
        --cache-backend-redis-server=redis \
        --cache-backend-redis-db=0 \
        --page-cache=redis \
        --page-cache-redis-server=redis \
        --page-cache-redis-db=1 \
        --amqp-host=rabbitmq \
        --amqp-port=5672 \
        --amqp-user="${RABBITMQ_USER}" \
        --amqp-password="${RABBITMQ_PASSWORD}" \
        --amqp-virtualhost="${RABBITMQ_VHOST:-/}" \
        --backend-frontname=admin
else
    log "Magento already installed (app/etc/env.php present), skipping setup:install."
fi

log "Enabling Gubee_Integration and applying schema/data patches..."
php bin/magento module:enable Gubee_Integration
php bin/magento module:disable Magento_TwoFactorAuth
php bin/magento setup:upgrade
php bin/magento setup:di:compile

# phpserver/router.php strips the "version<timestamp>/" segment from static
# URLs before checking if the file already exists on disk, but when it falls
# through to pub/static.php to generate a missing file on the fly, Magento's
# own request parsing still sees the un-stripped version segment in
# REQUEST_URI and rejects it ("Requested path ... is wrong"), 404ing every
# static asset. Unversioned static URLs go through fine, so drop the version
# signature to match what this router can actually serve.
php bin/magento config:set dev/static/sign 0
php bin/magento cache:flush

log "Ready. Storefront: http://localhost:${APP_PORT:-80}/  Admin: http://localhost:${APP_PORT:-80}/admin"
log "MinIO is up for future remote-storage wiring but its bucket isn't auto-created; run 'mc mb' against it if you configure remote storage."
