# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Router do
  use Pleroma.Web, :router
  import Phoenix.LiveDashboard.Router

  pipeline :accepts_html do
    plug(:accepts, ["html"])
  end

  pipeline :accepts_html_xml do
    plug(:accepts, ["html", "xml", "rss", "atom"])
  end

  pipeline :accepts_html_json do
    plug(:accepts, ["html", "activity+json", "json"])
  end

  pipeline :accepts_html_xml_json do
    plug(:accepts, ["html", "xml", "rss", "atom", "activity+json", "json"])
  end

  pipeline :accepts_xml_rss_atom do
    plug(:accepts, ["xml", "rss", "atom"])
  end

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end

  pipeline :oauth do
    plug(:fetch_session)
    plug(Pleroma.Web.Plugs.OAuthPlug)
    plug(Pleroma.Web.Plugs.UserEnabledPlug)
    plug(Pleroma.Web.Plugs.EnsureUserTokenAssignsPlug)
  end

  # Note: expects _user_ authentication (user-unbound app-bound tokens don't qualify)
  pipeline :expect_user_authentication do
    plug(Pleroma.Web.Plugs.ExpectAuthenticatedCheckPlug)
  end

  # Note: expects public instance or _user_ authentication (user-unbound tokens don't qualify)
  pipeline :expect_public_instance_or_user_authentication do
    plug(Pleroma.Web.Plugs.ExpectPublicOrAuthenticatedCheckPlug)
  end

  pipeline :authenticate do
    plug(Pleroma.Web.Plugs.OAuthPlug)
    plug(Pleroma.Web.Plugs.BasicAuthDecoderPlug)
    plug(Pleroma.Web.Plugs.UserFetcherPlug)
    plug(Pleroma.Web.Plugs.AuthenticationPlug)
  end

  pipeline :after_auth do
    plug(Pleroma.Web.Plugs.UserEnabledPlug)
    plug(Pleroma.Web.Plugs.SetUserSessionIdPlug)
    plug(Pleroma.Web.Plugs.EnsureUserTokenAssignsPlug)
    plug(Pleroma.Web.Plugs.UserTrackingPlug)
  end

  pipeline :base_api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(:authenticate)
    plug(OpenApiSpex.Plug.PutApiSpec, module: Pleroma.Web.ApiSpec)
  end

  pipeline :no_auth_or_privacy_expectations_api do
    plug(:base_api)
    plug(:after_auth)
    plug(Pleroma.Web.Plugs.IdempotencyPlug)
  end

  # Pipeline for app-related endpoints (no user auth checks — app-bound tokens must be supported)
  pipeline :app_api do
    plug(:no_auth_or_privacy_expectations_api)
  end

  pipeline :api do
    plug(:expect_public_instance_or_user_authentication)
    plug(:no_auth_or_privacy_expectations_api)
  end

  pipeline :authenticated_api do
    plug(:expect_user_authentication)
    plug(:no_auth_or_privacy_expectations_api)
    plug(Pleroma.Web.Plugs.EnsureAuthenticatedPlug)
  end

  pipeline :admin_api do
    plug(:expect_user_authentication)
    plug(:base_api)
    plug(Pleroma.Web.Plugs.AdminSecretAuthenticationPlug)
    plug(:after_auth)
    plug(Pleroma.Web.Plugs.EnsureAuthenticatedPlug)
    plug(Pleroma.Web.Plugs.UserIsStaffPlug)
    plug(Pleroma.Web.Plugs.IdempotencyPlug)
  end

  pipeline :require_admin do
    plug(Pleroma.Web.Plugs.UserIsAdminPlug)
  end

  pipeline :require_privileged_role_users_delete do
    plug(:admin_api)
    plug(Pleroma.Web.Plugs.EnsurePrivilegedPlug, :users_delete)
  end

  pipeline :require_privileged_role_users_manage_credentials do
    plug(:admin_api)
    plug(Pleroma.Web.Plugs.EnsurePrivilegedPlug, :users_manage_credentials)
  end

  pipeline :require_privileged_role_messages_read do
    plug(:admin_api)
    plug(Pleroma.Web.Plugs.EnsurePrivilegedPlug, :messages_read)
  end

  pipeline :require_privileged_role_users_manage_tags do
    plug(:admin_api)
    plug(Pleroma.Web.Plugs.EnsurePrivilegedPlug, :users_manage_tags)
  end

  pipeline :require_privileged_role_users_manage_activation_state do
    plug(:admin_api)
    plug(Pleroma.Web.Plugs.EnsurePrivilegedPlug, :users_manage_activation_state)
  end

  pipeline :require_privileged_role_users_manage_invites do
    plug(:admin_api)
    plug(Pleroma.Web.Plugs.EnsurePrivilegedPlug, :users_manage_invites)
  end

  pipeline :require_privileged_role_reports_manage_reports do
    plug(:admin_api)
    plug(Pleroma.Web.Plugs.EnsurePrivilegedPlug, :reports_manage_reports)
  end

  pipeline :require_privileged_role_users_read do
    plug(:admin_api)
    plug(Pleroma.Web.Plugs.EnsurePrivilegedPlug, :users_read)
  end

  pipeline :require_privileged_role_messages_delete do
    plug(:admin_api)
    plug(Pleroma.Web.Plugs.EnsurePrivilegedPlug, :messages_delete)
  end

  pipeline :require_privileged_role_emoji_manage_emoji do
    plug(:admin_api)
    plug(Pleroma.Web.Plugs.EnsurePrivilegedPlug, :emoji_manage_emoji)
  end

  pipeline :require_privileged_role_instances_delete do
    plug(:admin_api)
    plug(Pleroma.Web.Plugs.EnsurePrivilegedPlug, :instances_delete)
  end

  pipeline :require_privileged_role_moderation_log_read do
    plug(:admin_api)
    plug(Pleroma.Web.Plugs.EnsurePrivilegedPlug, :moderation_log_read)
  end

  pipeline :require_privileged_role_statistics_read do
    plug(:admin_api)
    plug(Pleroma.Web.Plugs.EnsurePrivilegedPlug, :statistics_read)
  end

  pipeline :require_privileged_role_announcements_manage_announcements do
    plug(:admin_api)
    plug(Pleroma.Web.Plugs.EnsurePrivilegedPlug, :announcements_manage_announcements)
  end

  pipeline :pleroma_html do
    plug(:browser)
    plug(:authenticate)
    plug(Pleroma.Web.Plugs.EnsureUserTokenAssignsPlug)
  end

  pipeline :well_known do
    plug(:accepts, ["json", "jrd+json", "xml", "xrd+xml"])
  end

  pipeline :config do
    plug(:accepts, ["json", "xml"])
    plug(OpenApiSpex.Plug.PutApiSpec, module: Pleroma.Web.ApiSpec)
  end

  pipeline :pleroma_api do
    plug(:accepts, ["html", "json"])
    plug(OpenApiSpex.Plug.PutApiSpec, module: Pleroma.Web.ApiSpec)
  end

  pipeline :mailbox_preview do
    plug(:accepts, ["html"])

    plug(:put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline' 'unsafe-eval'"
    })
  end

  pipeline :http_signature do
    plug(Pleroma.Web.Plugs.HTTPSignaturePlug)
    plug(Pleroma.Web.Plugs.MappedSignatureToIdentityPlug)
  end

  pipeline :static_fe do
    plug(Pleroma.Web.Plugs.StaticFEPlug)
  end

  scope "/api/v1/pleroma", Pleroma.Web.TwitterAPI do
    pipe_through(:pleroma_api)

    get("/password_reset/:token", PasswordController, :reset, as: :reset_password)
    post("/password_reset", PasswordController, :do_reset, as: :reset_password)
    get("/emoji", UtilController, :emoji)
    get("/captcha", UtilController, :captcha)
    get("/healthcheck", UtilController, :healthcheck)
    post("/remote_interaction", UtilController, :remote_interaction)
  end

  scope "/api/v1/pleroma", Pleroma.Web.PleromaAPI do
    pipe_through(:pleroma_api)

    get("/federation_status", InstancesController, :show)
  end

  scope "/api/v1/pleroma", Pleroma.Web do
    pipe_through(:pleroma_api)
    post("/uploader_callback/:upload_path", UploaderController, :callback)
  end

  # AdminAPI: only admins can perform these actions
  scope "/api/v1/pleroma/admin", Pleroma.Web.AdminAPI do
    pipe_through([:admin_api, :require_admin])

    get("/users/:nickname/permission_group", AdminAPIController, :right_get)
    get("/users/:nickname/permission_group/:permission_group", AdminAPIController, :right_get)

    post("/users/:nickname/permission_group/:permission_group", AdminAPIController, :right_add)

    delete(
      "/users/:nickname/permission_group/:permission_group",
      AdminAPIController,
      :right_delete
    )

    post("/users/permission_group/:permission_group", AdminAPIController, :right_add_multiple)

    delete(
      "/users/permission_group/:permission_group",
      AdminAPIController,
      :right_delete_multiple
    )

    post("/users/follow", UserController, :follow)
    post("/users/unfollow", UserController, :unfollow)
    post("/users", UserController, :create)

    patch("/users/suggest", UserController, :suggest)
    patch("/users/unsuggest", UserController, :unsuggest)

    get("/relay", RelayController, :index)
    post("/relay", RelayController, :follow)
    delete("/relay", RelayController, :unfollow)

    get("/instance_document/:name", InstanceDocumentController, :show)
    patch("/instance_document/:name", InstanceDocumentController, :update)
    delete("/instance_document/:name", InstanceDocumentController, :delete)

    get("/config", ConfigController, :show)
    post("/config", ConfigController, :update)
    get("/config/descriptions", ConfigController, :descriptions)
    get("/need_reboot", AdminAPIController, :need_reboot)
    get("/restart", AdminAPIController, :restart)

    get("/oauth_app", OAuthAppController, :index)
    post("/oauth_app", OAuthAppController, :create)
    patch("/oauth_app/:id", OAuthAppController, :update)
    delete("/oauth_app/:id", OAuthAppController, :delete)

    get("/media_proxy_caches", MediaProxyCacheController, :index)
    post("/media_proxy_caches/delete", MediaProxyCacheController, :delete)
    post("/media_proxy_caches/purge", MediaProxyCacheController, :purge)

    get("/frontends", FrontendController, :index)
    post("/frontends/install", FrontendController, :install)

    post("/backups", AdminAPIController, :create_backup)

    get("/email_list/subscribers.csv", EmailListController, :subscribers)
    get("/email_list/unsubscribers.csv", EmailListController, :unsubscribers)
    get("/email_list/combined.csv", EmailListController, :combined)

    get("/rules", RuleController, :index)
    post("/rules", RuleController, :create)
    patch("/rules/:id", RuleController, :update)
    delete("/rules/:id", RuleController, :delete)

    get("/webhooks", WebhookController, :index)
    get("/webhooks/:id", WebhookController, :show)
    post("/webhooks", WebhookController, :create)
    patch("/webhooks/:id", WebhookController, :update)
    delete("/webhooks/:id", WebhookController, :delete)
    post("/webhooks/:id/enable", WebhookController, :enable)
    post("/webhooks/:id/disable", WebhookController, :disable)
    post("/webhooks/:id/rotate_secret", WebhookController, :rotate_secret)
  end

  # AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/pleroma/admin", Pleroma.Web.AdminAPI do
    pipe_through(:require_privileged_role_announcements_manage_announcements)

    get("/announcements", AnnouncementController, :index)
    post("/announcements", AnnouncementController, :create)
    get("/announcements/:id", AnnouncementController, :show)
    patch("/announcements/:id", AnnouncementController, :change)
    delete("/announcements/:id", AnnouncementController, :delete)
  end

  # AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/pleroma/admin", Pleroma.Web.AdminAPI do
    pipe_through(:require_privileged_role_users_delete)

    delete("/users", UserController, :delete)
  end

  # AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/pleroma/admin", Pleroma.Web.AdminAPI do
    pipe_through(:require_privileged_role_users_manage_credentials)

    get("/users/:nickname/password_reset", AdminAPIController, :get_password_reset)
    get("/users/:nickname/credentials", AdminAPIController, :show_user_credentials)
    patch("/users/:nickname/credentials", AdminAPIController, :update_user_credentials)
    put("/users/disable_mfa", AdminAPIController, :disable_mfa)
    patch("/users/force_password_reset", AdminAPIController, :force_password_reset)
    patch("/users/confirm_email", AdminAPIController, :confirm_email)
    patch("/users/resend_confirmation_email", AdminAPIController, :resend_confirmation_email)
  end

  # AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/pleroma/admin", Pleroma.Web.AdminAPI do
    pipe_through(:require_privileged_role_messages_read)

    get("/users/:nickname/statuses", AdminAPIController, :list_user_statuses)
    get("/users/:nickname/chats", AdminAPIController, :list_user_chats)

    get("/statuses", StatusController, :index)

    get("/chats/:id", ChatController, :show)
    get("/chats/:id/messages", ChatController, :messages)

    get("/instances/:instance/statuses", InstanceController, :list_statuses)

    get("/statuses/:id", StatusController, :show)
  end

  # AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/pleroma/admin", Pleroma.Web.AdminAPI do
    pipe_through(:require_privileged_role_users_manage_tags)

    put("/users/tag", AdminAPIController, :tag_users)
    delete("/users/tag", AdminAPIController, :untag_users)
  end

  # AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/pleroma/admin", Pleroma.Web.AdminAPI do
    pipe_through(:require_privileged_role_users_manage_activation_state)

    patch("/users/:nickname/toggle_activation", UserController, :toggle_activation)
    patch("/users/activate", UserController, :activate)
    patch("/users/deactivate", UserController, :deactivate)
  end

  # AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/pleroma/admin", Pleroma.Web.AdminAPI do
    pipe_through(:require_privileged_role_users_manage_invites)

    patch("/users/approve", UserController, :approve)
    post("/users/invite_token", InviteController, :create)
    get("/users/invites", InviteController, :index)
    post("/users/revoke_invite", InviteController, :revoke)
    post("/users/email_invite", InviteController, :email)
  end

  # AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/pleroma/admin", Pleroma.Web.AdminAPI do
    pipe_through(:require_privileged_role_reports_manage_reports)

    get("/reports", ReportController, :index)
    get("/reports/:id", ReportController, :show)
    patch("/reports", ReportController, :update)
    post("/reports/assign_account", ReportController, :assign_account)
    post("/reports/:id/notes", ReportController, :notes_create)
    delete("/reports/:report_id/notes/:id", ReportController, :notes_delete)
  end

  # AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/pleroma/admin", Pleroma.Web.AdminAPI do
    pipe_through(:require_privileged_role_users_read)

    get("/users", UserController, :index)
    get("/users/:nickname", UserController, :show)
  end

  # AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/pleroma/admin", Pleroma.Web.AdminAPI do
    pipe_through(:require_privileged_role_messages_delete)

    put("/statuses/:id", StatusController, :update)
    delete("/statuses/:id", StatusController, :delete)

    delete("/chats/:id/messages/:message_id", ChatController, :delete_message)
  end

  # AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/pleroma/admin", Pleroma.Web.AdminAPI do
    pipe_through(:require_privileged_role_emoji_manage_emoji)

    post("/reload_emoji", AdminAPIController, :reload_emoji)
  end

  # AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/pleroma/admin", Pleroma.Web.AdminAPI do
    pipe_through(:require_privileged_role_instances_delete)

    delete("/instances/:instance", InstanceController, :delete)
  end

  # AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/pleroma/admin", Pleroma.Web.AdminAPI do
    pipe_through(:require_privileged_role_moderation_log_read)

    get("/moderation_log", AdminAPIController, :list_log)
  end

  # AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/pleroma/admin", Pleroma.Web.AdminAPI do
    pipe_through(:require_privileged_role_statistics_read)

    get("/stats", AdminAPIController, :stats)
  end

  # Mastodon AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/admin", Pleroma.Web.MastodonAPI.Admin do
    pipe_through([:require_privileged_role_users_read])

    get("/accounts", AccountController, :index)
    get("/accounts/:id", AccountController, :show)
  end

  # Mastodon AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/admin", Pleroma.Web.MastodonAPI.Admin do
    pipe_through(:require_privileged_role_users_delete)

    delete("/accounts/:id", AccountController, :delete)
  end

  # Mastodon AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/admin", Pleroma.Web.MastodonAPI.Admin do
    pipe_through([:require_privileged_role_users_manage_activation_state])

    post("/accounts/:id/action", AccountController, :account_action)
    post("/accounts/:id/enable", AccountController, :enable)
  end

  # Mastodon AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/admin", Pleroma.Web.MastodonAPI.Admin do
    pipe_through([:require_privileged_role_users_manage_invites])
    post("/accounts/:id/approve", AccountController, :approve)
    post("/accounts/:id/reject", AccountController, :reject)
  end

  # Mastodon AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
  scope "/api/v1/admin", Pleroma.Web.MastodonAPI.Admin do
    pipe_through([:require_privileged_role_reports_manage_reports])

    get("/reports", ReportController, :index)
    get("/reports/:id", ReportController, :show)
    post("/reports/:id/resolve", ReportController, :resolve)
    post("/reports/:id/reopen", ReportController, :reopen)
    post("/reports/:id/assign_to_self", ReportController, :assign_to_self)
    post("/reports/:id/unassign", ReportController, :unassign)
  end

  scope "/api/v1/pleroma/emoji", Pleroma.Web.PleromaAPI do
    scope "/pack" do
      pipe_through(:require_privileged_role_emoji_manage_emoji)

      post("/", EmojiPackController, :create)
      patch("/", EmojiPackController, :update)
      delete("/", EmojiPackController, :delete)
    end

    scope "/pack" do
      pipe_through(:api)

      get("/", EmojiPackController, :show)
    end

    # Modifying packs
    scope "/packs" do
      pipe_through(:require_privileged_role_emoji_manage_emoji)

      get("/import", EmojiPackController, :import_from_filesystem)
      get("/remote", EmojiPackController, :remote)
      post("/download", EmojiPackController, :download)

      post("/files", EmojiFileController, :create)
      patch("/files", EmojiFileController, :update)
      delete("/files", EmojiFileController, :delete)
    end

    # Pack info / downloading
    scope "/packs" do
      pipe_through(:api)

      get("/", EmojiPackController, :index)
      get("/archive", EmojiPackController, :archive)
    end
  end

  scope "/", Pleroma.Web.TwitterAPI do
    pipe_through(:pleroma_html)

    post("/main/ostatus", UtilController, :remote_subscribe)
    get("/main/ostatus", UtilController, :show_subscribe_form)
    get("/ostatus_subscribe", RemoteFollowController, :follow)
    post("/ostatus_subscribe", RemoteFollowController, :do_follow)

    get("/authorize_interaction", RemoteFollowController, :authorize_interaction)
  end

  scope "/api/pleroma", Pleroma.Web.TwitterAPI do
    pipe_through(:authenticated_api)

    post("/change_email", UtilController, :change_email)
    post("/change_password", UtilController, :change_password)
    post("/delete_account", UtilController, :delete_account)
    put("/notification_settings", UtilController, :update_notificaton_settings)
    post("/disable_account", UtilController, :disable_account)
    post("/move_account", UtilController, :move_account)

    put("/aliases", UtilController, :add_alias)
    get("/aliases", UtilController, :list_aliases)
    delete("/aliases", UtilController, :delete_alias)
  end

  scope "/api/pleroma", Pleroma.Web.PleromaAPI do
    pipe_through(:authenticated_api)

    post("/mutes_import", UserImportController, :mutes)
    post("/blocks_import", UserImportController, :blocks)
    post("/follow_import", UserImportController, :follow)

    get("/accounts/mfa", TwoFactorAuthenticationController, :settings)
    get("/accounts/mfa/backup_codes", TwoFactorAuthenticationController, :backup_codes)
    get("/accounts/mfa/setup/:method", TwoFactorAuthenticationController, :setup)
    post("/accounts/mfa/confirm/:method", TwoFactorAuthenticationController, :confirm)
    delete("/accounts/mfa/:method", TwoFactorAuthenticationController, :disable)
  end

  scope "/oauth", Pleroma.Web.OAuth do
    # Note: use /api/v1/accounts/verify_credentials for userinfo of signed-in user

    get("/registration_details", OAuthController, :registration_details)

    post("/mfa/verify", MFAController, :verify, as: :mfa_verify)
    get("/mfa", MFAController, :show)

    scope [] do
      pipe_through(:oauth)

      get("/authorize", OAuthController, :authorize)
      post("/authorize", OAuthController, :create_authorization)
    end

    scope [] do
      pipe_through(:fetch_session)

      post("/token", OAuthController, :token_exchange)
      post("/revoke", OAuthController, :token_revoke)
      post("/mfa/challenge", MFAController, :challenge)
    end

    scope [] do
      pipe_through(:browser)

      get("/prepare_request", OAuthController, :prepare_request)
      get("/:provider", OAuthController, :request)
      get("/:provider/callback", OAuthController, :callback)
      post("/register", OAuthController, :register)
    end
  end

  scope "/api/v1/pleroma", Pleroma.Web.PleromaAPI do
    pipe_through(:api)

    get("/apps", AppController, :index)
    get("/statuses/:id/reactions/:emoji", EmojiReactionController, :index)
    get("/statuses/:id/reactions", EmojiReactionController, :index)
  end

  scope "/api/v0/pleroma", Pleroma.Web.PleromaAPI do
    pipe_through(:authenticated_api)
    get("/reports", ReportController, :index)
    get("/reports/:id", ReportController, :show)
  end

  scope "/api/v1/pleroma", Pleroma.Web.PleromaAPI do
    scope [] do
      pipe_through(:authenticated_api)

      post("/chats/by-account-id/:id", ChatController, :create)
      get("/chats", ChatController, :index)
      get("/chats/:id", ChatController, :show)
      delete("/chats/:id", ChatController, :delete)
      get("/chats/:id/messages", ChatController, :messages)
      post("/chats/:id/messages", ChatController, :post_chat_message)
      delete("/chats/:id/messages/:message_id", ChatController, :delete_message)
      post("/chats/:id/read", ChatController, :mark_as_read)
      post("/chats/:id/messages/:message_id/read", ChatController, :mark_message_as_read)

      get("/conversations/:id/statuses", ConversationController, :statuses)
      get("/conversations/:id", ConversationController, :show)
      post("/conversations/read", ConversationController, :mark_as_read)
      patch("/conversations/:id", ConversationController, :update)

      put("/statuses/:id/reactions/:emoji", EmojiReactionController, :create)
      delete("/statuses/:id/reactions/:emoji", EmojiReactionController, :delete)
      post("/notifications/read", NotificationController, :mark_as_read)

      get("/mascot", MascotController, :show)
      put("/mascot", MascotController, :update)

      post("/scrobble", ScrobbleController, :create)

      get("/backups", BackupController, :index)
      post("/backups", BackupController, :create)

      post("/events", EventController, :create)
      get("/events/joined_events", EventController, :joined_events)
      put("/events/:id", EventController, :update)
      get("/events/:id/participations", EventController, :participations)
      get("/events/:id/participation_requests", EventController, :participation_requests)

      post(
        "/events/:id/participation_requests/:participant_id/authorize",
        EventController,
        :authorize_participation_request
      )

      post(
        "/events/:id/participation_requests/:participant_id/reject",
        EventController,
        :reject_participation_request
      )

      post("/events/:id/join", EventController, :join)
      post("/events/:id/leave", EventController, :leave)
      get("/events/:id/ics", EventController, :export_ics)

      get("/search/location", SearchController, :location)
    end

    scope [] do
      pipe_through(:api)
      get("/accounts/:id/favourites", AccountController, :favourites)
      get("/accounts/:id/endorsements", AccountController, :endorsements)

      get("/statuses/:id/quotes", StatusController, :quotes)
    end

    scope [] do
      pipe_through(:authenticated_api)

      post("/accounts/:id/subscribe", AccountController, :subscribe)
      post("/accounts/:id/unsubscribe", AccountController, :unsubscribe)

      get("/birthdays", AccountController, :birthdays)
    end

    post("/accounts/confirmation_resend", AccountController, :confirmation_resend)
  end

  scope "/api/v1/pleroma", Pleroma.Web.PleromaAPI do
    pipe_through(:api)
    get("/accounts/:id/scrobbles", ScrobbleController, :index)
  end

  scope "/api/v2/pleroma", Pleroma.Web.PleromaAPI do
    scope [] do
      pipe_through(:authenticated_api)
      get("/chats", ChatController, :index2)
    end
  end

  scope "/api/v1/ordo/admin", Pleroma.Web.AdminAPI do
    # AdminAPI: only admins can perform these actions
    scope [] do
      pipe_through([:admin_api, :require_admin])

      get("/email_list/subscribers.csv", EmailListController, :subscribers)
      get("/email_list/unsubscribers.csv", EmailListController, :unsubscribers)
      get("/email_list/combined.csv", EmailListController, :combined)

      get("/rules", RuleController, :index)
      post("/rules", RuleController, :create)
      patch("/rules/:id", RuleController, :update)
      delete("/rules/:id", RuleController, :delete)

      get("/webhooks", WebhookController, :index)
      get("/webhooks/:id", WebhookController, :show)
      post("/webhooks", WebhookController, :create)
      patch("/webhooks/:id", WebhookController, :update)
      delete("/webhooks/:id", WebhookController, :delete)
      post("/webhooks/:id/enable", WebhookController, :enable)
      post("/webhooks/:id/disable", WebhookController, :disable)
      post("/webhooks/:id/rotate_secret", WebhookController, :rotate_secret)
    end

    # AdminAPI: admins and mods (staff) can perform these actions (if privileged by role)
    scope [] do
      pipe_through(:require_privileged_role_reports_manage_reports)

      post("/reports/assign_account", ReportController, :assign_account)
    end
  end

  scope "/api/v1/ordo", Pleroma.Web.PleromaAPI do
    scope [] do
      pipe_through(:authenticated_api)

      post("/events", EventController, :create)
      get("/events/joined_events", EventController, :joined_events)
      put("/events/:id", EventController, :update)
      get("/events/:id/participations", EventController, :participations)
      get("/events/:id/participation_requests", EventController, :participation_requests)

      post(
        "/events/:id/participation_requests/:participant_id/authorize",
        EventController,
        :authorize_participation_request
      )

      post(
        "/events/:id/participation_requests/:participant_id/reject",
        EventController,
        :reject_participation_request
      )

      post("/events/:id/join", EventController, :join)
      post("/events/:id/leave", EventController, :leave)
      get("/events/:id/ics", EventController, :export_ics)

      get("/search/location", SearchController, :location)
    end

    scope [] do
      pipe_through(:api)

      get("/statuses/:id/quotes", StatusController, :quotes)
    end
  end

  scope "/api/v1", Pleroma.Web.MastodonAPI do
    pipe_through(:authenticated_api)

    get("/accounts/verify_credentials", AccountController, :verify_credentials)
    patch("/accounts/update_credentials", AccountController, :update_credentials)

    get("/accounts/relationships", AccountController, :relationships)
    get("/accounts/familiar_followers", AccountController, :familiar_followers)
    get("/accounts/:id/lists", AccountController, :lists)
    get("/accounts/:id/identity_proofs", AccountController, :identity_proofs)
    get("/endorsements", AccountController, :endorsements)
    get("/blocks", AccountController, :blocks)
    get("/mutes", AccountController, :mutes)

    post("/follows", AccountController, :follow_by_uri)
    post("/accounts/:id/follow", AccountController, :follow)
    post("/accounts/:id/unfollow", AccountController, :unfollow)
    post("/accounts/:id/block", AccountController, :block)
    post("/accounts/:id/unblock", AccountController, :unblock)
    post("/accounts/:id/mute", AccountController, :mute)
    post("/accounts/:id/unmute", AccountController, :unmute)
    post("/accounts/:id/note", AccountController, :note)
    post("/accounts/:id/pin", AccountController, :endorse)
    post("/accounts/:id/unpin", AccountController, :unendorse)
    post("/accounts/:id/remove_from_followers", AccountController, :remove_from_followers)

    get("/conversations", ConversationController, :index)
    post("/conversations/:id/read", ConversationController, :mark_as_read)
    delete("/conversations/:id", ConversationController, :delete)

    get("/domain_blocks", DomainBlockController, :index)
    post("/domain_blocks", DomainBlockController, :create)
    delete("/domain_blocks", DomainBlockController, :delete)

    get("/filters", FilterController, :index)

    post("/filters", FilterController, :create)
    get("/filters/:id", FilterController, :show)
    put("/filters/:id", FilterController, :update)
    delete("/filters/:id", FilterController, :delete)

    get("/follow_requests", FollowRequestController, :index)
    post("/follow_requests/:id/authorize", FollowRequestController, :authorize)
    post("/follow_requests/:id/reject", FollowRequestController, :reject)

    get("/lists", ListController, :index)
    get("/lists/:id", ListController, :show)
    get("/lists/:id/accounts", ListController, :list_accounts)

    delete("/lists/:id", ListController, :delete)
    post("/lists", ListController, :create)
    put("/lists/:id", ListController, :update)
    post("/lists/:id/accounts", ListController, :add_to_list)
    delete("/lists/:id/accounts", ListController, :remove_from_list)

    get("/markers", MarkerController, :index)
    post("/markers", MarkerController, :upsert)

    post("/media", MediaController, :create)
    get("/media/:id", MediaController, :show)
    put("/media/:id", MediaController, :update)

    get("/notifications", NotificationController, :index)
    get("/notifications/:id", NotificationController, :show)

    post("/notifications/:id/dismiss", NotificationController, :dismiss)
    post("/notifications/clear", NotificationController, :clear)
    delete("/notifications/destroy_multiple", NotificationController, :destroy_multiple)
    # Deprecated: was removed in Mastodon v3, use `/notifications/:id/dismiss` instead
    post("/notifications/dismiss", NotificationController, :dismiss_via_body)

    post("/polls/:id/votes", PollController, :vote)

    post("/reports", ReportController, :create)

    get("/scheduled_statuses", ScheduledActivityController, :index)
    get("/scheduled_statuses/:id", ScheduledActivityController, :show)

    put("/scheduled_statuses/:id", ScheduledActivityController, :update)
    delete("/scheduled_statuses/:id", ScheduledActivityController, :delete)

    # Unlike `GET /api/v1/accounts/:id/favourites`, demands authentication
    get("/favourites", StatusController, :favourites)
    get("/bookmarks", StatusController, :bookmarks)

    post("/statuses", StatusController, :create)
    put("/statuses/:id", StatusController, :update)
    delete("/statuses/:id", StatusController, :delete)
    post("/statuses/:id/reblog", StatusController, :reblog)
    post("/statuses/:id/unreblog", StatusController, :unreblog)
    post("/statuses/:id/favourite", StatusController, :favourite)
    post("/statuses/:id/unfavourite", StatusController, :unfavourite)
    post("/statuses/:id/pin", StatusController, :pin)
    post("/statuses/:id/unpin", StatusController, :unpin)
    post("/statuses/:id/bookmark", StatusController, :bookmark)
    post("/statuses/:id/unbookmark", StatusController, :unbookmark)
    post("/statuses/:id/mute", StatusController, :mute_conversation)
    post("/statuses/:id/unmute", StatusController, :unmute_conversation)

    post("/push/subscription", SubscriptionController, :create)
    get("/push/subscription", SubscriptionController, :show)
    put("/push/subscription", SubscriptionController, :update)
    delete("/push/subscription", SubscriptionController, :delete)

    get("/suggestions", SuggestionController, :index)
    delete("/suggestions/:account_id", SuggestionController, :dismiss)

    get("/timelines/home", TimelineController, :home)
    get("/timelines/direct", TimelineController, :direct)
    get("/timelines/list/:list_id", TimelineController, :list)

    get("/announcements", AnnouncementController, :index)
    post("/announcements/:id/dismiss", AnnouncementController, :mark_read)
  end

  scope "/api/v1", Pleroma.Web.MastodonAPI do
    pipe_through(:app_api)

    post("/apps", AppController, :create)
    get("/apps/verify_credentials", AppController, :verify_credentials)
  end

  scope "/api/v1", Pleroma.Web.MastodonAPI do
    pipe_through(:api)

    get("/accounts/search", SearchController, :account_search)
    get("/search", SearchController, :search)

    get("/accounts/lookup", AccountController, :lookup)

    get("/accounts/:id/statuses", AccountController, :statuses)
    get("/accounts/:id/followers", AccountController, :followers)
    get("/accounts/:id/following", AccountController, :following)
    get("/accounts/:id", AccountController, :show)

    post("/accounts", AccountController, :create)

    get("/instance", InstanceController, :show)
    get("/instance/peers", InstanceController, :peers)
    get("/instance/rules", InstanceController, :rules)
    get("/instance/domain_blocks", InstanceController, :domain_blocks)
    get("/instance/translation_languages", InstanceController, :translation_languages)

    get("/statuses", StatusController, :index)
    get("/statuses/:id", StatusController, :show)
    get("/statuses/:id/context", StatusController, :context)
    get("/statuses/:id/card", StatusController, :card)
    get("/statuses/:id/favourited_by", StatusController, :favourited_by)
    get("/statuses/:id/reblogged_by", StatusController, :reblogged_by)
    get("/statuses/:id/history", StatusController, :show_history)
    get("/statuses/:id/source", StatusController, :show_source)
    post("/statuses/:id/translate", StatusController, :translate)

    get("/custom_emojis", CustomEmojiController, :index)

    get("/trends", MastodonAPIController, :empty_array)

    get("/timelines/public", TimelineController, :public)
    get("/timelines/tag/:tag", TimelineController, :hashtag)

    get("/polls/:id", PollController, :show)

    get("/directory", DirectoryController, :index)
  end

  scope "/api/v2", Pleroma.Web.MastodonAPI do
    pipe_through(:api)

    get("/search", SearchController, :search2)

    post("/media", MediaController, :create2)

    get("/suggestions", SuggestionController, :index2)

    get("/instance", InstanceController, :show2)
  end

  scope "/api", Pleroma.Web do
    pipe_through(:config)

    get("/pleroma/frontend_configurations", TwitterAPI.UtilController, :frontend_configurations)
  end

  scope "/api", Pleroma.Web do
    pipe_through(:api)

    get(
      "/account/confirm_email/:user_id/:token",
      TwitterAPI.Controller,
      :confirm_email,
      as: :confirm_email
    )
  end

  scope "/api" do
    pipe_through(:base_api)

    get("/openapi", OpenApiSpex.Plug.RenderSpec, [])
  end

  scope "/api", Pleroma.Web, as: :authenticated_twitter_api do
    pipe_through(:authenticated_api)

    get("/oauth_tokens", TwitterAPI.Controller, :oauth_tokens)
    delete("/oauth_tokens/:id", TwitterAPI.Controller, :revoke_token)
    delete("/oauth_tokens", TwitterAPI.Controller, :revoke_all_tokens)
  end

  scope "/", Pleroma.Web do
    # Note: html format is supported only if static FE is enabled
    # Note: http signature is only considered for json requests (no auth for non-json requests)
    pipe_through([:accepts_html_json, :http_signature, :static_fe])

    get("/objects/:uuid", OStatus.OStatusController, :object)
    get("/activities/:uuid", OStatus.OStatusController, :activity)
    get("/notice/:id", OStatus.OStatusController, :notice)

    # Notice compatibility routes for other frontends
    get("/@:nickname/:id", OStatus.OStatusController, :notice)
    get("/@:nickname/posts/:id", OStatus.OStatusController, :notice)
    get("/:nickname/status/:id", OStatus.OStatusController, :notice)

    # Mastodon compatibility routes
    get("/users/:nickname/statuses/:id", OStatus.OStatusController, :object)
    get("/users/:nickname/statuses/:id/activity", OStatus.OStatusController, :activity)
  end

  scope "/", Pleroma.Web do
    # Note: html format is supported only if static FE is enabled
    # Note: http signature is only considered for json requests (no auth for non-json requests)
    pipe_through([:accepts_html_xml_json, :http_signature, :static_fe])

    # Note: returns user _profile_ for json requests, redirects to user _feed_ for non-json ones
    get("/users/:nickname", Feed.UserController, :feed_redirect, as: :user_feed)
    get("/@:nickname", Feed.UserController, :feed_redirect, as: :user_feed)
  end

  scope "/", Pleroma.Web do
    pipe_through([:accepts_html_xml])

    get("/users/:nickname/feed", Feed.UserController, :feed, as: :user_feed)
  end

  scope "/", Pleroma.Web do
    pipe_through(:accepts_html)
    get("/notice/:id/embed_player", OStatus.OStatusController, :notice_player)
  end

  scope "/", Pleroma.Web do
    pipe_through(:accepts_xml_rss_atom)
    get("/tags/:tag", Feed.TagController, :feed, as: :tag_feed)
  end

  scope "/", Pleroma.Web do
    pipe_through(:browser)
    get("/mailer/unsubscribe/:token", Mailer.SubscriptionController, :unsubscribe)
  end

  pipeline :ap_service_actor do
    plug(:accepts, ["activity+json", "json"])
  end

  # Server to Server (S2S) AP interactions
  pipeline :activitypub do
    plug(:ap_service_actor)
    plug(:http_signature)
  end

  # Client to Server (C2S) AP interactions
  pipeline :activitypub_client do
    plug(:ap_service_actor)
    plug(:fetch_session)
    plug(:authenticate)
    plug(:after_auth)
  end

  scope "/", Pleroma.Web.ActivityPub do
    pipe_through([:activitypub_client])

    get("/api/ap/whoami", ActivityPubController, :whoami)
    get("/users/:nickname/inbox", ActivityPubController, :read_inbox)

    get("/users/:nickname/outbox", ActivityPubController, :outbox)

    # The following two are S2S as well, see `ActivityPub.fetch_follow_information_for_user/1`:
    get("/users/:nickname/followers", ActivityPubController, :followers)
    get("/users/:nickname/following", ActivityPubController, :following)
    get("/users/:nickname/collections/featured", ActivityPubController, :pinned)
  end

  scope "/", Pleroma.Web.ActivityPub do
    pipe_through(:activitypub)
    post("/inbox", ActivityPubController, :inbox)
    post("/users/:nickname/inbox", ActivityPubController, :inbox)
  end

  scope "/relay", Pleroma.Web.ActivityPub do
    pipe_through(:ap_service_actor)

    get("/", ActivityPubController, :relay)

    scope [] do
      pipe_through(:http_signature)
      post("/inbox", ActivityPubController, :inbox)
    end

    get("/following", ActivityPubController, :relay_following)
    get("/followers", ActivityPubController, :relay_followers)
  end

  scope "/internal/fetch", Pleroma.Web.ActivityPub do
    pipe_through(:ap_service_actor)

    get("/", ActivityPubController, :internal_fetch)
    post("/inbox", ActivityPubController, :inbox)
  end

  scope "/.well-known", Pleroma.Web do
    pipe_through(:well_known)

    get("/host-meta", WebFinger.WebFingerController, :host_meta)
    get("/webfinger", WebFinger.WebFingerController, :webfinger)
    get("/nodeinfo", Nodeinfo.NodeinfoController, :schemas)
  end

  scope "/nodeinfo", Pleroma.Web do
    get("/:version", Nodeinfo.NodeinfoController, :nodeinfo)
  end

  scope "/", Pleroma.Web do
    pipe_through(:api)

    get("/manifest.json", ManifestController, :show)
  end

  scope "/", Pleroma.Web do
    pipe_through(:pleroma_html)

    post("/auth/password", TwitterAPI.PasswordController, :request)
  end

  scope "/proxy/", Pleroma.Web do
    get("/preview/:sig/:url", MediaProxy.MediaProxyController, :preview)
    get("/preview/:sig/:url/:filename", MediaProxy.MediaProxyController, :preview)
    get("/:sig/:url", MediaProxy.MediaProxyController, :remote)
    get("/:sig/:url/:filename", MediaProxy.MediaProxyController, :remote)
  end

  if Pleroma.Config.get(:env) == :dev do
    scope "/dev" do
      pipe_through([:mailbox_preview])

      forward("/mailbox", Plug.Swoosh.MailboxPreview, base_path: "/dev/mailbox")
    end
  end

  scope "/" do
    pipe_through([:pleroma_html, :authenticate, :require_admin])
    live_dashboard("/phoenix/live_dashboard")
  end

  # Test-only routes needed to test action dispatching and plug chain execution
  if Pleroma.Config.get(:env) == :test do
    @test_actions [
      :do_oauth_check,
      :fallback_oauth_check,
      :skip_oauth_check,
      :fallback_oauth_skip_publicity_check,
      :skip_oauth_skip_publicity_check,
      :missing_oauth_check_definition
    ]

    scope "/test/api", Pleroma.Tests do
      pipe_through(:api)

      for action <- @test_actions do
        get("/#{action}", AuthTestController, action)
      end
    end

    scope "/test/authenticated_api", Pleroma.Tests do
      pipe_through(:authenticated_api)

      for action <- @test_actions do
        get("/#{action}", AuthTestController, action)
      end
    end
  end

  scope "/", Pleroma.Web.MongooseIM do
    get("/user_exists", MongooseIMController, :user_exists)
    get("/check_password", MongooseIMController, :check_password)
  end

  scope "/", Pleroma.Web.Fallback do
    get("/registration/:token", RedirectController, :registration_page)
    get("/:maybe_nickname_or_id", RedirectController, :redirector_with_meta)
    match(:*, "/api/pleroma/*path", LegacyPleromaApiRerouterPlug, [])
    get("/api/*path", RedirectController, :api_not_implemented)
    get("/*path", RedirectController, :redirector_with_preload)

    options("/*path", RedirectController, :empty)
  end

  def get_api_routes do
    Phoenix.Router.routes(__MODULE__)
    |> Enum.reject(fn r -> r.plug == Pleroma.Web.Fallback.RedirectController end)
    |> Enum.map(fn r ->
      r.path
      |> String.split("/", trim: true)
      |> List.first()
    end)
    |> Enum.uniq()
  end
end
