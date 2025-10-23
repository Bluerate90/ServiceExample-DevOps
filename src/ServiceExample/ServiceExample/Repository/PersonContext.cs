using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using MongoDB.Driver;
using MongoDB.EntityFrameworkCore.Extensions;
using ServiceExample.Models;

namespace ServiceExample.Repository;

public class PersonContext : DbContext
{
    private static readonly IMongoClient _mongoClient = new MongoClient("mongodb://admin:password123@mongodb:27017/ServiceExampleDB?authSource=admin");

    public virtual DbSet<Person> Persons { get; set; }

    public PersonContext(DbContextOptions<PersonContext> options)
        : base(options)
    {
    }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
        {
            optionsBuilder.UseMongoDB(_mongoClient, "ServiceExampleDB");
            optionsBuilder.ConfigureWarnings(w => w.Ignore(CoreEventId.ManyServiceProvidersCreatedWarning));
        }
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.Entity<Person>().HasKey(p => p.Id);
        modelBuilder.Entity<Person>().ToCollection("persons");
    }
}
