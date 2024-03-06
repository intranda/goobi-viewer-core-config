#!/bin/bash

## CONFIG ##
VIEWERDBNAME="viewer"
VIEWERFOLDER="/opt/digiverso/viewer"
WWWFOLDER="/var/www"
SOLRURL=""

USAGE="script_create_package.sh -d VIEWERDBNAME -f /path/to/viewer -s https://viewer.example.org/solr/"
while getopts "d:f:w:s:h" OPCOES; do
        case $OPCOES in
                d ) VIEWERDBNAME="${OPTARG}";;
                f ) VIEWERFOLDER="${OPTARG}";;
                w ) WWWFOLDER="${OPTARG}";;
                s ) SOLRURL="${OPTARG}";;
                h ) echo "$USAGE"
                    exit 0;;
                * ) echo "$USAGE"
                    exit 1;;
        esac
done


TMPDIR=/tmp/viewerconfig
TEMPFILENAME="${VIEWERDBNAME}_developer.zip"

## ERROR HANDLING ##
type -P xmlstarlet &>/dev/null || { echo "ERROR: xmlstarlet does not exist. Aborting" >&2; exit 1; }
type -P zip &>/dev/null || { echo "ERROR: zip does not exist. Aborting" >&2; exit 1; }

if [ ! -d "${VIEWERFOLDER}" ] ; then
  echo "ERROR: The given path ${VIEWERFOLDER} does not exist or is not a directory." >&2;
  exit 1
fi

if [ ! -f "${VIEWERFOLDER}/config/config_viewer.xml" ] ; then
  echo "ERROR: There is no file config_viewer.xml at the given path ${VIEWERFOLDER}/config/." >&2;
  exit 1
fi

if [ ! -d "${WWWFOLDER}" ] ; then
  echo "ERROR: The given path ${WWWFOLDER} does not exist or is not a directory." >&2;
  exit 1
fi


if [ -f /tmp/viewerconfig.lock ]; then
        echo "Script already running..."
        exit 1
fi
touch /tmp/viewerconfig.lock

# Delete old files
if [ -f ${WWWFOLDER}/developer.html ]; then
        rm ${WWWFOLDER}/developer.html
fi

if [ -f ${WWWFOLDER}/${VIEWERDBNAME}_*.zip ]; then
        rm ${WWWFOLDER}/${VIEWERDBNAME}_*.zip
fi

if [ ! -d "${TMPDIR}" ] ; then
	mkdir "${TMPDIR}"
fi

# Copy needed files
cp ${VIEWERFOLDER}/config/config_viewer.xml $TMPDIR

for f in ${VIEWERFOLDER}/config/messages_*.properties; do
        [ -e "${f}" ] && cp ${f} ${TMPDIR}
done

if [ -f ${VIEWERFOLDER}/config/config_viewer-module-crowdsourcing.xml ]; then
  cp ${VIEWERFOLDER}/config/config_viewer-module-crowdsourcing.xml $TMPDIR
fi

dump_file=$TMPDIR/viewer.sql

mysqldump $VIEWERDBNAME --ignore-table=viewer.crowdsourcing_fulltexts > $dump_file

echo "DROP TABLE IF EXISTS \`users\`;" >> "$dump_file"
echo "CREATE TABLE \`users\` (
            \`user_id\` bigint(20) NOT NULL AUTO_INCREMENT,
            \`activation_key\` varchar(255) DEFAULT NULL,
            \`active\` tinyint(1) NOT NULL DEFAULT 0,
            \`comments\` varchar(255) DEFAULT NULL,
            \`email\` varchar(255) NOT NULL,
            \`first_name\` varchar(255) DEFAULT NULL,
            \`last_login\` datetime DEFAULT NULL,
            \`last_name\` varchar(255) DEFAULT NULL,
            \`nickname\` varchar(255) DEFAULT NULL,
            \`password_hash\` varchar(255) DEFAULT NULL,
            \`score\` bigint(20) DEFAULT NULL,
            \`superuser\` tinyint(1) NOT NULL DEFAULT 0,
            \`suspended\` tinyint(1) NOT NULL DEFAULT 0,
            \`agreed_to_terms_of_use\` tinyint(1) DEFAULT 0,
            \`avatar_type\` varchar(255) DEFAULT NULL,
            \`local_avatar_updated\` bigint(20) DEFAULT NULL,
             PRIMARY KEY (\`user_id\`),
             KEY \`index_users_email\` (\`email\`)
             ) ENGINE=InnoDB AUTO_INCREMENT=191 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;" >> "$dump_file"
echo "INSERT INTO users (active,email,password_hash,score,superuser) VALUES (1,\`goobi@intranda.com\`,
            \`\$2a\$10\$Z5GTNKND9ZbuHt0ayDh0Remblc7pKUNlqbcoCxaNgKza05fLtkuYO\`,0,1);" >> "$dump_file"


# Extract information from config_viewer.xml
# If the RESTURL is missing the script will stop here because xmlstarlet will exit with 1.
# please add the information mentioned here and run again:
#   https://docs.goobi.io/goobi-viewer-de/devop/1#2019-07-06
THEMENAME=$(xmlstarlet sel -t -v '//config/viewer/theme/@mainTheme' ${VIEWERFOLDER}/config/config_viewer.xml)
RESTURL=$(xmlstarlet sel -t -v '//config/urls/rest' ${VIEWERFOLDER}/config/config_viewer.xml)

# as the solr is always asked via http and localhost but sometimes in rare cases does not have collection1
# we need to generate the developer URL from the base url from REST and folders from solr
#
# ... but only in case we did not
sed -i "s/<solr>.*<\/solr>/<solr>${SOLRURL}<\/solr>/g" $TMPDIR/config_viewer.xml

# replace rest with iiif
sed -i "s/<rest>\(.*\)<\/rest>/<iiif>\1<\/iiif>/g" $TMPDIR/config_viewer.xml

# add rest to localhost url
sed -i 's/<\/iiif>/<\/iiif>\n<rest>http:\/\/localhost:8080\/viewer\/api\/v1\/<\/rest>/g' $TMPDIR/config_viewer.xml

# remove theme/rootPath configuration. This is done to avoid errors when deplying the config on a system with no local theme repository
sed -i '/<rootPath>.*<\/rootPath>/d' $TMPDIR/config_viewer.xml

# create zip file
zip -rq ${WWWFOLDER}/$TEMPFILENAME $TMPDIR
#zip -rq - $TMPDIR > /dev/stdout

# delete temp dir
rm -rf $TMPDIR

# must write this to output to inform viewer of path to zip file
echo "${WWWFOLDER}/$TEMPFILENAME"

rm /tmp/viewerconfig.lock
