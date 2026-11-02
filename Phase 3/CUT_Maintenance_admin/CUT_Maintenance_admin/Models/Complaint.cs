using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using CUT_Maintenance_Admin.Data;

namespace CUT_Maintenance_Admin.Models
{
    [Table("complaints")]
    public class Complaint
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("reference")]
        public string? Reference { get; set; }

        [Column("reporter_id")]
        public Guid ReporterId { get; set; }

        [Column("category_id")]
        public Guid? CategoryId { get; set; }

        [Column("residence_id")]
        public Guid? ResidenceId { get; set; }

        [Column("title")]
        public string Title { get; set; }

        [Column("description")]
        public string? Description { get; set; }

        [Column("location")]
        public string? Location { get; set; }

        [Column("status")]
        public ComplaintStatus Status { get; set; }

        [Column("priority")]
        public PriorityLevel Priority { get; set; }

        [Column("deadline")]
        public DateTime? Deadline { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; }

        [Column("closed_at")]
        public DateTime? ClosedAt { get; set; }

        // --- Non-Database Properties for the Dashboard ---
        [NotMapped]
        public List<ComplaintImage> Images { get; set; } = new List<ComplaintImage>();

        [NotMapped]
        public string? CompletionNotes { get; set; }

        // Navigation properties
        [ForeignKey("CategoryId")]
        public virtual Category? Category { get; set; }

        [ForeignKey("ResidenceId")]
        public virtual Residence? Residence { get; set; }

        [ForeignKey("ReporterId")]
        public virtual Profile? Reporter { get; set; }
    }

    [Table("complaint_images")]
    public class ComplaintImage
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("complaint_id")]
        public Guid ComplaintId { get; set; }

        [Column("image_url")]
        public string ImageUrl { get; set; } = string.Empty;

        [Column("uploaded_at")]
        public DateTime UploadedAt { get; set; }

        // ADDED THIS LINE TO FIX THE ERROR
        [Column("stage")]
        public string? Stage { get; set; }
    }
}