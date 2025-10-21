using Microsoft.EntityFrameworkCore;
using MongoDB.Driver;
using ServiceExample.Repository;
using ServiceExample.Services;

var builder = WebApplication.CreateBuilder(args);

builder.AddMongoDBClient("mongodb");
builder.AddRedisClient("cache");
builder.AddNatsClient("nats");

builder.Services.AddHostedService<Sender>();
builder.Services.AddHostedService<Receiver>();

builder.Services.AddDbContextFactory<PersonContext>((sp, options) =>
{
    var client = sp.GetRequiredService<IMongoClient>();
    options.UseMongoDB(client, "testdb");
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddOpenApi();

builder.Logging.AddConsole();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.UseSwagger();

app.UseSwaggerUI();

app.Run();
