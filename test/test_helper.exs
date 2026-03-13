ExUnit.start()

# Start the application for tests
{:ok, _} = Application.ensure_all_started(:bot_army_learning)

# Define mocks for behaviors
Mox.defmock(BotArmyLearning.CardStoreMock, for: BotArmyLearning.CardStoreBehaviour)
