# webMethods Integration Microservice: Hello World - JDBC

TODO

##  Development

The initial sttHelloWorld package is enhanced with a new POST /messages API methods, which accepts a message. The message in question is saved in a Postgres database using the JDBC Adapter, along with a few other properties:
-   a uuid, allocated by the server to identify the message, which is also returned in the API response
-   the current timestamp
-   the name of the creator, which is populated from a microservices runtime global variable
  
The implementation pushed to this Github repo isn't state of the art. The goal is to show how to deal with JDBC connectivity the cloud-native way.  
It references a JDBC adapter connection named postgres.  
The DDL of the Postgres messages table can be found in ./resources/database  

To test the API using curl:
```
curl -X POST "http://localhost:5555/hello-world/messages" -u Administrator:manage -H "Accept: application/json" -H "Content-Type: application/json" -d '{"content":"Hello from Designer"}'
```
  
Which should the uuid of the inserted message (allocated by the server.)


##  Image build

A Dockerfile is provided to build the image:
-   it uses an official webMethods Microservices Runtime base image
-   it takes the webMethods Package Manager (WPM) token in argument (go to https://packages.webmethods.io to create such a token if you don't already have one)
-   it uses this token to install the WmJDBCAdapter packages from packages.webmethods.io
-   then it downloads the Postgres JDBC driver and places in a relevant location
-   finally, it copies the sttHelloWorld package into /opt/softwareag/IntegrationServer/packages

Important: the management of the WPM token described in this Dockerfile isn't leak proof. There are better ways of dealing with it (staged build, build secrets), but at this stage I want to keep things simple.  
  
Pre-requisite: you need to login to the IBM image registry to pull the base product image. The username is "cp" and the password is a token that needs to be obtained from https://myibm.ibm.com
```
docker login cp.icr.io -u cp
```
  
To perform the build and create an image with the stt-hello-world-jdbc tag name (don't forget to set the WPM_TOKEN environment variable):
```
docker build -t stt-hello-world-jdbc --platform=linux/amd64 --build-arg WPM_TOKEN=${WPM_TOKEN} .
```
  
We'll push this image to a remote image registry a little later.  

##  External configuration

We build the image once and then deploy it in all its target environments.  
The image configuration is externalized in an application.properties file that is managed in a "configuration as code" approach and injected into the container upon startup.  
This application.properties file references environment variables, Kubernetes secrets or vault secrets.  

We have properties to:
-   configure the Administrator password: user.Administrator.password
-   configure the JDBC adapter connection: artConnection.sttHelloWorld.sttHelloWorld.eu.sttlab.connections.postgres.*
-   set the value of the SERVER global variable: globalvariable.SERVER.value
  
##  Local deployment using docker compose

The ./resources/compose folder contains resources to deploy a container using compose. We have:
-   the application.properties file, which
    -   sets the Administrator password by referencing an ADMIN_PASSWORD environment variable
    -   sets the JDBC adapter connection parameters, referencing the DB_USERNAME and DB_PASSWORD environment variables. We make this connection point to a Postgres database deployed in the same docker compose stack.
    -   sets the value of the SERVER global variable to DOCKER
-   the .env file which sets values for the environment variables referenced by the application.properties file
-   the docker-compose.yml file which 
    -   creates a container from the stt-hello-world image,
    -   mounts the application.properties at the correct location, 
    -   injects the variables defined in .env,
    -   maps the internal 5555 port to the external 15555 port (meaning we can access the microservice via http://localhost:15555)
    -   also creates a Postgres container and creates a user using the DB_USERNAME and DB_PASSWORD environment variables
  
To start the compose stack:
```
docker compose up -d
```
  
To check the microservice logs:
```
docker logs -f msr
```

Before performing an API call for the first time you need to create the database table using the messages.ddl.sql file located in ./resources/database  

To test the API using curl:
```
curl -X POST "http://localhost:15555/hello-world/messages" -u Administrator:Manage123 -H "Accept: application/json" -H "Content-Type: application/json" -d '{"content":"Hello from Compose"}'
```
  
Which should the uuid of the inserted message (allocated by the server.)  

  
To stop the compose stack:
```
docker compose up -d
```
  
##  Push of the microservice image

Once we've confirmed we have a working microservice image we can push it to an image registry. I use the Github container registry here but the process is the same for all registries.  

Login to the registry (you'll need to provide a username and a token):
```
docker login ghcr.io
```

Tagging of the image (my user name is staillanibm):
```
docker tag stt-hello-world ghcr.io/staillanibm/stt-hello-world-jdbc
```

Push of the image:
```
docker push ghcr.io/staillanibm/stt-hello-world-jdbc
```
  
##  Deployment in Kubernetes

The ./resources/kubernetes folder contains resources to create a deployment in Kubernetes. We have:
-   the secret.yml file which references:
    -   the ADMIN_PASSWORD value, encoded in base64 (value is set to Manage12345 here)
    -   the DB_USERNAME and DB_PASSWORD values, also encoded in base64
-   the deploy.yml file which references several objects:
    -   a config map, which contains the content of the application.properties file (to configure the Administrator password, the database connection and the value of the SERVER global variable)
    -   a deployment with 3 pods, pointing to the container image previously pushed, in which we mount the config map and the secret previously mentioned. We also inject the pod name into the SERVER environment variable
    -   a load balancer service that exposes the 5555 port

The network exposition is simplified here with the use of a load balancer service. At target an ingress should be configured.  

To manage the deployment, follow these steps.
Note: you can also create a kubernetes namespace to do this deployment, here I am working in the default namespace to keep things simple.  

If not already done, create an image registry secret in order for Kubernetes to be able to fetch the image you previously pushed (after setting the references environment variables):
```
kubectl create secret docker-registry regcred --docker-server=${CR_SERVER} --docker-username=${CR_USERNAME} --docker-password=${CR_PASSWORD}
```

Apply the yml manifest files:
```
kubectl apply -f .
```

Check the pods:
```
kubectl get pods -w
```

After a minute or two you should see three pods in status running:
```
NAME                               READY   STATUS    RESTARTS   AGE
stt-hello-world-xxxxxxxxxx-xxxxx   1/1     Running   0          41m
stt-hello-world-yyyyyyyyyy-yyyyy   1/1     Running   0          41m
stt-hello-world-zzzzzzzzzz-zzzzz   1/1     Running   0          41m
```
  
A TCP readiness probe is configured for this deployment, so pods will only be in status "ready" once the TCP port 5555 is open.
  
Then check the load balancer service:
```
kubectl get svc stt-hello-world
```

You should see the external IP of the service, which you can use to call the API.
```
NAME              TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
stt-hello-world   LoadBalancer   10.100.228.57   127.0.0.1     5555:31228/TCP   48m
```
  
Finally you can call the API
```
curl -X POST "http://127.0.0.1:5555/hello-world/messages" -u Administrator:Manage12345 -H "Accept: application/json" -H "Content-Type: application/json" -d '{"content":"Hello from Kubernetes"}'
```
  
Which should the uuid of the inserted message (allocated by the server.)  

  
To undeploy:
```
kubectl delete -f .
```