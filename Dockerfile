# InvoicePlane v1.7.2 on Railway.
# Upstream publishes no release-tagged container image (c8n.io/mpldr/invoiceplane only has
# latest/dev/beta tags), so this builds the official release zip on the same base upstream's
# own Containerfile uses (php:8.2-apache), pinned by version and multi-arch digest.
# To update: bump IP_VERSION and IP_SHA256 together (the SHA-256 is in the release notes),
# check the PHP base, and add a CHANGELOG.md entry.
FROM php:8.2.36-apache@sha256:b90981025fa445ad7784981110e9423656409177f761eb67b13dc98861049d00

ARG IP_VERSION=v1.7.2
ARG IP_SHA256=5d70ca0c437e9a35bdadddb4bb98dc89f5cc19527d1dad214579db7d6292f2b8

# PHP extensions from upstream's resources/docker/Containerfile, plus opcache.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libfreetype6-dev libjpeg62-turbo-dev libpng-dev libxml2-dev libonig-dev libzip-dev unzip; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" bcmath gd mbstring mysqli opcache xml zip; \
    a2enmod rewrite remoteip; \
    apt-get clean; rm -rf /var/lib/apt/lists/*

# The release zip already contains vendor/ and the built assets. Copy only what upstream's
# Containerfile copies into the web root (no compose files, lock files or docs).
RUN set -eux; \
    curl -fsSL -o /tmp/ip.zip "https://github.com/InvoicePlane/InvoicePlane/releases/download/${IP_VERSION}/${IP_VERSION}.zip"; \
    echo "${IP_SHA256}  /tmp/ip.zip" | sha256sum -c -; \
    unzip -q /tmp/ip.zip -d /tmp/src; \
    rm -rf /var/www/html; mkdir -p /var/www/html; \
    cd /tmp/src/ip; \
    cp -a application assets vendor favicon.ico index.php robots.txt /var/www/html/; \
    cp -a htaccess /var/www/html/.htaccess; \
    mkdir -p /opt/invoiceplane; \
    cp -a uploads /opt/invoiceplane/uploads; \
    cp -a storage /opt/invoiceplane/storage; \
    cd /; rm -rf /tmp/ip.zip /tmp/src; \
    test -f /var/www/html/vendor/autoload.php; \
    test -f /var/www/html/assets/core/js/scripts.min.js

COPY rootfs /

# uploads/ and storage/ live on the Railway volume at /data (symlinks).
# AllowOverride All for InvoicePlane's .htaccess; no directory listings.
RUN set -eux; \
    ln -s /data/uploads /var/www/html/uploads; \
    ln -s /data/storage /var/www/html/storage; \
    sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf; \
    sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/Options Indexes FollowSymLinks/Options FollowSymLinks/' /etc/apache2/apache2.conf; \
    a2enconf railway >/dev/null; \
    sed -i "s#CustomLog \${APACHE_LOG_DIR}/access.log combined#CustomLog \${APACHE_LOG_DIR}/access.log combined env=!dontlog#" /etc/apache2/sites-available/000-default.conf; \
    grep -q "env=!dontlog" /etc/apache2/sites-available/000-default.conf; \
    chown -R www-data:www-data /var/www/html; \
    chmod 0755 /usr/local/bin/railway-start.sh /usr/local/bin/railway-db.php; \
    apache2ctl -t

# Railway routes the public domain to PORT; Apache listens on it (80 when unset).
# 8 Apache workers and a 256M PHP limit keep the service inside 0.5 GB of RAM.
ENV PORT=80 \
    TZ=UTC \
    APACHE_MAX_WORKERS=8
EXPOSE 80

ENTRYPOINT ["railway-start.sh"]
CMD []
