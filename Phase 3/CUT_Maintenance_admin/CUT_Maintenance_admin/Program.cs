using Microsoft.EntityFrameworkCore;
using CUT_Maintenance_Admin.Data;

var builder = WebApplication.CreateBuilder(args);

// 1. Add services
builder.Services.AddControllersWithViews();
builder.Services.AddSession();

// 2. Configure database and enum mapping
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString, o =>
    {
        // Key fix: Tell Npgsql about these two C# enums
        // The first parameter must match the database enum type name exactly
        o.MapEnum<ComplaintStatus>("complaint_status");
        o.MapEnum<PriorityLevel>("priority_level");
    }));

var app = builder.Build();

// 3. Middleware pipeline
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseSession(); // Must be before UseAuthorization
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Dashboard}/{action=Dashboard}/{id?}");
                        //Account           //Login
app.Run();