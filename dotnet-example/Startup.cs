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
using dotnet_example.Services;
using Microsoft.EntityFrameworkCore;
using Google.Cloud.Diagnostics.AspNetCore;
using ZNetCS.AspNetCore.Authentication.Basic;
using ZNetCS.AspNetCore.Authentication.Basic.Events;
using System.Security.Claims;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.DataProtection;

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

            // turn on GCP-related services here if we are deployed on it.
            string projectId = Google.Api.Gax.Platform.Instance().ProjectId;
            if (!string.IsNullOrEmpty(projectId))
            {
                // turn on google exception logging
                services.AddGoogleExceptionLogging(options =>
                {
                    options.ProjectId = projectId;
                    options.ServiceName = "dotnet_example";
                    options.Version = Configuration["DEPLOY_ENV"];
                });

                // Turn on KMS to store keys for antiforgery protection
                services.AddSingleton<IDataProtectionProvider>(serviceProvider =>
                    new KmsDataProtectionProvider(projectId, "global", "dataprotectionprovider")); 
            }

            // sqlite is used for local development.
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
                // create an empty authorization that lets everybobody in.
                services.AddAuthorization(x =>
                    x.DefaultPolicy = new AuthorizationPolicyBuilder()
                        .RequireAssertion(_ => true)
                        .Build());
            }
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IHostingEnvironment env)
        {
            // If we have a basic auth user, turn on authentication.
            var basicauthuser = Configuration["BASICAUTH_USER"];
            if (! String.IsNullOrEmpty(basicauthuser))
            {
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

            // Add various headers to prevent clickjacking, XSS, etc.
            app.Use(async (context, next) =>
            {
                context.Response.Headers.Add("X-Xss-Protection", "1; mode=block");
                await next();
            });
            app.Use(async (context, next) =>
            {
                context.Response.Headers.Add("X-Frame-Options", "SAMEORIGIN");
                await next();
            });
            app.Use(async (context, next) =>
            {
                context.Response.Headers.Add("X-Content-Type-Options", "nosniff");
                await next();
            });

            app.UseMvc(routes =>
            {
                routes.MapRoute(
                    name: "default",
                    template: "{controller=Blogs}/{action=Index}/{id?}");
            });
        }

        // This is to automatically do db migrations when the app starts up.
        // This is sort of brave, but it ensures that your app will deploy
        // without you having to allow database access to anybody.
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
