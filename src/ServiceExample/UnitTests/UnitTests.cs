using System.Text.Json;
using AutoFixture;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using MockQueryable;
using MockQueryable.Moq;
using Moq;
using ServiceExample.Controllers;
using ServiceExample.Models;
using ServiceExample.Repository;
using StackExchange.Redis;

namespace UnitTests;

public class UnitTests
{
    private readonly Fixture _fixture = new Fixture();

    [Fact]
    public async Task ControllerTestAsync()
    {
        var persons = _fixture.CreateMany<Person>(5).ToList();

        var logger = new Mock<ILogger<PersonController>>();
        var mockCacheDb = new Mock<IDatabase>();
        mockCacheDb.Setup(db => db.StringGetAsync(It.IsAny<RedisKey>(), It.IsAny<CommandFlags>()))
            .ReturnsAsync(new RedisValue(JsonSerializer.Serialize(persons)));

        var cache = new Mock<IConnectionMultiplexer>();
        cache.Setup(c => c.IsConnected).Returns(true);
        cache.Setup(c => c.GetDatabase(It.IsAny<int>(), It.IsAny<object>())).Returns(() => mockCacheDb.Object);

        var contextMock = new Mock<PersonContext>();
        var controller = new PersonController(contextMock.Object, cache.Object, logger.Object);        
        
        var result = await controller.GetPersons() as OkObjectResult;
        Assert.NotNull(result);

        var list = result.Value as IList<Person>;
        Assert.NotNull(list);
        Assert.Equal(5, list.Count);
    }
}
