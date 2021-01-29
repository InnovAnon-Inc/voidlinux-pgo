FROM innovanon/builder as bootstrap
RUN sleep 91                                                                                            \
 && curl -L --proxy $SOCKS_PROXY --retry 11          -o void-x86_64-ROOTFS-20191109.tar.xz              \
       https://alpha.de.repo.voidlinux.org/live/current/void-x86_64-ROOTFS-20191109.tar.xz              \
 && tar xf                                              void-x86_64-ROOTFS-20191109.tar.xz    -C /tmp/  \
 && curl -L --proxy $SOCKS_PROXY --retry 11 -o          xbps-static-latest.x86_64-musl.tar.xz           \
             https://alpha.de.repo.voidlinux.org/static/xbps-static-latest.x86_64-musl.tar.xz           \
 && tar xf                                              xbps-static-latest.x86_64-musl.tar.xz -C /tmp/tmp/

FROM scratch as voidlinux
COPY --from=bootstrap /tmp/ /

FROM voidlinux as droidlinux
COPY --from=bootstrap /etc/profile.d/support.sh      /etc/profile.d/
COPY --from=bootstrap /etc/sysctl.conf               /etc/sysctl.conf
COPY --from=bootstrap /usr/local/bin/support         /usr/local/bin/
ENV XBPS_ARCH=x86_64
RUN /tmp/usr/bin/xbps-install  -SyR https://alpha.us.repo.voidlinux.org/current
#RUN /tmp/usr/bin/xbps-install  -uyR https://alpha.us.repo.voidlinux.org/current xbps
RUN /tmp/usr/bin/xbps-install -SuyR https://alpha.us.repo.voidlinux.org/current
RUN              xbps-install   -y tor
COPY                 ./etc/profile.d/socksproxy.sh   /etc/profile.d/
COPY                 ./etc/xbps.d/                   /etc/xbps.d/
COPY                 ./usr/local/bin/support-wrapper /usr/local/bin/
SHELL ["/usr/bin/bash", "-l", "-c"]
ARG TEST
RUN tor --verify-config \
 && sleep 91            \
 && xbps-install -S

# TODO [CircleCI] Directory /var/lib/torcannot be read: Permission denied
FROM scratch as squash
COPY --from=droidlinux / /
RUN chown -R tor:tor /var/lib/tor
SHELL ["/usr/bin/bash", "-l", "-c"]
ARG TEST

FROM squash as test
ARG TEST
RUN tor --verify-config \
 && sleep 127           \
 && xbps-install -S     \
 && exec true || exec false

FROM squash as final

