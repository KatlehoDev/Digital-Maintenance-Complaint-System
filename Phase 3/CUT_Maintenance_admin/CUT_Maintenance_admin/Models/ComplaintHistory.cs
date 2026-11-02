using System;
using System.ComponentModel.DataAnnotations.Schema;
using CUT_Maintenance_Admin.Data;

namespace CUT_Maintenance_Admin.Models
{
    [Table("complaint_history")]
    public class ComplaintHistory
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("complaint_id")]
        public Guid ComplaintId { get; set; }

        [Column("user_id")]
        public Guid? UserId { get; set; }

        [Column("action")]
        public string Action { get; set; }

        [Column("old_status")]
        public ComplaintStatus? OldStatus { get; set; }

        [Column("new_status")]
        public ComplaintStatus? NewStatus { get; set; }

        [Column("comment")]
        public string? Comment { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        // Explicitly map to the UserId property
        [ForeignKey("UserId")]
        public virtual Profile? User { get; set; }
    }
}