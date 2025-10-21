# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
COPY ./src ./src
WORKDIR /src/ServiceExample/ServiceExample
RUN dotnet restore
RUN dotnet build -c Release -o /app/build

# Publish stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS publish
COPY ./src ./src
WORKDIR /src/ServiceExample/ServiceExample
RUN dotnet restore
RUN dotnet publish -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
RUN useradd -m -u 1001 appuser
COPY --from=publish /app/publish .
RUN chown -R appuser:appuser /app
USER appuser
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1
EXPOSE 5000
ENV ASPNETCORE_URLS=http://+:5000
ENTRYPOINT ["dotnet", "ServiceExample.dll"]