FROM alpine:latest

# Install packages
RUN apk add --no-cache stunnel openssh

# Create SSH directories and generate host keys for the container's sshd
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh && ssh-keygen -A

# Copy configs
COPY config/stunnel.conf /etc/stunnel/stunnel.conf
COPY config/sshd_config /etc/ssh/sshd_config

# Copy entrypoint and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Add all public keys to authorized_keys
RUN echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIG17gM3oWQd0bw2L+DG0UZZEvAh/gOa2PsqwKRWLptikxruaNBezdE1aaGkU2gqTqCoUERXeUAU7ICjyWC6t88vsNNYlCYhIqUDiEhIrwoCNFLXcT0Nb0I0V3JNHmLo0328E/h22nOYdkrA/n87ngYmhAyhVzm4CBls2LDQjo2v1i8/99cb+B84IpL7a8RspeqFC7Al4UpYAB1Rw7vVfW84wLOb/ZUoDMDmqW1L0jDeSRee6Lz4u4PRmyh/0MCEnj9lD8TCa0JH/xEKLxHA7LflQEMCpnp/pE2yi8qXXJkvV3EAAKd7fVMxWIGI98Qd6OwBTb3e45tHLnooCM1bHIjeuo5mAss7gPRqE8++lOhFsOTG+6VYuJFSWAanB0HPoRCT9BBOqbdUi3rVrVrARmf7KDMkAk0V9oHox9CQMasZDHnq1PhcYFczoImDOgodzYS64llPLo3nqtrjdn7jycWLNdJHIY6qKif+Xgj6fzIEfErBTvJiwK0vFjcS2R8+ptC6Sf2YvxSB+S6R2Lqm9zrYFeM52cvDBGZJFpN6EZw9T5K95GyovCgFgCYWWOpWsxiJVruDcBGHbEJjUxWGRanRFUtq6WOcJ2YIn0+K5l/lMjE2f3PDPPw3bSTYrmE3UrUstnCAWi7hL27rKGcTmwBSSnmYJStGWkR099enw== igor04091968@cs-1030016233626-default' >> /root/.ssh/authorized_keys && 
    echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC12yt6USMAgZ40qjEYielLmQAQkGF2iT6Ff0aCedT6iySrzd5PoJuXv4DZTE5iIwCCINOUz1d+kdYSg79ect5MC9bqfwHNJXSCrJLSJbrmCkOQ9b/dY6noBzbiap7py2srHVnfsOGXln9rJlikX43nTzcpjs8ocPbLNkrQloYW2QJFQ9Pltjd7KacZp2ZKJ97zay3M8MsSZQnLCM+NHagudE1dXgIbNN17vz4N3fq9Hjs7+UWIRVNduW998/OrZoEIpYYQ//6+Ox14m3GLTXy9Njp1DF+LrBdV3E7zKcXpuDdNt8fUu3Ad8JQQV9E/isxcBU4/ugtiwFKSyoTiyqquk75NPRAAmMiXAqK817O7JpqGPme0CXOGoRnaQucxMN6l9CT215ne80Y1FtnvRRfvyI6v7ayz6O1Katx84vK+mgwrQpHPGqqVifEEMjGR/c+qwjyoVFbecsvk2sMnrsYKOwZVUOf2L0YKTuq34jQndhHOJSEpK4gOWFC2JCzdorenTyPt/XRU/Ebm3voyHkITUISVauORWGxKi1s6EEbqEfD7dH7Yij9YIWscJ6RphJV34KNCR8bUUM+JVEWAS0n6PjMIopAbbZ7FhRpGo6hzH7Uh0s7+n//hhJDBY1lzKfSVBARBEeBS51oOIkG5BEqL8VCb17jYxtWpLpigPuSgwQ== igorivanovich04091968@cs-590205348487-default' >> /root/.ssh/authorized_keys

# The private key for vds1 will be mounted at /root/.ssh/id_rsa_vds1
# The user will need to provide it at runtime.

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
