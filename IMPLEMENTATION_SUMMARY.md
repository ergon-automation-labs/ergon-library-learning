# Learning Bot - Phase 1 Implementation Summary

**Status**: ✅ Complete
**Date**: 2026-03-13
**Lines of Code**: 1,962 (source) + tests
**Tests**: 13 passing ✓

## Overview

The Learning Bot implements FSRS-5 (Free Spaced Repetition Scheduler) as the core engine for adaptive flashcard review scheduling. Phase 1 is a standalone system with Ecto persistence, NATS event flow, and Mix task authoring interface.

## Architecture Components

### 1. Core FSRS Algorithm (`fsrs.ex`)
- Pure functional, zero side effects
- FSRS-5 grade-based scheduling (grades 0-3: again, hard, good, easy)
- Functions: `initial_stability/1`, `next_difficulty/2`, `next_due_at/2`, `apply_review/2`
- **13 unit tests** covering all code paths

### 2. Database Schema (6 Ecto migrations)
```
Domain → Deck → Card → (Review, Session, Snooze)
```
- **Domain**: Learning domain (e.g., "greek", "spanish")
- **Deck**: Collection of cards in a domain
- **Card**: Flashcard with FSRS fields (stability, difficulty, due_at)
- **Session**: Active study session tracking
- **Review**: Historical record of card reviews
- **Snooze**: Temporarily suppress cards

### 3. GenServer Store Pattern

**CardStore** (In-memory + PostgreSQL persistence)
- `list_cards_for_deck/1` - Fetch all cards in a deck
- `list_due_cards/2` - Get cards due for review (limit)
- `create_card/2`, `update_card/2`, `delete_card/1`
- Implementation: GenServer with Ecto transaction semantics

**SessionManager** (In-memory session tracking)
- `start_session/3` - Begin study session
- `next_card/1` - Get next card (deferred to Phase 2)
- `record_answer/3` - Log review grade
- `end_session/1` - Persist session to DB
- State: `%{sessions: %{id => %{cards_reviewed, status, ...}}}`

### 4. NATS Event Flow

**Inbound Subjects** (consumed by handlers):
- `learning.session.start` → SessionHandler
- `learning.session.answer` → SessionHandler
- `learning.session.end` → SessionHandler
- `learning.card.create` → CardHandler
- `learning.deck.create` → CardHandler

**Outbound Subjects** (published events):
- `events.learning.session.card` - Card presented to user
- `events.learning.session.result` - Review result recorded
- `events.learning.session.complete` - Session finished
- `events.learning.card.due` - Card due notification (Phase 3)
- `events.learning.error` - Error events

### 5. Event Handlers

**CardHandler**
- Creates flashcards with FSRS defaults (stability=2.5, difficulty=5.0)
- Creates decks and auto-creates domains
- Validates required fields before DB insert

**SessionHandler**
- Manages session lifecycle via SessionManager
- Records answers (grades 0-3) with FSRS updates
- Publishes progress and completion events

### 6. Mix Task Interface (Phase 1 Authoring)

```bash
# Create learning domain and deck
mix learning.deck.new --name "Greek Vocabulary" --domain greek --description "..."

# Add flashcard to deck
mix learning.card.new --deck-id <UUID> \
  --front "ἀγαθός" --back "good, noble" \
  --type recall --tags "greek,vocab"

# Show statistics
mix learning.stats [--deck-id <UUID>]
```

**Features**:
- Auto-creates domains on first use
- Tag parsing (comma-separated)
- User-friendly output with UUIDs and next-step guidance
- Global and deck-specific statistics views
- FSRS average calculations

### 7. Application Configuration

**@env Pattern** (compile-time, not runtime):
```elixir
@env Mix.env()

defp maybe_add_card_store(children) do
  if @env == :test, do: children, else: [{BotArmyLearning.CardStore, []} | children]
end
```
- In `:test` → Stores not started (pure unit tests)
- In `:dev`/`:prod` → Stores started and operational

**Database Setup** (per environment):
- Dev: `ergon_learning_dev` on localhost:30003 (SSH tunnel)
- Test: `ergon_learning_test` with SQL Sandbox (parallel test isolation)

### 8. Deployment (Automatic via Git Hook)

**Pre-push Hook** (`git-hooks/pre-push`):
1. `mix deps.get` - Fetch dependencies
2. `mix compile --force` - Check compilation
3. `mix credo` - Linting (non-blocking)
4. `mix test` - Run test suite
5. `MIX_ENV=prod mix release` - Build OTP release
6. Create tarball: `learning_bot-VERSION.tar.gz`
7. `gh release create v$VERSION` - Publish to GitHub
8. `git push` - Push commit

**Jenkins Deployment** (Jenkinsfile):
1. Download release tarball from GitHub
2. Extract to `/opt/ergon/releases/learning_bot/releases/TIMESTAMP/`
3. Symlink to `current`
4. Apply Salt states: `common.core`, `common.schemas`, `bots.learning_bot`
5. `launchctl unload/load` - Restart service
6. `health_check.sh` - Verify startup
7. Publish event to `ops.builds.learning_bot` on NATS

### 9. Infrastructure Registration

**bot_army_infra Updates**:
- `jenkins_bot_config.sh` - Added `*ergon-learning*)` case
- `pillar/common.sls` - Added:
  - `bot_army_schemas_learning` to schema repos
  - Learning schema paths and permissions
  - Learning bot service configuration

### 10. Schema Repository (`bot_army_schemas_learning`)

Separate git repo with JSON Schema definitions:
- `learning.card.json` - Card with FSRS fields
- `learning.session.json` - Session state
- `learning.review.json` - Review record

All schemas extend core envelope from `bot_army_schemas`.

## Testing Strategy

**Phase 1: Pure Unit Tests**
- ✅ FSRS algorithm (13 tests, no DB needed)
- ✅ Validation logic
- ✅ Grade transitions
- ✅ Retention sensitivity

**Phase 2 Deferred: Integration Tests**
- Handler + GenServer tests (with mocked CardStore)
- NATS message routing
- Session state persistence
- Card loading and filtering

**SQL Sandbox Ready**: `config/test.exs` configured for:
- Parallel test execution
- Transaction isolation per test
- No shared state pollution

## Verification Checklist

- [x] Scaffold from template
- [x] Jenkinsfile (modeled after llm_bot)
- [x] infra registration (jenkins_bot_config.sh, pillar/common.sls)
- [x] 6 Ecto migrations (domains, decks, cards, sessions, reviews, snoozes)
- [x] 6 Ecto schemas with relationships
- [x] FSRS module (pure functional, 4 functions)
- [x] CardStore GenServer (6 public methods)
- [x] SessionManager GenServer (4 public methods)
- [x] NATS Consumer (5 subscriptions)
- [x] NATS Publisher (6 outbound events)
- [x] CardHandler (create card/deck)
- [x] SessionHandler (session lifecycle)
- [x] 3 Mix tasks (deck.new, card.new, stats)
- [x] application.ex with @env pattern
- [x] config/config.exs, runtime.exs, test.exs
- [x] Pre-push hook (compile → test → release → publish)
- [x] git-hooks executable
- [x] Release module (LearningBot.Release.migrate)
- [x] bot_army_schemas_learning (separate repo, 3 schemas)
- [x] 13 passing tests ✓
- [x] No database required for tests (pure unit tests)

## Deferred to Phase 2+

- Context Broker integration (fetch card context from other bots)
- Scheduler wake timer / tease model (notify when cards are due)
- G2 surface (web UI implementation)
- `produce` card type + LLM grading
- Anki import
- Smart Mirror integration
- Handler integration tests with mocked stores
- Performance optimization (caching, indexing)

## Next Steps

1. **Create GitHub repositories**:
   - Push `bot_army_learning` to `ergon-automation-labs/ergon-learning`
   - Push `bot_army_schemas_learning` to `ergon-automation-labs/ergon-schemas-learning`

2. **Trigger Jenkins CI/CD**:
   - Pre-push hook builds release and publishes to GitHub
   - Jenkins pulls latest release and deploys via Salt

3. **Phase 2 Planning**:
   - Handler integration tests with Mox
   - Card context fetching from GTD bot
   - Session scheduling (wake timers)

## File Structure

```
bot_army_learning/
├── config/
│   ├── config.exs          # Ecto repos config
│   ├── runtime.exs         # Environment-specific (runtime)
│   └── test.exs            # Test database setup
├── lib/
│   ├── bot_army_learning.ex
│   ├── bot_army_learning/
│   │   ├── application.ex  # @env pattern
│   │   ├── repo.ex
│   │   ├── fsrs.ex         # Pure FSRS-5 algorithm
│   │   ├── card_store.ex
│   │   ├── card_store_behaviour.ex
│   │   ├── session_manager.ex
│   │   ├── handlers/
│   │   │   ├── card_handler.ex
│   │   │   └── session_handler.ex
│   │   ├── nats/
│   │   │   ├── consumer.ex
│   │   │   └── publisher.ex
│   │   └── schemas/
│   │       ├── domain.ex
│   │       ├── deck.ex
│   │       ├── card.ex
│   │       ├── review.ex
│   │       ├── session.ex
│   │       └── snooze.ex
│   ├── learning_bot/
│   │   └── release.ex      # Migration runner
│   └── mix/tasks/
│       ├── learning.deck.new.ex
│       ├── learning.card.new.ex
│       └── learning.stats.ex
├── priv/repo/migrations/
│   ├── 20260313000001_create_learning_domains.exs
│   ├── 20260313000002_create_learning_decks.exs
│   ├── 20260313000003_create_learning_cards.exs
│   ├── 20260313000004_create_learning_sessions.exs
│   ├── 20260313000005_create_learning_reviews.exs
│   └── 20260313000006_create_learning_snoozes.exs
├── test/
│   ├── test_helper.exs
│   └── bot_army_learning/
│       └── fsrs_test.exs   # 13 passing tests
├── .gitignore
├── git-hooks/
│   └── pre-push            # Automated release pipeline
├── mix.exs
├── Makefile
├── Jenkinsfile             # Deploy via Jenkins/Salt
└── README.md

bot_army_schemas_learning/
├── schemas/
│   ├── learning.card.json
│   ├── learning.session.json
│   └── learning.review.json
├── Makefile
├── package.json
└── README.md
```

---

**Implementation Date**: 2026-03-13
**Framework**: Elixir/Phoenix Ecto, NATS, GenServer
**Algorithm**: FSRS-5 Spaced Repetition
**Ready for**: Jenkins/Salt deployment via GitHub releases
