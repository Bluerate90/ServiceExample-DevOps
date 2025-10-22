# Local Development Setup

## Prerequisites

- .NET 9 SDK
- Docker
- Docker Compose

## Installation

1. Install .NET 9 SDK:
```bash
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --version latest
```

2. Clone the repository:
```bash
git clone <repository-url>
cd ServiceExample-DevOps
```

3. Start the application:
```bash
docker-compose up
```

## Verify It's Running

Once the containers are up, test the API:

- **Swagger UI**: http://localhost:9080/swagger/index.html
- **API Endpoint**: http://localhost:9080/api/Person

```bash
curl http://localhost:9080/api/Person
```

## Troubleshooting

If Docker Compose takes too long or fails, upgrade Docker:

```bash
sudo apt-get update
sudo apt-get upgrade docker.io
sudo systemctl restart docker
docker-compose up
```

That's it!
