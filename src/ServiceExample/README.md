# ServiceExample

This service sample demonstrates how to use .NET Web API service with:
* NATS messaging (sending and receiving messages)
* HTTP endpoint with OpenAPI/Swagger documentation
* Redis cache for list requests
* MongoDB for data storage

Service sends and receives person messages using NATS messaging system, stores them in MongoDB, and caches list requests in Redis for improved performance.

# To run it in k8s those environment variables must be set:
Aspire__MongoDB__Driver__ConnectionString="mongodb://mongo:27017"
Aspire__StackExchange__Redis__ConnectionString="redis:6379"
Aspire__NATS__Net__ConnectionString="nats://nats:4222"

Where mongo, redis and nats are the service names in the k8s cluster.

# To run unit tests navigate to the solution folder and run:
dotnet test

# To test API locally, this URL can be used:
http://localhost:9080/swagger/index.html

This API enpoint should be available: 
http://localhost:9080/api/Person

Dockerfile is provided to build the image. 
Also, docker-compose.yaml is provided to run it locally with required dependencies.