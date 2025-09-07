FROM alpine:latest

# Install OpenSSH
RUN apk add --no-cache openssh

# Create a non-root user and unlock it
RUN adduser -D igor04091968 && passwd -u igor04091968

# Set up SSH for the new user
USER igor04091968
WORKDIR /home/igor04091968
RUN mkdir .ssh && chmod 700 .ssh

# Add the public key
RUN echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA+ae2Y4jjLBxGGoZvucdQl4JUSKP7A8vn9BtkuWXv51 root@ruvds-b00ki" >> .ssh/authorized_keys
RUN chmod 600 .ssh/authorized_keys

# Switch back to root to finalize setup
USER root

# Generate host keys
RUN ssh-keygen -A

# Expose port 22
EXPOSE 22

# Start SSH server in the foreground
CMD ["/usr/sbin/sshd", "-D", "-e"]