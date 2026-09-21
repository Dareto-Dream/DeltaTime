class ReplaceHcaSlackAuthWithGoogleAndPassword < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :google_uid, :string
    add_column :users, :google_access_token, :text
    add_column :users, :google_avatar_url, :string
    add_column :users, :google_name, :string
    add_column :users, :password_digest, :string

    add_index :users, :google_uid
    add_index :users, [ :google_uid, :google_access_token ], name: "index_users_on_google_uid_and_access_token"

    remove_column :users, :hca_access_token, :string
    remove_column :users, :hca_id, :string
    remove_column :users, :hca_scopes, :string, array: true, default: []
    remove_column :users, :slack_access_token, :text
    remove_column :users, :slack_avatar_url, :string
    remove_column :users, :slack_scopes, :string, array: true, default: []
    remove_column :users, :slack_synced_at, :datetime
    remove_column :users, :slack_uid, :string
    remove_column :users, :slack_username, :string
    remove_column :users, :uses_slack_status, :boolean, default: false, null: false

    remove_column :oauth_applications, :redirect_to_hca_login, :boolean, default: false, null: false

    drop_table :sailors_log_leaderboards, force: :cascade do |t|
      t.datetime "created_at", null: false
      t.datetime "deleted_at"
      t.text "message"
      t.string "slack_channel_id"
      t.string "slack_uid"
      t.datetime "updated_at", null: false
    end

    drop_table :sailors_log_notification_preferences, force: :cascade do |t|
      t.datetime "created_at", null: false
      t.boolean "enabled", default: true, null: false
      t.string "slack_channel_id", null: false
      t.string "slack_uid", null: false
      t.datetime "updated_at", null: false
    end

    drop_table :sailors_log_slack_notifications, force: :cascade do |t|
      t.datetime "created_at", null: false
      t.integer "project_duration", null: false
      t.string "project_name", null: false
      t.boolean "sent", default: false, null: false
      t.string "slack_channel_id", null: false
      t.string "slack_uid", null: false
      t.datetime "updated_at", null: false
    end

    drop_table :sailors_logs, force: :cascade do |t|
      t.datetime "created_at", null: false
      t.jsonb "projects_summary", default: {}, null: false
      t.string "slack_uid", null: false
      t.datetime "updated_at", null: false
    end

    drop_table :email_verification_requests, force: :cascade do |t|
      t.datetime "created_at", null: false
      t.datetime "deleted_at"
      t.string "email"
      t.datetime "expires_at"
      t.string "token"
      t.datetime "updated_at", null: false
      t.bigint "user_id", null: false
    end

    drop_table :sign_in_tokens, force: :cascade do |t|
      t.integer "auth_type"
      t.string "continue_param"
      t.datetime "created_at", null: false
      t.datetime "expires_at"
      t.jsonb "return_data"
      t.string "token"
      t.datetime "updated_at", null: false
      t.datetime "used_at"
      t.bigint "user_id", null: false
      t.index [ "token" ], name: "index_sign_in_tokens_on_token"
      t.index [ "user_id" ], name: "index_sign_in_tokens_on_user_id"
    end
  end
end
