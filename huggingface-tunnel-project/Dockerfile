# Base image
FROM alpine:latest

# Install packages
RUN apk add --no-cache stunnel openssh iperf3

# Create a non-root user with UID 1000
RUN addgroup -g 1000 user && adduser -u 1000 -G user -h /home/user -s /bin/sh -D user

# Create SSH directory for the new user and add authorized keys
RUN mkdir -p /home/user/.ssh && \
    chmod 700 /home/user/.ssh && \
    echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIG17gM3oWQd0bw2L+DG0UZZEvAh/gOa2PsqwKRWLptikxruaNBezdE1aaGkU2gqTqCoUERXeUAU7ICjyWC6t88vsNNYlCYhIqUDiEhIrwoCNFLXcT0Nb0I0V3JNHmLo0328E/h22nOYdkrA/n87ngYmhAyhVzm4CBls2LDQjo2v1i8/99cb+B84IpL7a8RspeqFC7Al4UpYAB1Rw7vVfW84wLOb/ZUoDMDmqW1L0jDeSRee6Lz4u4PRmyh/0MCEnj9lD8TCa0JH/xEKLxHA7LflQEMCpnp/pE2yi8qXXJkvV3EAAKd7fVMxWIGI98Qd6OwBTb3e45tHLnooCM1bHIjeuo5mAss7gPRqE8++lOhFsOTG+6VYuJFSWAanB0HPoRCT9BBOqbdUi3rVrVrARmf7KDMkAk0V9oHox9CQMasZDHnq1PhcYFczoImDOgodzYS64llPLo3nqtrjdn7jycWLNdJHIY6qKif+Xgj6fzIEfErBTvJiwK0vFjcS2R8+ptC6Sf2YvxSB+S6R2Lqm9zrYFeM52cvDBGZJFpN6EZw9T5K95GyovCgFgCYWWOpWsxiJVruDcBGHbEJjUxWGRanRFUtq6WOcJ2YIn0+K5l/lMjE2f3PDPPw3bSTYrmE3UrUstnCAWi7hL27rKGcTmwBSSnmYJStGWkR099enw== igor04091968@cs-1030016233626-default' >> /home/user/.ssh/authorized_keys && \
    echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBCo7nqAnebsAnY7Hw0hgwHEcKwYixwdNjKKfpO8vveJvbL1lHpfXpx4L23waOOE064TF8AebDqT9dBp58510xWbNr1Q4sb9YNkcrDjf+bqL23u4JaTiesZtake2JMpKiuuCqSJ5u8wKcy7qr+RG0hpY2rYE7TjdjQRTD4W8WbPWbWdXXL7Umm9XCMw11v+NyC2OPIO3IRWPqdQ6ZUYnsg4a0RQiQS/C03944WbB9Q6ZBkNidnK1lGGVcvppQHQVsFQ0c09VSIlw0gvuVV3VHMluLzcbf+nv4Z0GtDUtdqVK4Z3RxWHo5ozSFKGfyRm/Ntl6zmzH2g53SBLlHXrpYFF/S2qO4cNmQlhzVPuGEzXbaTiTrS2OOOLmaNyt7Xl4eTcVhYxtGX34Z6XBXGjqgBFaES6T0lX5mt6i7+SJ1BT6xHwx44dJTDsl8w+BkCqoZzoO73K6ztmKu8r4ZAcs6GW5y7efg7vZSmffNrSjsNzBRwcS0CfHkLcBXdbcxtyIk7Zx15C6vKVzu2T4ahXyp9Nx2giVdUD7KMDYzbNWSc1kOcwRdSeW+YHOcRdyAKK8SnREKpv9/TwMMuYR1m3zkkQOhhud4zkNODdSpf6YUvMFlQDdbbyHgqJNi5lbjW2TOnP9mZpPaC3gI4EW64fFWGRonC21B2xQkJzHo4xW3KTQ== root@ruvds-b00ki' >> /home/user/.ssh/authorized_keys && \
    chown -R user:user /home/user/.ssh

# Copy configs
COPY stunnel.conf /etc/stunnel/stunnel.conf
COPY sshd_config /etc/ssh/sshd_config

# Copy entrypoint and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh



# Switch to the new user

WORKDIR /home/user

# Expose the port that will be mapped by Hugging Face
EXPOSE 2222

ENTRYPOINT ["/entrypoint.sh"]