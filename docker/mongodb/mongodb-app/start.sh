#!/bin/bash

mkdir -p /data/db

exec /bin/mongod --dbpath /data/db --logpath /var/log/mongodb/mongo.log --noprealloc --smallfiles
