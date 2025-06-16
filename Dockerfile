FROM cp.icr.io/cp/webmethods/integration/ibm-webmethods-integration-microservicesruntime:11.1.0.4

USER 1724

ADD --chown=1724 . /opt/softwareag/IntegrationServer/packages/sttHelloWorld