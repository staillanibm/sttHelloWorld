# webMethods Integration Microservice: Hello World

Very simple webMethods integration microservice which showcases the build, configuration and deployment of an integration package that contains a hello world API.

##  Development

The integration package was implemented using the webMethods service designer and pushed to Github using the embedded Git client, which is available through the "Local Service Development" feature.  
A full fledged Service Designer (with the webMethods Microservices Runtime) can be downloaded here: https://www.ibm.com/resources/mrs/assets?source=WMS_Designers  
  
To test the API using curl:
```
curl -u Administrator:manage "http://localhost:5555/hello-world/greetings?name=Designer" -H "Accept: application/json"
```
  
Which should return:
```
{"message":"Hello Designer","dateTime":"2025-06-16T13:50:34.298Z"}
```

##  Image build

A Dockerfile is provided to build the image:
-   it uses an official webMethods Microservices Runtime base image
-   it copies the sttHelloWorld package into /opt/softwareag/IntegrationServer/packages

To perform the build and create an image with the stt-hello-world tag name:
```
docker build -t stt-hello-world --platform=linux/amd64 .
```
  
We'll push this image to a remote image registry a little later.  

##  External configuration

We build the image once and then deploy it in all its target environments.  
The image configuration is externalized in an application.properties file that is managed in a "configuration as code" approach and injected into the container upon startup.  
This application.properties file references environment variables, Kubernetes secrets or vault secrets.  

##  Local deployment using docker compose

The ./resources/compose folder contains resources to deploy a container using compose. We have:
-   the application.properties file, which sets the Administrator password and references an ADMIN_PASSWORD environment variable
-   the value for this environment variable is set in a .env file (ADMIN_PASSWORD is set to Manage123 here)
-   the docker-compose.yml file which 
    -   creates a container from the stt-hello-world image,
    -   mounts the application.properties at the correct location, 
    -   injects the variables defined in .env,
    -   maps the internal 5555 port to the external 15555 port (meaning we can access the microservice via http://localhost:15555)
  
To start the compose stack:
```
docker compose up -d
```
  
To check the microservice logs:
```
docker logs -f msr
```

To test the API using curl:
```
curl -u Administrator:Manage123 "http://localhost:15555/hello-world/greetings?name=Compose" -H "Accept: application/json"
```
  
Which should return:
```
{"message":"Hello Compose","dateTime":"2025-06-16T13:53:36.175Z"}
```
  
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
docker tag stt-hello-world ghcr.io/staillanibm/stt-hello-world 
```

Push of the image:
```
docker push ghcr.io/staillanibm/stt-hello-world
```
  
##  Deployment in Kubernetes

The ./resources/kubernetes folder contains resources to create a deployment in Kubernetes. We have:
-   the secret.yml file which references the ADMIN_PASSWORD value, encoded in base64 (value is set to Manage12345 here)
-   the deploy.yml file which references several objects:
    -   a config map, which contains the content of the application.properties file (this time user.Administrator.password points to a secret named ADMIN_PASSWORD)
    -   a deployment with 3 pods, pointing to the container image previously pushed, in which we mount the config map and the secret previously mentioned
    -   a load balancer service that exposes the 5555 port

The network exposition is simplified here with the use of a load balancer service. At target an ingress should be configured.  

To manage the deployment, follow these steps.
Note: you can also create a kubernetes namespace to do this deployment, here I am working in the default namespace to keep things simple.  

Create an image registry secret in order for Kubernetes to be able to fetch the image you previously pushed (after setting the references environment variables):
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
curl -u Administrator:Manage12345 "http://127.0.0.1:5555/hello-world/greetings?name=Kubernetes" -H "Accept: application/json"
```
  
Which should return:
```
{"message":"Hello Kubernetes","dateTime":"2025-06-16T13:59:09.723Z"}
```
  
To undeploy:
```
kubectl delete -f .
```