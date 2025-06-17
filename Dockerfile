# We use a base product image for the Microservices Runtime
FROM cp.icr.io/cp/webmethods/integration/ibm-webmethods-integration-microservicesruntime:11.1.0.4

# We take the wpm token as argument, to connect to https://packages.webmethods.io and fetch the WmJDBCAdapter package
ARG WPM_TOKEN

USER 1724

# We install the JDBC adapter from the package registry
RUN /opt/softwareag/wpm/bin/wpm.sh install -ws https://packages.webmethods.io -wr licensed -j $WPM_TOKEN -d /opt/softwareag/IntegrationServer WmJDBCAdapter:latest

# We download the Postgres JDBC driver and place it in the relevant location
RUN curl -o /opt/softwareag/IntegrationServer/packages/WmJDBCAdapter/code/jars/postgresql-42.7.4.jar "https://jdbc.postgresql.org/download/postgresql-42.7.4.jar"

# We add the custom package to the Microservices Runtime
ADD --chown=1724 . /opt/softwareag/IntegrationServer/packages/sttHelloWorld