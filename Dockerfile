FROM azul/zulu-openjdk:latest
#FROM kurron/docker-azul-jdk-8-build:latest
#FROM ubuntu:16.04

ARG nixuser
ENV ENVSDIR /home/$nixuser
ENV HOME $ENVSDIR
WORKDIR $ENVSDIR

MAINTAINER Brandon Barker <brandon.barker@cornell.edu>

RUN rm -fr /home/$nixuser && \
  adduser --disabled-password --gecos "" $nixuser && \
  echo "$nixuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
  chown -R $nixuser:$nixuser $ENVSDIR && \
  mkdir -m 0755 /nix && \
  chown -R $nixuser:$nixuser /nix
  
RUN echo "nameserver 8.8.8.8" | tee /etc/resolv.conf > /dev/null && \
  apt-get update -y && apt-get install -y --no-install-recommends bzip2 ca-certificates wget

RUN echo "nixbld:x:30000:nixbld1,nixbld2,nixbld3,nixbld4,nixbld5,nixbld6,nixbld7,nixbld8,nixbld9,nixbld10,nixbld11,nixbld12,nixbld13,nixbld14,nixbld15,nixbld16,nixbld17,nixbld18,nixbld19,nixbld20,nixbld21,nixbld22,nixbld23,nixbld24,nixbld25,nixbld26,nixbld27,nixbld28,nixbld29,nixbld30" >> /etc/group \
  && for i in $(seq 1 30); do echo "nixbld$i:x:$((30000 + $i)):30000:::" >> /etc/passwd; done 

COPY ./config.nix $ENVSDIR/.config/nixpkgs/
RUN chown -R $nixuser:$nixuser $ENVSDIR/.config

#
# Install a few additional Ubuntu packages that are tedious to do from Nix
#
RUN apt-get install -y --no-install-recommends x11-apps

USER $nixuser

RUN wget -O- http://nixos.org/releases/nix/nix-1.11.14/nix-1.11.14-x86_64-linux.tar.bz2 | bzcat - | tar xf - \
    && USER=$nixuser sh nix-*-x86_64-linux/install \

ENV \
    PATH=$nixuser/.nix-profile/bin:$nixuser/.nix-profile/sbin:/bin:/sbin:/usr/bin:/usr/sbin \
    GIT_SSL_CAINFO=$nixuser/.nix-profile/etc/ssl/certs/ca-bundle.crt \
    NIX_SSL_CERT_FILE=$nixuser/.nix-profile/etc/ssl/certs/ca-bundle.crt

ENV \
    PATH=$nixuser/.nix-profile/bin:$nixuser/.nix-profile/sbin:/bin:/sbin:/usr/bin:/usr/sbin \
    GIT_SSL_CAINFO=$nixuser/.nix-profile/etc/ssl/certs/ca-bundle.crt \
    NIX_SSL_CERT_FILE=$nixuser/.nix-profile/etc/ssl/certs/ca-bundle.crt \
    NIX_PATH=/nix/var/nix/profiles/per-user/$nixuser/channels/
  
ENV nixenv ". /home/$nixuser/.nix-profile/etc/profile.d/nix.sh"

RUN $nixenv && nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs && \
  nix-channel --add https://nixos.org/channels/nixos-unstable nixos
  
RUN $nixenv && nix-channel --update

COPY ./entrypoint ./scala-default.nix ./scala-build.sh $ENVSDIR/
#
# Initialize environment a bit for faster container spinup/use later
#
RUN $nixenv && cd /tmp && nix-env -if $ENVSDIR/scala-default.nix && printf 'exit\n' | sbt && \
  printf '\nsource $HOME/.nix-profile/etc/profile.d/nix.sh\n' >> $HOME/.bashrc

CMD ["./entrypoint"]

