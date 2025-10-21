using System;
using Microsoft.EntityFrameworkCore;
using NATS.Client.Core;
using NATS.Client.Serializers.Json;
using ServiceExample.Models;
using ServiceExample.Repository;

namespace ServiceExample.Services;

public class Receiver : BackgroundService
{
    private readonly ILogger<Receiver> _logger;
    private readonly INatsConnection _connection;
    private readonly IDbContextFactory<PersonContext> _contextFactory;

    public Receiver(INatsConnection aConnection, IDbContextFactory<PersonContext> aContextFactory, ILogger<Receiver> aLogger)
    {
        _connection = aConnection ?? throw new ArgumentNullException(nameof(aConnection));
        _contextFactory = aContextFactory ?? throw new ArgumentNullException(nameof(aContextFactory));
        _logger = aLogger ?? throw new ArgumentNullException(nameof(aLogger));
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await foreach (var msg in _connection.SubscribeAsync("persons", serializer: new NatsJsonSerializer<Person>(), cancellationToken: stoppingToken))
        {
            if (msg.Data != null)
            {
                _logger.LogInformation($"Person {msg.Data.FirstName} {msg.Data.LastName} received.");

                using var context = await _contextFactory.CreateDbContextAsync(stoppingToken);
                await context.Persons.AddAsync(msg.Data);
                await context.SaveChangesAsync();
            }                
        }
    }
}
