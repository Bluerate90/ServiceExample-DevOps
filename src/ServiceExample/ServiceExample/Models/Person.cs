using System.Text.Json.Serialization;

namespace ServiceExample.Models;

public class Person
{
    public string Id { get; set; } = Guid.NewGuid().ToString();

    public string FirstName { get; set; } = null!;

    public string LastName { get; set; } = null!;

    public DateTime CreatedAt { get; set; } = DateTime.Now;

    public int Age { get; set; }    
}