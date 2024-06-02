FROM archlinux:latest as buildlayer

# Update system and install dependencies
RUN pacman -Syyu --noconfirm && \
    pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -S --needed --noconfirm git base-devel cmake sudo \
    libvncserver pcre vlc opencv-cuda nginx fcgiwrap spawn-fcgi

# Add sudoers entry for nobody user
RUN echo "nobody ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/nobody

# Install yay for AUR package management
RUN su -s /bin/bash nobody -c "cd /tmp/ && git clone https://aur.archlinux.org/yay.git" && \
    mkdir --mode=777 -p /.cache/go-build && \
    su -s /bin/bash nobody -c "cd /tmp/yay/ && makepkg -si --noconfirm"

# Install AUR packages
RUN su -s /bin/bash nobody -c "yay -S --noconfirm --norebuild --noredownload pod2man zoneminder zmeventnotification"

# Prepare directories and permissions
RUN touch /var/log/zm.log && chown http:http /var/log/zm.log && \
    mkdir -p /run/fcgiwrap/ && chown http:http /run/fcgiwrap/

################### Create DB
FROM mariadb:latest as zmdb
COPY --from=buildlayer /usr/share/zoneminder/db/zm_create.sql /docker-entrypoint-initdb.d/zm_create.sql
COPY --from=buildlayer /usr/share/zoneminder/db/ /usr/share/zoneminder/db/

################### Create Zoneminder
FROM buildlayer as zm
COPY ./dockerinit.sh /dockerinit.sh
COPY ./nginx.conf /etc/nginx/nginx.conf
CMD ["/dockerinit.sh"]
