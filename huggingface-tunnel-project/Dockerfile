# Base image
FROM alpine:latest

# Install packages
RUN apk add --no-cache openssh sshpass

# Set root password and configure SSH
RUN echo "root:Ckj;ysqgfhjkm" | chpasswd

# Copy configs
COPY sshd_config /etc/ssh/sshd_config

# Copy entrypoint and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose the port
EXPOSE 2222

ENTRYPOINT ["/entrypoint.sh"]
