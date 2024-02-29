#!/bin/bash
      if [ ! -f "/home/centos/.env" ]; then
        sudo touch /home/centos/.env
      fi
      sudo echo "DB_HOST=${db_host}" > /home/centos/.env
      sudo echo "DB_USER=${db_user}" >> /home/centos/.env
      sudo echo "DB_PASSWORD=${db_password}" >> /home/centos/.env
      sudo echo "DB_DATABASE=${db_database}" >> /home/centos/.env