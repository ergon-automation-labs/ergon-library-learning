ExUnit.start()

# Start the application for tests
# Note: CardStore and SessionManager are NOT started in test mode (@env == :test in application.ex)
# This allows pure unit tests without database dependencies
{:ok, _} = Application.ensure_all_started(:bot_army_learning)
