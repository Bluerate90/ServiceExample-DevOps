using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ServiceExample.Models;
using ServiceExample.Repository;
using ServiceExample.Services;
using StackExchange.Redis;

namespace ServiceExample.Controllers;

[Route("api/[controller]")]
[ApiController]
public class PersonController : ControllerBase
{
    private readonly ILogger<PersonController> _logger;
    private readonly PersonContext _context;
    private readonly IConnectionMultiplexer _cache;
    
    public PersonController(PersonContext aContext, IConnectionMultiplexer aCache, ILogger<PersonController> aLogger)
    {
        _context = aContext ?? throw new ArgumentNullException(nameof(aContext));
        _cache = aCache ?? throw new ArgumentNullException(nameof(aCache));
        _logger = aLogger ?? throw new ArgumentNullException(nameof(aLogger));
    }

    [HttpGet]
    public async Task<IActionResult> GetPersons()
    {
        if (_cache.IsConnected)
        {
            var db = _cache.GetDatabase();
            var cachedPersons = await db.StringGetAsync("persons");
            if (cachedPersons.HasValue)
            {
                _logger.LogInformation("Persons retrieved from cache.");
                var personsFromCache = JsonSerializer.Deserialize<IList<Person>>(cachedPersons!);
                return Ok(personsFromCache);
            }
            else
            {
                var persons = await _context.Persons.OrderByDescending(x => x.CreatedAt).Take(10).ToListAsync();
                var serializedPersons = JsonSerializer.Serialize(persons);
                await db.StringSetAsync("persons", serializedPersons, TimeSpan.FromSeconds(30));
                _logger.LogInformation("Persons retrieved from database and cached.");
                return Ok(persons);
            }
        }

        return Problem("Cache is not available.");
    }
}
