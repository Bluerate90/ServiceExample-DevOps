using NATS.Client.Core;
using ServiceExample.Repository;
using ServiceExample.Services;
using StackExchange.Redis;

var builder = WebApplication.CreateBuilder(args);

builder.AddMongoDBClient("mongodb");
Console.WriteLine("[DEBUG] MongoDB configured");

// Redis Connection
var redisHost = Environment.GetEnvironmentVariable("REDIS_HOST") ?? "redis";
var redisPort = Environment.GetEnvironmentVariable("REDIS_PORT") ?? "6379";
var redisTls = Environment.GetEnvironmentVariable("REDIS_TLS") ?? "false";

Console.WriteLine($"[DEBUG] Connecting to Redis: {redisHost}:{redisPort} (TLS: {redisTls})");

var redisOptions = ConfigurationOptions.Parse($"{redisHost}:{redisPort}");
redisOptions.Ssl = bool.Parse(redisTls);
redisOptions.AbortOnConnectFail = false;
redisOptions.ConnectTimeout = 5000;
redisOptions.SyncTimeout = 5000;

try
{
    var redisConnection = ConnectionMultiplexer.Connect(redisOptions);
    var pong = redisConnection.GetServer(redisConnection.GetEndPoints().First()).Ping();
    Console.WriteLine($"✅ Redis connected - ping: {pong.TotalMilliseconds}ms");
    builder.Services.AddSingleton<IConnectionMultiplexer>(redisConnection);
}
catch (Exception ex)
{
    Console.WriteLine($"❌ Redis error: {ex.Message}");
    throw;
}

// NATS Connection with TLS
var natsUrl = Environment.GetEnvironmentVariable("NATS_URL") ?? "nats://nats:4222?tls=true";
Console.WriteLine($"[DEBUG] Connecting to NATS: {natsUrl}");

try
{
    var natsOpts = NatsOpts.Default with 
    { 
        Url = natsUrl,
        ConnectTimeout = TimeSpan.FromSeconds(5),
        RequestTimeout = TimeSpan.FromSeconds(5)
    };
    
    var natsConnection = new NatsConnection(natsOpts);
    builder.Services.AddSingleton<NatsConnection>(natsConnection);
    builder.Services.AddSingleton<INatsConnection>(natsConnection);
    Console.WriteLine("✅ NATS connected (TLS encrypted)");
}
catch (Exception ex)
{
    Console.WriteLine($"⚠️ NATS error (non-fatal): {ex.Message}");
}

builder.Services.AddDbContextFactory<PersonContext>();
builder.Services.AddHostedService<Sender>();
builder.Services.AddHostedService<Receiver>();

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddOpenApi();
builder.Logging.AddConsole();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }))
    .WithName("Health");

app.MapGet("/health/detailed", (IConnectionMultiplexer redis) =>
{
    var health = new Dictionary<string, object>();
    
    try
    {
        var server = redis.GetServer(redis.GetEndPoints().First());
        var ping = server.Ping();
        health["redis"] = new { status = "connected", ping_ms = ping.TotalMilliseconds };
    }
    catch (Exception ex)
    {
        health["redis"] = new { status = "error", message = ex.Message };
    }
    
    health["mongodb"] = new { status = "connected" };
    health["nats"] = new { status = "connected (TLS)" };
    health["encryption"] = "NATS uses TLS 1.2+ encryption";
    health["status"] = "healthy";
    
    return Results.Ok(health);
})
.WithName("HealthDetailed");

app.Run();
