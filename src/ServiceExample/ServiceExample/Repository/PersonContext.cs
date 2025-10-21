using Microsoft.EntityFrameworkCore;
using MongoDB.EntityFrameworkCore.Extensions;
using ServiceExample.Models;

namespace ServiceExample.Repository;

public class PersonContext : DbContext
{
    public virtual DbSet<Person> Persons { get; set; }

    public PersonContext()
    {
    }

    public PersonContext(DbContextOptions options)
        : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Person>().HasKey(p => p.Id);
        modelBuilder.Entity<Person>().ToCollection("persons");
    }
}
