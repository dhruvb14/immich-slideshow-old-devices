# Base image with PHP-FPM
FROM php:8.5-fpm

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    nginx \
    libfreetype-dev \
	libjpeg62-turbo-dev \
	libpng-dev \
	libwebp-dev \
    libcurl4-openssl-dev \
    && docker-php-ext-install curl \
    && docker-php-ext-configure gd --with-webp --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Use the production PHP configuration (fatals become clean 500s and go to the
# container log instead of the response body) and raise the memory limit
# (image processing of large photos needs headroom)
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && printf "memory_limit=256M\nexpose_php=Off\n" > /usr/local/etc/php/conf.d/zz-app-overrides.ini

# Copy Nginx configuration and handle symbolic link
COPY nginx.conf /etc/nginx/sites-available/default
# Remove existing link if it exists and then create it
RUN rm -f /etc/nginx/sites-enabled/default && ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY public/ .

# Give permissions to www-data user
RUN chown -R www-data:www-data /var/www/html

# Expose port 80
EXPOSE 80

# Copy entry script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Use the script as entry point
ENTRYPOINT ["entrypoint.sh"]