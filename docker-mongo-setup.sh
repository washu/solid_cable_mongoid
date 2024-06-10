#!/bin/bash
docker run --rm -d -p 27017:27017 -h localhost --name mongo mongo:6.0.5 --replSet=test && sleep 5 && docker exec mongo mongosh --quiet --eval "rs.initiate();"
