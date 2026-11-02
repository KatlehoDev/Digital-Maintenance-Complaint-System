using CUT_Maintenance_Admin.Data;
using CUT_Maintenance_Admin.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace CUT_Maintenance_Admin.Controllers
{
    public class DashboardController : Controller
    {
        private readonly AppDbContext _context;

        public DashboardController(AppDbContext context)
        {
            _context = context;
        }

        private bool IsLoggedIn() => HttpContext.Session.GetString("AdminEmail") != null;

        private async Task LoadNotificationsAsync()
        {
            var adminEmail = HttpContext.Session.GetString("AdminEmail");
            if (string.IsNullOrEmpty(adminEmail)) return;

            var admin = await _context.Profiles.FirstOrDefaultAsync(p => p.Email == adminEmail);
            if (admin != null)
            {
                ViewBag.NotificationList = await _context.Notifications
                    .Where(n => n.UserId == admin.Id)
                    .OrderByDescending(n => n.CreatedAt)
                    .Take(5)
                    .ToListAsync();
                ViewBag.UnreadCount = await _context.Notifications.CountAsync(n => n.UserId == admin.Id && !n.IsRead);
            }
        }

        private async Task SendNotificationAsync(Guid userId, Guid complaintId, string message)
        {
            try
            {
                var sql = "SELECT notify_user(@p0, @p1, @p2)";
                await _context.Database.ExecuteSqlRawAsync(sql, userId, complaintId, message);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Notification failed: {ex.Message}");
            }
        }

        // NEW: API ENDPOINT FOR LIVE TABLE UPDATES
        [HttpGet]
        public async Task<IActionResult> GetDashboardData()
        {
            if (!IsLoggedIn()) return Unauthorized();

            // Return just the counts to check if we need to reload the page
            var total = await _context.Complaints.CountAsync(c => c.Status != ComplaintStatus.withdrawn);
            var open = await _context.Complaints.CountAsync(c => c.Status == ComplaintStatus.reported);
            var inProgress = await _context.Complaints.CountAsync(c => c.Status == ComplaintStatus.in_progress || c.Status == ComplaintStatus.assigned || c.Status == ComplaintStatus.accepted);
            var resolved = await _context.Complaints.CountAsync(c => c.Status == ComplaintStatus.closed || c.Status == ComplaintStatus.verified || c.Status == ComplaintStatus.completed);

            return Json(new { total, open, inProgress, resolved });
        }

        [HttpGet]
        public async Task<IActionResult> GetNotifications()
        {
            if (!IsLoggedIn()) return Unauthorized();

            var adminEmail = HttpContext.Session.GetString("AdminEmail");
            var admin = await _context.Profiles.FirstOrDefaultAsync(p => p.Email == adminEmail);
            if (admin == null) return NotFound();

            var notifications = await _context.Notifications
                .Where(n => n.UserId == admin.Id)
                .OrderByDescending(n => n.CreatedAt)
                .Take(5)
                .Select(n => new {
                    n.Id,
                    n.Message,
                    n.IsRead,
                    CreatedAt = n.CreatedAt.ToString("dd MMM, HH:mm")
                })
                .ToListAsync();

            var unreadCount = await _context.Notifications.CountAsync(n => n.UserId == admin.Id && !n.IsRead);

            return Json(new { notifications, unreadCount });
        }

        [HttpPost]
        public async Task<IActionResult> MarkNotificationRead(Guid id)
        {
            var notif = await _context.Notifications.FindAsync(id);
            if (notif != null)
            {
                notif.IsRead = true;
                await _context.SaveChangesAsync();
            }
            return RedirectToAction("Dashboard");
        }

        public async Task<IActionResult> Dashboard()
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");
            await LoadNotificationsAsync();

            var complaints = await _context.Complaints
                .Where(c => c.Status != ComplaintStatus.withdrawn)
                .ToListAsync();

            ViewBag.Total = complaints.Count;
            ViewBag.Open = complaints.Count(c => c.Status == ComplaintStatus.reported);
            ViewBag.InProgress = complaints.Count(c => c.Status == ComplaintStatus.in_progress || c.Status == ComplaintStatus.assigned || c.Status == ComplaintStatus.accepted);
            ViewBag.Resolved = complaints.Count(c => c.Status == ComplaintStatus.closed || c.Status == ComplaintStatus.verified || c.Status == ComplaintStatus.completed);
            ViewBag.RejectedCount = complaints.Count(c => c.Status == ComplaintStatus.rejected);
            ViewBag.WithdrawnCount = complaints.Count(c => c.Status == ComplaintStatus.withdrawn);

            ViewBag.RecentHistory = await _context.ComplaintHistories
                .Include(h => h.User)
                .OrderByDescending(h => h.CreatedAt)
                .Take(5)
                .ToListAsync();

            return View();
        }

        public async Task<IActionResult> AllComplaints(string searchString)
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");
            await LoadNotificationsAsync();

            ViewData["CurrentFilter"] = searchString;

            var complaints = _context.Complaints
                .Include(c => c.Category)
                .Include(c => c.Residence)
                .Include(c => c.Reporter)
                .Where(c => c.Status != ComplaintStatus.withdrawn)
                .AsQueryable();

            if (!string.IsNullOrEmpty(searchString))
            {
                searchString = searchString.ToLower();
                complaints = complaints.Where(c =>
                    c.Title.ToLower().Contains(searchString) ||
                    c.Reference.ToLower().Contains(searchString) ||
                    (c.Location != null && c.Location.ToLower().Contains(searchString)) ||
                    (c.Residence != null && c.Residence.Name.ToLower().Contains(searchString))
                );
            }

            return View(await complaints.OrderByDescending(c => c.CreatedAt).ToListAsync());
        }

        public async Task<IActionResult> Details(Guid id)
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");
            await LoadNotificationsAsync();

            var complaint = await _context.Complaints
                .Include(c => c.Category)
                .Include(c => c.Residence)
                .Include(c => c.Reporter)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (complaint == null) return NotFound();

            complaint.Images = await _context.ComplaintImages
                .Where(i => i.ComplaintId == complaint.Id)
                .OrderBy(i => i.UploadedAt)
                .ToListAsync();

            ViewBag.History = await _context.ComplaintHistories
                .Include(h => h.User)
                .Where(h => h.ComplaintId == complaint.Id)
                .OrderByDescending(h => h.CreatedAt)
                .ToListAsync();

            var assignment = await _context.Assignments
                .Include(a => a.User)
                .Where(a => a.ComplaintId == complaint.Id)
                .OrderByDescending(a => a.AssignedAt)
                .FirstOrDefaultAsync();

            ViewBag.AssignedWorker = assignment?.User;

            ViewBag.Workers = await _context.Profiles
                .Where(p => p.Role == "maintenance" && p.IsActive == true)
                .ToListAsync();

            return View(complaint);
        }

        public async Task<IActionResult> Assign(Guid id)
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");
            await LoadNotificationsAsync();

            var complaint = await _context.Complaints
                .Include(c => c.Category)
                .Include(c => c.Residence)
                .Include(c => c.Reporter)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (complaint == null) return NotFound();

            complaint.Images = await _context.ComplaintImages
                .Where(i => i.ComplaintId == complaint.Id)
                .OrderBy(i => i.UploadedAt)
                .ToListAsync();

            ViewBag.Workers = await _context.Profiles
                .Where(p => p.Role == "maintenance" && p.IsActive == true)
                .ToListAsync();

            return View(complaint);
        }

        [HttpPost]
        public async Task<IActionResult> Assign(Guid id, Guid workerId, DateTime deadline, PriorityLevel priority)
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");

            var complaint = await _context.Complaints.FindAsync(id);
            if (complaint == null) return NotFound();

            var utcDeadline = DateTime.SpecifyKind(deadline, DateTimeKind.Utc);
            var utcNow = DateTime.UtcNow;

            _context.Assignments.Add(new Assignment
            {
                Id = Guid.NewGuid(),
                ComplaintId = complaint.Id,
                UserId = workerId,
                AssignedAt = utcNow,
                Deadline = utcDeadline
            });

            complaint.Status = ComplaintStatus.assigned;
            complaint.Deadline = utcDeadline;
            complaint.Priority = priority;

            _context.ComplaintHistories.Add(new ComplaintHistory
            {
                Id = Guid.NewGuid(),
                ComplaintId = complaint.Id,
                UserId = workerId,
                Action = $"Assigned to maintenance worker with {priority} priority",
                OldStatus = ComplaintStatus.reported,
                NewStatus = ComplaintStatus.assigned,
                CreatedAt = utcNow
            });

            await _context.SaveChangesAsync();

            await SendNotificationAsync(workerId, complaint.Id, $"New Job Assigned: {complaint.Title}");

            TempData["Success"] = "Complaint successfully assigned!";
            return RedirectToAction("AllComplaints");
        }

        [HttpPost]
        public async Task<IActionResult> Reassign(Guid id, Guid workerId, DateTime deadline, PriorityLevel priority)
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");

            var complaint = await _context.Complaints.FindAsync(id);
            if (complaint == null) return NotFound();

            var utcDeadline = DateTime.SpecifyKind(deadline, DateTimeKind.Utc);
            var utcNow = DateTime.UtcNow;

            _context.Assignments.Add(new Assignment
            {
                Id = Guid.NewGuid(),
                ComplaintId = complaint.Id,
                UserId = workerId,
                AssignedAt = utcNow,
                Deadline = utcDeadline
            });

            complaint.Status = ComplaintStatus.assigned;
            complaint.Deadline = utcDeadline;
            complaint.Priority = priority;

            _context.ComplaintHistories.Add(new ComplaintHistory
            {
                Id = Guid.NewGuid(),
                ComplaintId = complaint.Id,
                UserId = workerId,
                Action = $"Reassigned to maintenance worker with {priority} priority",
                OldStatus = ComplaintStatus.reopened,
                NewStatus = ComplaintStatus.assigned,
                CreatedAt = utcNow
            });

            await _context.SaveChangesAsync();

            await SendNotificationAsync(workerId, complaint.Id, $"Job Reassigned: {complaint.Title}");

            TempData["Success"] = "Complaint successfully reassigned!";
            return RedirectToAction("Details", new { id = complaint.Id });
        }

        public async Task<IActionResult> ManageCategories()
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");
            await LoadNotificationsAsync();
            return View(await _context.Categories.ToListAsync());
        }

        [HttpPost]
        public async Task<IActionResult> AddCategory(string name, string description)
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");
            _context.Categories.Add(new Category { Name = name, Description = description, IsActive = true });
            await _context.SaveChangesAsync();
            TempData["Success"] = "Category added successfully!";
            return RedirectToAction("ManageCategories");
        }

        public async Task<IActionResult> EditCategory(Guid id)
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");
            await LoadNotificationsAsync();
            var category = await _context.Categories.FindAsync(id);
            if (category == null) return NotFound();
            return View(category);
        }

        [HttpPost]
        public async Task<IActionResult> EditCategory(Guid id, string name, string description, bool isActive)
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");
            var category = await _context.Categories.FindAsync(id);
            if (category == null) return NotFound();

            category.Name = name;
            category.Description = description;
            category.IsActive = isActive;
            await _context.SaveChangesAsync();
            TempData["Success"] = "Category updated successfully!";
            return RedirectToAction("ManageCategories");
        }

        [HttpPost]
        public async Task<IActionResult> DeleteCategory(Guid id)
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");
            var category = await _context.Categories.FindAsync(id);
            if (category != null)
            {
                var isUsed = await _context.Complaints.AnyAsync(c => c.CategoryId == id);
                if (isUsed)
                {
                    category.IsActive = false;
                    TempData["Success"] = "Category is in use. Marked as Inactive.";
                }
                else
                {
                    _context.Categories.Remove(category);
                    TempData["Success"] = "Category deleted successfully!";
                }
                await _context.SaveChangesAsync();
            }
            return RedirectToAction("ManageCategories");
        }

        public async Task<IActionResult> Analytics()
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");
            await LoadNotificationsAsync();

            var complaints = await _context.Complaints
                .Include(c => c.Category)
                .Where(c => c.Status != ComplaintStatus.withdrawn)
                .ToListAsync();

            ViewBag.Total = complaints.Count;
            ViewBag.Open = complaints.Count(c => c.Status == ComplaintStatus.reported);
            ViewBag.InProgress = complaints.Count(c => c.Status == ComplaintStatus.in_progress);
            ViewBag.Resolved = complaints.Count(c => c.Status == ComplaintStatus.verified || c.Status == ComplaintStatus.closed);

            var topIssues = complaints.GroupBy(c => c.Category?.Name ?? "Other")
                                      .Select(g => new { Category = g.Key, Count = g.Count() })
                                      .OrderByDescending(g => g.Count)
                                      .Take(5)
                                      .ToList();
            ViewBag.TopIssues = topIssues;
            return View();
        }

        public async Task<IActionResult> Users(string searchString, string roleFilter)
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");
            await LoadNotificationsAsync();

            var users = _context.Profiles.AsQueryable();

            if (!string.IsNullOrEmpty(searchString))
            {
                searchString = searchString.ToLower();
                users = users.Where(u =>
                    (u.FullName != null && u.FullName.ToLower().Contains(searchString)) ||
                    u.Email.ToLower().Contains(searchString));
            }

            if (!string.IsNullOrEmpty(roleFilter))
            {
                users = users.Where(u => u.Role == roleFilter);
            }

            ViewData["CurrentFilter"] = searchString;
            ViewData["CurrentRole"] = roleFilter;

            return View(await users.OrderByDescending(u => u.CreatedAt).ToListAsync());
        }

        [HttpPost]
        public async Task<IActionResult> ToggleUserStatus(Guid id)
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");

            var user = await _context.Profiles.FindAsync(id);
            if (user != null)
            {
                user.IsActive = !(user.IsActive ?? true);
                await _context.SaveChangesAsync();
                TempData["Success"] = $"User status updated to {(user.IsActive == true ? "Active" : "Inactive")}.";
            }

            return RedirectToAction("Users");
        }

        public async Task<IActionResult> ManageResidences()
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");
            await LoadNotificationsAsync();
            return View(await _context.Residences.ToListAsync());
        }

        [HttpPost]
        public async Task<IActionResult> AddResidence(string name)
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");
            _context.Residences.Add(new Residence { Name = name });
            await _context.SaveChangesAsync();
            TempData["Success"] = "Residence added successfully!";
            return RedirectToAction("ManageResidences");
        }

        [HttpPost]
        public async Task<IActionResult> DeleteResidence(Guid id)
        {
            if (!IsLoggedIn()) return RedirectToAction("Login", "Account");
            var residence = await _context.Residences.FindAsync(id);
            if (residence != null)
            {
                var isUsed = await _context.Complaints.AnyAsync(c => c.ResidenceId == id);
                if (isUsed)
                {
                    TempData["Error"] = "Cannot delete this residence because there are complaints attached to it.";
                }
                else
                {
                    _context.Residences.Remove(residence);
                    await _context.SaveChangesAsync();
                    TempData["Success"] = "Residence deleted successfully!";
                }
            }
            return RedirectToAction("ManageResidences");
        }
    }
}