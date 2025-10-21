using AutoFixture;
using NATS.Client.Core;
using NATS.Client.Serializers.Json;
using ServiceExample.Models;

namespace ServiceExample.Services;

public class Sender : BackgroundService
{
    private readonly ILogger<Sender> _logger;
    private readonly INatsConnection _connection;
    private readonly Fixture _fixture = new Fixture();

    public Sender(INatsConnection aConnection, ILogger<Sender> aLogger)
    {
        _connection = aConnection ?? throw new ArgumentNullException(nameof(aConnection));
        _logger = aLogger ?? throw new ArgumentNullException(nameof(aLogger));
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            var person = _fixture.Build<Person>()
                .Without(p => p.Id)
                .With(p => p.CreatedAt, DateTime.Now)
                .With(p => p.FirstName, GetRandomFirstName())
                .With(p => p.LastName, GetRandomLastName())
                .With(p => p.Age, new Random().Next(10, 90))
                .Create();

            await _connection.PublishAsync("persons", person, serializer: new NatsJsonSerializer<Person>());

            _logger.LogInformation($"Person {person.FirstName} {person.LastName} sent.");

            Task.Delay(1000, stoppingToken).Wait(stoppingToken);
        }
    }

    // Helper methods for realistic names
    private static string GetRandomFirstName()
    {
        var firstNames = new[] { "John", "Jane", "Michael", "Sarah", "David", "Emily", "Chris", "Jessica" };
        return firstNames[new Random().Next(firstNames.Length)];
    }

    private static string GetRandomLastName()
    {
        var lastNames = new[] { "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis" };
        return lastNames[new Random().Next(lastNames.Length)];
    }
}
