using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace CUT_Maintenance_Admin.Models
{
    [Table("profiles")]
    public class Profile
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("email")]
        public string Email { get; set; }

        [Column("full_name")]
        public string? FullName { get; set; }

        [Column("role")]
        public string Role { get; set; }

        [Column("is_active")]
        public bool? IsActive { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        [InverseProperty("User")]
        public virtual ICollection<ComplaintHistory> ComplaintHistories { get; set; } = new List<ComplaintHistory>();
    }
}