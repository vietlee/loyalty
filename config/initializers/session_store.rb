# The merchant dashboard and customer app live on per-workspace subdomains
# (e.g. cozycafe.loyalty.czin.net). Scope the session cookie to the whole
# ".loyalty.czin.net" zone so a login started on any host stays valid when we
# send the merchant to their workspace subdomain. In dev/test we access the app
# by path on a single host, so a plain host-only cookie is correct there.
if Rails.env.production?
  Rails.application.config.session_store :cookie_store,
                                         key: "_loyalty_session",
                                         domain: ".loyalty.czin.net",
                                         same_site: :lax
else
  Rails.application.config.session_store :cookie_store, key: "_loyalty_session"
end
