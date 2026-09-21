class RenameHackatimeExtensionTextTypeOnUsers < ActiveRecord::Migration[8.1]
  def change
    rename_column :users, :hackatime_extension_text_type, :deltatime_extension_text_type
  end
end
