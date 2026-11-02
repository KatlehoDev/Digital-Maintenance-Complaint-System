using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace CUT_Maintenance_Admin.Models
{
    [Table("assignments")]
    public class Assignment
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("complaint_id")]
        public Guid ComplaintId { get; set; }

        [Column("user_id")]
        public Guid UserId { get; set; }

        [Column("assigned_at")]
        public DateTime AssignedAt { get; set; }

        [Column("accepted_at")]
        public DateTime? AcceptedAt { get; set; }

        [Column("deadline")]
        public DateTime? Deadline { get; set; }

        // ADD THIS: Navigation property to link to the Profile table
        [ForeignKey("UserId")]
        public virtual Profile? User { get; set; }
    }
}