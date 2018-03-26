#!/bin/sh
if [ -z "$1" ]
  then
    echo "Please put your RDS endpoint"
    exit 1
fi
sudo apt-get --yes update
sudo apt-get --yes install build-essential python
sudo apt-get --yes install python-setuptools
sudo apt-get --yes install python-dev
sudo apt-get --yes install nginx
sudo apt-get --yes install upstart
mysql -h $1 -u root --password=uisaws123 < earthquake.sql
sudo /etc/init.d/nginx start
sudo easy_install pip
sudo pip install virtualenv
virtualenv venv
. venv/bin/activate
pip install -r requirements.txt
deactivate
python nginx_conf_maker.py
sudo systemctl stop aws_app
sudo service nginx stop
sed -i "s?DB_HOST=.*?\DB_HOST=\"$1\"?" views.py

sed -i "s?WorkingDirectory=.*?\WorkingDirectory=$(pwd)?" aws_app.service
sed -i "s?Environment=.*?\Environment=\"PATH=$(pwd)/venv/bin\"?" aws_app.service
sed -i "s?ExecStart=.*?\ExecStart=$(pwd)/venv/bin/uwsgi --ini aws_app.ini?" aws_app.service

sudo chown -R www-data:www-data static/uploadedimages/
sudo rm -r /etc/nginx/sites-enabled/aws_app_nginx.conf
sudo rm -r /etc/systemd/system/aws_app.service
sudo ln -s aws_app_nginx.conf /etc/nginx/sites-enabled
sudo ln -s aws_app.service /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl start aws_app
sudo service nginx start
