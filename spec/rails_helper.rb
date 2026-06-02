# This file is copied to spec/ when you run 'rails generate rspec:install'

# Measure test coverage. Must start before any app code is loaded.
require "simplecov"
SimpleCov.start "rails" do
  add_filter "/spec/"
  enable_coverage :branch

  # Turn on the hard gate once real domain code lands (step 3 onward).
  # Every change ships with its test, so this should stay green.
  # minimum_coverage line: 90, branch: 80
end

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
# Uncomment the line below in case you have `--require rails_helper` in the `.rspec` file
# that will avoid rails generators crashing because migrations haven't been run yet
# return unless Rails.env.test?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# Ensures that the test database schema matches the current schema file.
# If there are pending migrations it will invoke `db:test:prepare` to
# recreate the test database by loading the schema.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # DatabaseCleaner handles cleanup instead, so we can truncate (not just roll
  # back a transaction) for threaded specs that need committed, cross-connection data.
  config.use_transactional_fixtures = false

  config.before(:suite) { DatabaseCleaner.clean_with(:truncation) }

  # Pick the strategy first...
  config.before(:each) { DatabaseCleaner.strategy = :transaction }
  # Tag an example with `:no_transaction` to truncate instead (e.g. thread races)
  config.before(:each, :no_transaction) { DatabaseCleaner.strategy = :truncation }
  # ...then start, so `start` reads the strategy chosen above
  config.before(:each) { DatabaseCleaner.start }
  config.append_after(:each) { DatabaseCleaner.clean }

  # Don't leak the current tenant between examples
  config.before(:each) { ActsAsTenant.current_tenant = nil }

  # Run Bullet around request specs so an N+1 fails the test
  if defined?(Bullet) && Bullet.enable?
    config.before(:each, type: :request) { Bullet.start_request }
    config.after(:each, type: :request) do
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    end
  end

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails uses metadata to mix in different behaviours to your tests,
  # for example enabling you to call `get` and `post` in request specs. e.g.:
  #
  #     RSpec.describe UsersController, type: :request do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/8-0/rspec-rails
  #
  # You can also infer these behaviours automatically by location, e.g.
  # /spec/models would pull in the same behaviour as `type: :model` but this
  # behaviour is considered legacy and will be removed in a future version.
  #
  # To enable this behaviour uncomment the line below.
  # config.infer_spec_type_from_file_location!

  # Use `build`/`create` directly instead of `FactoryBot.build`
  config.include FactoryBot::Syntax::Methods

  # Let request specs call `sign_in` / `sign_out`
  config.include Devise::Test::IntegrationHelpers, type: :request

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end
