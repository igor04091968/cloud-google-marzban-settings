# Base image
FROM alpine:latest

# Install packages
RUN apk add --no-cache stunnel openssh iperf3

# Create SSH directories and generate host keys for the container's sshd
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh && ssh-keygen -A

# Copy configs
COPY stunnel.conf /etc/stunnel/stunnel.conf
COPY sshd_config /etc/ssh/sshd_config

# Copy entrypoint and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Add public keys to authorized_keys
# Note: For a real Hugging Face Space, it's better to manage keys via Space Secrets.
# This is included for reproducibility of the original environment.
RUN echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIG17gM3oWQd0bw2L+DG0UZZEvAh/gOa2PsqwKRWLptikxruaNBezdE1aaGkU2gqTqCoUERXeUAU7ICjyWC6t88vsNNYlCYhIqUDiEhIrwoCNFLXcT0Nb0I0V3JNHmLo0328E/h22nOYdkrA/n87ngYmhAyhVzm4CBls2LDQjo2v1i8/99cb+B84IpL7a8RspeqFC7Al4UpYAB1Rw7vVfW84wLOb/ZUoDMDmqW1L0jDeSRee6Lz4u4PRmyh/0MCEnj9lD8TCa0JH/xEKLxHA7LflQEMCpnp/pE2yi8qXXJkvV3EAAKd7fVMxWIGI98Qd6OwBTb3e45tHLnooCM1bHIjeuo5mAss7gPRqE8++lOhFsOTG+6VYuJFSWAanB0HPoRCT9BBOqbdUi3rVrVrARmf7KDMkAk0V9oHox9CQMasZDHnq1PhcYFczoImDOgodzYS64llPLo3nqtrjdn7jycWLNdJHIY6qKif+Xgj6fzIEfErBTvJiwK0vFjcS2R8+ptC6Sf2YvxSB+S6R2Lqm9zrYFeM52cvDBGZJFpN6EZw9T5K95GyovCgFgCYWWOpWsxiJVruDcBGHbEJjUxWGRanRFUtq6WOcJ2YIn0+K5l/lMjE2f3PDPPw3bSTYrmE3UrUstnCAWi7hL27rKGcTmwBSSnmYJStGWkR099enw== igor04091968@cs-1030016233626-default' >> /root/.ssh/authorized_keys

# The private key for vds1 will be mounted or injected as a secret.

# Expose the port that will be mapped by Hugging Face
EXPOSE 2222

ENTRYPOINT ["/entrypoint.sh"]
