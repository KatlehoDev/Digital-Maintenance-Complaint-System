using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace CUT_Maintenance_Admin.Models
{
    [Table("notifications")]
    public class Notification
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("user_id")]
        public Guid UserId { get; set; }

        [Column("complaint_id")]
        public Guid? ComplaintId { get; set; }

        [Column("message")]
        public string Message { get; set; }

        [Column("is_read")]
        public bool IsRead { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }
    }
}