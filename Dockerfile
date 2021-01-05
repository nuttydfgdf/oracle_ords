# ------------------------------------------------------------------------------
# Dockerfile to build basic Oracle REST Data Services (ORDS) images
# Based on the following:
#   - Oracle Linux 8 - Slim
#   - Java 11 :
#       https://adoptopenjdk.net/releases.html?variant=openjdk11&jvmVariant=hotspot
#   - Tomcat 9.0.x :
#       https://tomcat.apache.org/download-90.cgi
#   - Oracle REST Data Services (ORDS) 19.x :
#       http://www.oracle.com/technetwork/developer-tools/rest-data-services/downloads/index.html
#   - Oracle Application Express (APEX) 20.x :
#       http://www.oracle.com/technetwork/developer-tools/apex/downloads/index.html
#   - Oracle SQLcl 19.x :
#       http://www.oracle.com/technetwork/developer-tools/sqlcl/downloads/index.html
#
# Example build and run. Assumes Docker network called "my_network" to connect to DB.
#
# docker build -t ol8_ords:latest .
# docker build --squash -t ol8_ords:latest .
#
# docker run -dit --name ol8_ords_con -p 8080:8080 -p 8443:8443 --network=my_network -e DB_HOSTNAME=ol8_19_con ol8_ords:latest
# Pure CATALINA_BASE on a persistent volume.
# docker run -dit --name ol8_ords_con -p 8080:8080 -p 8443:8443 --network=my_network -e DB_HOSTNAME=ol8_18_con -v /home/docker_user/volumes/ol8_19_ords_tomcat:/u01/config/instance1 ol8_ords:latest
#
# docker logs --follow ol8_ords_con
# docker exec -it ol8_ords_con bash
#
# docker stop --time=30 ol8_ords_con
# docker start ol8_ords_con
#
# docker rm -vf ol8_ords_con
#
# ------------------------------------------------------------------------------

# Set the base image to Oracle Linux 8
FROM oraclelinux:8-slim
#FROM oraclelinux:8

# File Author / Maintainer
# Use LABEL rather than deprecated MAINTAINER
# MAINTAINER Nutsu
LABEL maintainer="nuttydfgdf@gmail.com"

# ------------------------------------------------------------------------------
# Define fixed (build time) environment variables.
ENV JAVA_SOFTWARE="OpenJDK11U-jdk_x64_linux_hotspot_11.0.9.1_1.tar.gz"          \
    TOMCAT_SOFTWARE="apache-tomcat-9.0.41.zip"                              \
    ORDS_SOFTWARE="ords-20.3.0.301.1819.zip"                                   \
    APEX_SOFTWARE="apex_20.2_en.zip"                                           \ 
    SQLCL_SOFTWARE="sqlcl-20.3.0.274.1916.zip"                                 \
    SOFTWARE_DIR="/u01/software"                                               \
    SCRIPTS_DIR="/u01/scripts"                                                 \
    KEYSTORE_DIR="/u01/keystore"                                               \
    ORDS_HOME="/u01/ords"                                                      \
    ORDS_CONF="/u01/ords/conf"                                                 \
    JAVA_HOME="/u01/java/latest"                                               \
    CATALINA_HOME="/u01/tomcat/latest"                                         \
    CATALINA_BASE="/u01/config/instance1"

# ------------------------------------------------------------------------------
# Define config (runtime) environment variables.
ENV DB_HOSTNAME="localhost"                                           \
    DB_PORT="1521"                                                             \
    DB_SERVICE="xe"                                                          \
    APEX_PUBLIC_USER_PASSWORD="Dev!1234"                                  \
    APEX_TABLESPACE="APEX"                                                     \
    TEMP_TABLESPACE="TEMP"                                                     \
    APEX_LISTENER_PASSWORD="Dev!1234"                                     \
    APEX_REST_PASSWORD="Dev!1234"                                         \
    PUBLIC_PASSWORD="Dev!1234"                                            \
    SYS_PASSWORD="oracle"                                                \
    KEYSTORE_PASSWORD="KeystorePassword1"                                      \
    AJP_SECRET="AJPSecret1"                                                    \
    AJP_ADDRESS="::1"                                                          \
    APEX_IMAGES_REFRESH="false"                                                \
    PROXY_IPS="123.123.123.123\|123.123.123.124"

# ------------------------------------------------------------------------------
# Get all the files for the build.
COPY software/* ${SOFTWARE_DIR}/
COPY scripts/* ${SCRIPTS_DIR}/

# ------------------------------------------------------------------------------
# Unpack all the software and remove the media.
# No config done in the build phase.
RUN sh ${SCRIPTS_DIR}/install_os_packages.sh                                && \
    sh ${SCRIPTS_DIR}/ords_software_installation.sh

# Perform the following actions as the tomcat user
USER tomcat

VOLUME [${CATALINA_BASE}]
EXPOSE 8080 8443
HEALTHCHECK --interval=1m --start-period=1m \
   CMD ${SCRIPTS_DIR}/healthcheck.sh >/dev/null || exit 1

# ------------------------------------------------------------------------------
# The start script performs all config based on runtime environment variables,
# and starts tomcat.
CMD exec ${SCRIPTS_DIR}/start.sh

# End
