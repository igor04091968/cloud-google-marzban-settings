# Base image
FROM alpine:latest

# Install packages - only stunnel and openssh-client are needed
RUN apk add --no-cache stunnel openssh-client iperf3

# Create a non-root user with UID 1000
RUN addgroup -g 1000 user && adduser -u 1000 -G user -h /home/user -s /bin/sh -D user

# Copy configs
COPY stunnel.conf /etc/stunnel/stunnel.conf

# Copy entrypoint and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to the new user
WORKDIR /home/user

# Expose the port that will be mapped by Hugging Face
EXPOSE 2222

ENTRYPOINT ["/entrypoint.sh"]
