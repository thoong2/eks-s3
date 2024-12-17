FROM amazonlinux:2

RUN yum install -y aws-cli

COPY script.sh /app/script.sh
RUN chmod +x /app/script.sh

CMD ["/app/script.sh"]
