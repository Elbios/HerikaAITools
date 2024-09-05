# Use Debian 12 (bookworm) as the base image
FROM debian:bookworm

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Create the 'dwemer' user and set up the home directory
RUN useradd -m -s /bin/bash dwemer

# Install Apache, PostgreSQL, PHP, and other necessary services
RUN apt-get update && apt-get install -y \
    apache2 \
    php \
    libapache2-mod-php \
    postgresql \
    postgresql-contrib \
    && rm -rf /var/lib/apt/lists/*

# Set up Apache, PHP, PostgreSQL config by copying your configuration files
# Copy Apache configuration
COPY ./distro/etc/apache2/ /etc/apache2/

# Copy PHP configuration
COPY ./distro/etc/php/ /etc/php/

# Copy PostgreSQL configuration
COPY ./distro/etc/postgresql/ /etc/postgresql/
COPY ./distro/etc/postgresql-common/ /etc/postgresql-common/

# Copy specific files from /etc
COPY ./distro/etc/ddistro-full-packages.txt /etc/ddistro-full-packages.txt
COPY ./distro/etc/ddistro-min-packages.txt /etc/ddistro-min-packages.txt
COPY ./distro/etc/start_env /etc/start_env

COPY ./all_debian_packages.txt /etc/all_debian_packages.txt

# Copy Dwemer helper binaries
COPY ./distro/usr/local/bin /usr/local/bin

# Copy user home directory data for 'dwemer'
COPY ./distro/home/dwemer/ /home/dwemer/

# Copy Apache web server files
COPY ./distro/var/www/html/ /var/www/html/

# Change ownership of the home directory and web files to 'dwemer'
RUN chown -R dwemer:dwemer /home/dwemer/ && \
    chown -R www-data:www-data /var/www/html/

# Expose necessary ports (e.g., for Apache and PostgreSQL)
EXPOSE 80 5432

COPY ./distro/etc/apt/sources.list /etc/apt/sources.list

RUN apt-get update

RUN dpkg --set-selections < /etc/all_debian_packages.txt

RUN apt-get update

RUN apt-get dselect-upgrade

# Run installation for CUDA, minime, mimic, xtts
RUN /usr/local/bin/install_full_packages

USER dwemer

RUN /home/dwemer/minime-t5/ddistro_install.sh
RUN /home/dwemer/mimic3/ddistro_install.sh
RUN /home/dwemer/xtts-api-server/ddistro_install.sh

# Start services by default when the container runs
# Assuming you have a start script /etc/start_env, we'll use it to start the environment
CMD ["/bin/bash", "/etc/start_env"]
