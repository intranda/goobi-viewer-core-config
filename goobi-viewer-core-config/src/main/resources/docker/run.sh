#!/bin/bash
set -e

[ -z "$CONFIGSOURCE" ] && CONFIGSOURCE="default"

set -u

echo "Setting database configuration from environment..."
envsubst '\$DB_SERVER \$DB_PORT \$DB_NAME \$DB_USER \$DB_PASSWORD' </usr/local/tomcat/conf/viewer.xml.template > /usr/local/tomcat/conf/Catalina/localhost/viewer.xml
envsubst '\$VIEWER_DOMAIN' </usr/local/tomcat/conf/server.xml.template >/usr/local/tomcat/conf/server.xml.template

echo "Settings SOLR URL from environment..."
sed -i "s|http://localhost:8983/solr/collection1|${SOLR_URL}|" /usr/local/tomcat/webapps/viewer/WEB-INF/classes/config_viewer.xml

#if [ -n "${WORKING_STORAGE:-}" ]
#then
  #CATALINA_TMPDIR="${WORKING_STORAGE}/goobi/jvmtemp"
  #mkdir -p "${CATALINA_TMPDIR}"
  #echo >> /usr/local/tomcat/bin/setenv.sh
  #echo "CATALINA_TMPDIR=${CATALINA_TMPDIR}" >> /usr/local/tomcat/bin/setenv.sh
#fi

case $CONFIGSOURCE in
  # s3)
  #   if [ -z "$AWS_S3_BUCKET" ]
  #   then
  #     echo "AWS_S3_BUCKET is required"
  #     exit 1
  #   fi
  #   echo "Pulling configuration from s3 bucket"
  #   aws s3 cp s3://$AWS_S3_BUCKET/goobi/config/ /opt/digiverso/goobi/config/ --recursive
  #   aws s3 cp s3://$AWS_S3_BUCKET/goobi/rulesets/ /opt/digiverso/goobi/rulesets/ --recursive
  #   aws s3 cp s3://$AWS_S3_BUCKET/goobi/xslt/ /opt/digiverso/goobi/xslt/ --recursive
  #   ;;
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
