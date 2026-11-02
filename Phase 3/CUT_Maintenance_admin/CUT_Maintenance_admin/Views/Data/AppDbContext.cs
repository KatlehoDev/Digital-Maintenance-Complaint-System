using Microsoft.EntityFrameworkCore;
using CUT_Maintenance_Admin.Models;

namespace CUT_Maintenance_Admin.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Complaint> Complaints { get; set; }
        public DbSet<Profile> Profiles { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<Residence> Residences { get; set; }
        public DbSet<Assignment> Assignments { get; set; }
        public DbSet<ComplaintHistory> ComplaintHistories { get; set; }
        public DbSet<ComplaintImage> ComplaintImages { get; set; }
        public DbSet<Notification> Notifications { get; set; } // <-- ADDED

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            modelBuilder.HasPostgresEnum<ComplaintStatus>("public", "complaint_status");
            modelBuilder.HasPostgresEnum<PriorityLevel>("public", "priority_level");
        }
    }

    public enum ComplaintStatus
    {
        reported, assigned, accepted, in_progress, completed, verified, closed, reopened, rejected, withdrawn
    }
    public enum PriorityLevel
    {
        low, medium, high, urgent
    }
}