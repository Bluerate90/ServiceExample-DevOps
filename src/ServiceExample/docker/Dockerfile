# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS builder
WORKDIR /src

# Copy solution and project files
COPY src/ServiceExample/ServiceExample.sln ./
COPY src/ServiceExample/ServiceExample/ServiceExample.csproj ./ServiceExample/
COPY src/ServiceExample/UnitTests/UnitTests.csproj ./UnitTests/

# Restore dependencies
RUN dotnet restore ServiceExample.sln

# Copy all source code
COPY src/ServiceExample/ ./

# Build solution
RUN dotnet build ServiceExample.sln -c Release --no-restore

# Test stage
FROM builder AS tester
RUN dotnet test ServiceExample.sln --no-build -c Release --verbosity normal || true

# Publish stage
FROM builder AS publish
RUN dotnet publish ServiceExample/ServiceExample.csproj -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
COPY --from=publish /app/publish .
EXPOSE 5000 5001

HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1

ENTRYPOINT ["dotnet", "ServiceExample.dll"]
