FROM docker.elastic.co/logstash/logstash

# https://www.elastic.co/guide/en/logstash/current/docker-config.html
RUN rm -f /usr/share/logstash/pipeline/logstash.conf
COPY logstash.conf /usr/share/logstash/pipeline/logstash.conf

