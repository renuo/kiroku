# frozen_string_literal: true

admin = User.find_or_create_by!(google_uid: "admin_seed_uid") do |user|
  user.email = "admin@example.com"
  user.name = "Admin User"
  user.admin = true
end

regular = User.find_or_create_by!(google_uid: "regular_seed_uid") do |user|
  user.email = "user@example.com"
  user.name = "Regular User"
end

Rails.logger.info "Seeded admin: #{admin.email} (admin: #{admin.admin?})"
Rails.logger.info "Seeded user: #{regular.email}"
