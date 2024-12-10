using Microsoft.EntityFrameworkCore;

public class ClownCarRentalContext : DbContext
{
    public ClownCarRentalContext(DbContextOptions<ClownCarRentalContext> options)
        : base(options)
    {
    }

    public DbSet<Customer> Customers { get; set; }
    public DbSet<ClownCar> ClownCars { get; set; }
    public DbSet<Rental> Rentals { get; set; }
    public DbSet<Staff> Staff { get; set; }
}
