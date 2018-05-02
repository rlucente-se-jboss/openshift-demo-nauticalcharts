echo "	--> Create a new application from the mysql-ephemeral template"
oc get dc/mysql || oc new-app mysql-ephemeral --name=mysql -l app=${OPENSHIFT_APPLICATION_NAME},part=backend --param=MYSQL_USER=myphp --param=MYSQL_PASSWORD=myphp --param=MYSQL_DATABASE=myphp || { echo "FAILED: Could find or create the application" && exit 1; }
echo "	--> and for convenience, lets group it with the original php service"
oc get svc/php && oc patch svc/php -p '{"metadata" : { "annotations" : { "service.alpha.openshift.io/dependencies" : "[ { \"name\" : \"mysql\" , \"kind\" : \"Service\"  } ]" } } }' || { echo "FAILED: Could not patch app=${OPENSHIFT_APPLICATION_NAME},part=backend" && exit 1; }

echo "	--> Waiting for the mysql application to start....press any key to proceed"
while ! oc get pods | grep mysql | grep -v deploy | grep Running ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""

echo "	--> Verify the database automatically"
## OPENSHIFT_APPLICATION_MYSQL_PODS=`oc get pods -o jsonpath='{.items[*].metadata.name}' | grep -o '\bmysql[-a-zA-Z0-9]*\b'`
oc rsh dc/mysql /bin/sh -c 'echo -e "show tables;\nselect * from visitors;\n quit\n" | /opt/rh/rh-mysql57/root/usr/bin/mysql -h 127.0.0.1 -u myphp -P 3306 -D myphp -p myphp'
echo "	--> To verify database manually:" 
cat << EOF_SAMPLE_APPLICATION_DATABASE_MANUAL_VERIFICATION 
	oc rsh dc/mysql

	mysql -h 127.0.0.1 -u myphp -P 3306 -D myphp -p myphp
	show tables;
	select * from visitors;
	quit
	exit
EOF_SAMPLE_APPLICATION_DATABASE_MANUAL_VERIFICATION

echo "	--> Adding database connection parameters to frontend"
oc env dc/php MYSQL_SERVICE_HOST=mysql.${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}.svc.cluster.local MYSQL_SERVICE_PORT=3306 MYSQL_SERVICE_DATABASE=myphp MYSQL_SERVICE_USERNAME=myphp MYSQL_SERVICE_PASSWORD=myphp
echo "	--> Adding database connection parameters to backend"
oc env dc/mysql MYSQL_USER=myphp MYSQL_PASSWORD=myphp MYSQL_DATABASE=myphp
echo "	--> Waiting for pods to restart"
sleep 5s;
echo "	--> Waiting for application to detect database"
while ! curl -L -s 'http://php-'${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}'.'${OPENSHIFT_APPS} | grep -o "Database is available" ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""

echo "	--> Verify the frontend is connected to the backend"
curl -L -s 'http://php-'${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}'.'${OPENSHIFT_APPS} | grep -o "Database is available" || echo "ERROR: Could not verify the php frontend is connected to the mysql backend"


echo "Done."