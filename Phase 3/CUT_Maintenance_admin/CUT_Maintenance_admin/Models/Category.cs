using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace CUT_Maintenance_Admin.Models
{
    [Table("categories")]
    public class Category
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("name")]
        public string Name { get; set; }

        [Column("is_active")]
        public bool? IsActive { get; set; }

        [Column("description")]
        public string? Description { get; set; }
    }
}