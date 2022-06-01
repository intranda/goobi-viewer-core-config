#!/bin/bash
set -e

[ -z "$CONFIGSOURCE" ] && CONFIGSOURCE="default"

set -u

echo "Setting database configuration from environment..."
envsubst '\$DB_SERVER \$DB_PORT \$DB_NAME \$DB_USER \$DB_PASSWORD' </usr/local/tomcat/conf/viewer.xml.template > /usr/local/tomcat/conf/Catalina/localhost/viewer.xml
envsubst '\$VIEWER_DOMAIN' </usr/local/tomcat/conf/server.xml.template >/usr/local/tomcat/conf/server.xml
envsubst '\$TOMCAT_SAMESITECOOKIES' </usr/local/tomcat/conf/context.xml.template >/usr/local/tomcat/conf/context.xml

echo "Setting SOLR URL from environment..."
sed -i "s|http://localhost:8983/solr/collection1|${SOLR_URL}|" /usr/local/tomcat/webapps/viewer/WEB-INF/classes/config_viewer.xml
sed -i "s|http://localhost:8983/solr/collection1|${SOLR_URL}|" /usr/local/tomcat/webapps/viewer/WEB-INF/classes/config_oai.xml

case $CONFIGSOURCE in
  folder)
    if [ -z "$CONFIG_FOLDER" ]
    then
      echo "CONFIG_FOLDER is required"
      exit 1
    fi

    if ! [ -d "$CONFIG_FOLDER" ]
    then
      echo "CONFIG_FOLDER: $CONFIG_FOLDER does not exists or is not a folder"
      exit 1
    fi
    
    echo "Copying configuration from local folder"
    [ -d "$CONFIG_FOLDER" ] && cp -av "$CONFIG_FOLDER"/* /opt/digiverso/viewer/config/ 
    ;;

  *)
    echo "Keeping configuration"
    ;;
esac

echo "Starting application server..."
exec catalina.sh run
