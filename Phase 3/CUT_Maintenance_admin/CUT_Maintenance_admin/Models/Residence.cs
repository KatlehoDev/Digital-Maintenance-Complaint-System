using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace CUT_Maintenance_Admin.Models
{
    [Table("residences")]
    public class Residence
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("name")]
        public string Name { get; set; }
    }
}