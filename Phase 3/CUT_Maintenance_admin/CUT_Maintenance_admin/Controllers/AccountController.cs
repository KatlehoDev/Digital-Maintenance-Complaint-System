using Microsoft.AspNetCore.Mvc;
using CUT_Maintenance_Admin.Data;
using Microsoft.EntityFrameworkCore;

namespace CUT_Maintenance_Admin.Controllers
{
    public class AccountController : Controller
    {
        private readonly AppDbContext _context;

        public AccountController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult Login()
        {
            // If already logged in, go straight to Dashboard
            if (HttpContext.Session.GetString("AdminEmail") != null)
                return RedirectToAction("Dashboard", "Dashboard");

            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Login(string email, string password)
        {
            try
            {
                // 1. Fetch the user by email ONLY
                var user = await _context.Profiles
                    .FirstOrDefaultAsync(u => u.Email == email);

                // 2. Check if user exists
                if (user == null)
                {
                    ViewBag.Error = "User not found in database.";
                    return View();
                }

                // 3. Check if user is admin
                if (user.Role != "admin")
                {
                    ViewBag.Error = $"Access denied. Your role is '{user.Role}', not 'admin'.";
                    return View();
                }

                // 4. Check prototype password
                if (password != "admin123")
                {
                    ViewBag.Error = "Incorrect password. (Hint: use admin123)";
                    return View();
                }

                // 5. Success! Set session variables
                HttpContext.Session.SetString("AdminEmail", user.Email);
                HttpContext.Session.SetString("AdminName", user.FullName ?? "Admin");

                // Route directly to the new Dashboard greeting page
                return RedirectToAction("Dashboard", "Dashboard");
            }
            catch (Exception ex)
            {
                // Catch any database mapping errors and display them
                ViewBag.Error = "Database Error: " + ex.Message;
                return View();
            }
        }

        public IActionResult Logout()
        {
            HttpContext.Session.Clear();
            return RedirectToAction("Login", "Account");
        }
    }
}