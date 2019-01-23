using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using dotnet_example.Models;
using Microsoft.EntityFrameworkCore;
using Google.Cloud.Diagnostics.AspNetCore;
using ZNetCS.AspNetCore.Authentication.Basic;
using ZNetCS.AspNetCore.Authentication.Basic.Events;
using System.Security.Claims;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Authorization;

namespace dotnet_example
{
    public class Startup
    {
        private readonly ILogger _logger;

        public Startup(IConfiguration configuration, ILogger<Startup> logger)
        {
            Configuration = configuration;
            _logger = logger;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.Configure<CookiePolicyOptions>(options =>
            {
                // This lambda determines whether user consent for non-essential cookies is needed for a given request.
                options.CheckConsentNeeded = context => true;
                options.MinimumSameSitePolicy = SameSiteMode.None;
            });


            services.AddMvc().SetCompatibilityVersion(CompatibilityVersion.Version_2_1);

            string projectId = Google.Api.Gax.Platform.Instance().ProjectId;
            if (!string.IsNullOrEmpty(projectId))
            {
                services.AddGoogleExceptionLogging(options =>
                {
                    options.ProjectId = projectId;
                    options.ServiceName = "dotnet_example";
                    options.Version = Configuration["DEPLOY_ENV"];
                });
            }

            var connectionstring = Configuration.GetConnectionString("postgres");
            if (String.IsNullOrEmpty(connectionstring))
            {
                // use sqlite
                connectionstring = "Data Source=blogging.db";
                services.AddDbContext<BloggingContext>
                    (options => options.UseSqlite(connectionstring));
            }
            else
            {
                // use postgres
                services.AddDbContext<BloggingContext>
                    (options => options.UseNpgsql(connectionstring));
            }

            // set up basic auth here if there is a user
            var basicauthuser = Configuration["BASICAUTH_USER"];
            var basicauthpw = Configuration["BASICAUTH_PASSWORD"];
            if (! String.IsNullOrEmpty(basicauthuser))
            {
                _logger.LogInformation("user is {basicauthuser}", basicauthuser);
                services
                    .AddAuthentication(BasicAuthenticationDefaults.AuthenticationScheme)
                    .AddBasicAuthentication(
                        options =>
                        {
                            options.Realm = "dotnet-example";
                            options.Events = new BasicAuthenticationEvents
                            {
                                OnValidatePrincipal = context =>
                                {
                                    if ((context.UserName == basicauthuser) && (context.Password == basicauthpw))
                                    {
                                        var claims = new List<Claim>
                                        {
                                            new Claim(ClaimTypes.Name, context.UserName, context.Options.ClaimsIssuer)
                                        };

                                        var principal = new ClaimsPrincipal(new ClaimsIdentity(claims, BasicAuthenticationDefaults.AuthenticationScheme));
                                        context.Principal = principal;
                                    }
                                    else 
                                    {
                                        // optional with following default.
                                        // context.AuthenticationFailMessage = "Authentication failed."; 
                                    }

                                    return Task.CompletedTask;
                                }
                            };
                        });
            }
            else
            {
                // create an empty authorization that lets everybody in.
                services.AddAuthorization(x =>
                    x.DefaultPolicy = new AuthorizationPolicyBuilder()
                        .RequireAssertion(_ => true)
                        .Build());
            }
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IHostingEnvironment env)
        {
            var basicauthuser = Configuration["BASICAUTH_USER"];
            if (! String.IsNullOrEmpty(basicauthuser))
            {
                // default authentication initialization
                app.UseAuthentication();
            }

            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Home/Error");
                app.UseHsts();
            }

            UpdateDatabase(app);

            app.UseHttpsRedirection();
            app.UseStaticFiles();
            app.UseCookiePolicy();

            app.UseMvc(routes =>
            {
                routes.MapRoute(
                    name: "default",
                    template: "{controller=Blogs}/{action=Index}/{id?}");
            });
        }

        private static void UpdateDatabase(IApplicationBuilder app)
        {
            using (var serviceScope = app.ApplicationServices
                .GetRequiredService<IServiceScopeFactory>()
                .CreateScope())
            {
                using (var context = serviceScope.ServiceProvider.GetService<BloggingContext>())
                {
                    context.Database.Migrate();
                }
            }
        }
    }
}
