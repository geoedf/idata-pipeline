# Instructions for Testing AuditBeat-Logstash-RabbitMQ Pipeline

In order to test the complete pipeline, Docker containers for the RabbitMQ server and 
workers for processing the message queues need to be started. We use Docker Compose 
to define this set of containers.

## Server

The server is a container built off the RabbitMQ base image that support custom management. 
We use the custom management configuration to predefine the necessary exchanges and queues 
for the various messages. Specifically, there are two separate queues; a catch-all queue for 
processing all incoming audit messages and a type-specific queue that uses "topics" to route 
file processing to the specific connector implementing that processing (raster, vector, etc.).
`Dockerfile-server` contains this container definition, `definitions.json` has the exchange and 
queue definitions.

## Workers

There are three different worker containers: catch-all worker `Dockerfile-all`, raster file worker `Dockerfile-raster`, 
and vector file worker `Dockerfile-vector`. Each of these containers runs a simple Python script that 
subscribes to the respective queue and topic and processes the incoming message. For now, the script 
simply outputs the file path to a temporary file. The catch-all worker's script `processfile.py` processes 
the incoming message, then based on the file extension creates and sends a new message with the appropriate 
routing key.


## Running the containers

To build the Docker container images, run:

```
sudo docker-compose build
```

Then run the server:

```
sudo docker-compose up rabbitmq-server
```

Next, run several copies of the workers (2 in this case):

```
sudo docker-compose scale rabbitmq-default-worker=2
sudo docker-compose scale rabbitmq-raster-worker=2
sudo docker-compose scale rabbitmq-vector-worker=2
```

## Testing

In order to test that the files get processed by the right containers, ssh into the containers and check 
the `/tmp/messages.txt` file.

```
sudo docker exec -it <container ID> /bin/bash
```
