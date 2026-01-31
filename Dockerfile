FROM ghcr.io/quantcdn-templates/app-apache-php:8.4

# Set working directory
WORKDIR /var/www/html

# Copy dependency files first (changes occasionally)
COPY src/composer.json src/composer.lock* ./

# Install PHP dependencies (cached until composer files change)
RUN set -eux; \
    export COMPOSER_HOME="$(mktemp -d)"; \
    composer config apcu-autoloader true; \
    composer install --optimize-autoloader --apcu-autoloader --no-dev --no-scripts; \
    rm -rf "$COMPOSER_HOME"

# Configure Apache DocumentRoot for Craft CMS web directory (web/ not public/)
RUN sed -i 's!/var/www/html!/var/www/html/web!g' /etc/apache2/sites-available/000-default.conf && \
    # Update the quant-host-snippet include path
    sed -i 's!/DocumentRoot /var/www/html!/DocumentRoot /var/www/html/web!' /etc/apache2/sites-available/000-default.conf

# Add Craft-specific PHP configuration
RUN { \
        echo 'max_execution_time = 120'; \
        echo 'upload_max_filesize = 100M'; \
        echo 'post_max_size = 100M'; \
    } > /usr/local/etc/php/conf.d/99-craft-cms.ini

# Include Quant config (synced into site root at runtime)
COPY quant/ /quant/
RUN chmod +x /quant/entrypoints.sh && \
    if [ -d /quant/entrypoints ]; then find /quant/entrypoints -type f -exec chmod +x {} \; ; fi

# Copy Quant PHP configuration files if any exist (allows users to add custom PHP configs)
RUN mkdir -p /quant/php.ini.d
COPY quant/php.ini.d/ /usr/local/etc/php/conf.d/

# Copy source code (changes frequently - do this last!)
COPY src/ /var/www/html/

# Final setup that depends on source code
RUN set -eux; \
    # Run the Composer scripts that were skipped during install
    export COMPOSER_HOME="$(mktemp -d)"; \
    composer dump-autoload --optimize --apcu --no-dev || true; \
    rm -rf "$COMPOSER_HOME"; \
    # Set up permissions for Craft CMS directories
    mkdir -p /var/www/html/storage /var/www/html/web/cpresources /var/www/html/config; \
    chown -R www-data:www-data /var/www/html; \
    chmod -R 775 /var/www/html/storage /var/www/html/web/cpresources /var/www/html/config

# Set PATH to include vendor binaries
ENV PATH=${PATH}:/var/www/html/vendor/bin

# Expose port 80
EXPOSE 80

# Use Quant entrypoints as the main entrypoint
ENTRYPOINT ["/quant/entrypoints.sh", "docker-php-entrypoint"]
CMD ["apache2-foreground"]
