# Diary Feature Audit

## Current Files Involved

- Screen and flow: [lib/screens/diary/diary_screen.dart](D:/dev/alpha/rutio_app/lib/screens/diary/diary_screen.dart)
- List and card UI: [lib/screens/diary/widgets/diary_screen_body.dart](D:/dev/alpha/rutio_app/lib/screens/diary/widgets/diary_screen_body.dart), [lib/screens/diary/widgets/diary_screen_header.dart](D:/dev/alpha/rutio_app/lib/screens/diary/widgets/diary_screen_header.dart), [lib/screens/diary/widgets/diary_entry_card.dart](D:/dev/alpha/rutio_app/lib/screens/diary/widgets/diary_entry_card.dart)
- Grouping and filtering: [lib/screens/diary/helpers/diary_screen_view_data.dart](D:/dev/alpha/rutio_app/lib/screens/diary/helpers/diary_screen_view_data.dart), [lib/screens/diary/sections/diary_summary_section.dart](D:/dev/alpha/rutio_app/lib/screens/diary/sections/diary_summary_section.dart), [lib/screens/diary/sections/diary_entries_section.dart](D:/dev/alpha/rutio_app/lib/screens/diary/sections/diary_entries_section.dart)
- Composer and detail flows: [lib/screens/diary/sheets/diary_entry_composer_sheet.dart](D:/dev/alpha/rutio_app/lib/screens/diary/sheets/diary_entry_composer_sheet.dart), [lib/screens/diary/screens/diary_entry_detail_screen.dart](D:/dev/alpha/rutio_app/lib/screens/diary/screens/diary_entry_detail_screen.dart)
- Local model and persistence: [lib/models/diary_entry.dart](D:/dev/alpha/rutio_app/lib/models/diary_entry.dart), [lib/stores/user_state_store_diary.dart](D:/dev/alpha/rutio_app/lib/stores/user_state_store_diary.dart), [lib/stores/user_state_store_core.dart](D:/dev/alpha/rutio_app/lib/stores/user_state_store_core.dart)
- Remote sync: [lib/data/repositories/journal_entry_repository.dart](D:/dev/alpha/rutio_app/lib/data/repositories/journal_entry_repository.dart), [lib/data/services/journal_entry_sync_service.dart](D:/dev/alpha/rutio_app/lib/data/services/journal_entry_sync_service.dart), [lib/data/models/remote/remote_journal_entry.dart](D:/dev/alpha/rutio_app/lib/data/models/remote/remote_journal_entry.dart), [lib/data/mappers/journal_entry_remote_mapper.dart](D:/dev/alpha/rutio_app/lib/data/mappers/journal_entry_remote_mapper.dart)
- Shared entry trigger: [lib/screens/diary/helpers/diary_screen_actions.dart](D:/dev/alpha/rutio_app/lib/screens/diary/helpers/diary_screen_actions.dart)
- Demo seed: [lib/devtools/demo_seed/demo_seed_data.dart](D:/dev/alpha/rutio_app/lib/devtools/demo_seed/demo_seed_data.dart), [lib/devtools/demo_seed/demo_seed_history.dart](D:/dev/alpha/rutio_app/lib/devtools/demo_seed/demo_seed_history.dart), [lib/devtools/demo_seed/demo_seed_runner.dart](D:/dev/alpha/rutio_app/lib/devtools/demo_seed/demo_seed_runner.dart)
- Navigation coupling: [lib/screens/home/home_screen.dart](D:/dev/alpha/rutio_app/lib/screens/home/home_screen.dart), [lib/screens/home/logic/home_navigation.dart](D:/dev/alpha/rutio_app/lib/screens/home/logic/home_navigation.dart), [lib/screens/habit_monthly/habit_monthly_screen.dart](D:/dev/alpha/rutio_app/lib/screens/habit_monthly/habit_monthly_screen.dart), [lib/widgets/app_view_drawer.dart](D:/dev/alpha/rutio_app/lib/widgets/app_view_drawer.dart)

## Current Data Model Summary

### Local model

- `DiaryEntry` currently persists:
  - `id`
  - `createdAt` as epoch milliseconds
  - `text`
  - optional `remoteId`
  - optional `habitId`
  - optional `familyId`
  - optional `mood`
  - `isPinned`
- There is no first-class local field for:
  - separate `date`
  - separate `title`
  - `tags`
  - `attachments`
  - `prompt`
  - `favorite/saved` beyond the `isPinned` flag

### UI view model

- `DiaryEntryUi` adds:
  - normalized `createdAt`
  - `type` (`habit` or `personal`)
  - resolved `habitName`, `familyName`, `familyColor`
  - `timeLabel`
- It still does not add tags, attachments, prompt, or a distinct title/body split.

### Composer draft

- The composer sheet has a richer draft shape than the local model:
  - `type`
  - `text`
  - optional `mood`
  - optional `habitId`, `habitName`, `familyName`, `familyColor`
- The UI exposes title and reflection inputs, but they are collapsed into one stored `text` field when saved.

## Current Persistence Summary

- Diary entries are stored inside local user state under `userState.diaryEntries`.
- `user_state_store_diary.dart` is the source of truth for add, update, delete, local reward application, and remote sync triggers.
- A diary save:
  - creates or updates a local `DiaryEntry`
  - persists it via `UserStateRepository`
  - awards daily diary XP/coins when the entry is non-empty
  - attempts Supabase sync through `JournalEntrySyncService`
- Remote persistence uses `journal_entries` with fields such as:
  - `entry_date`
  - `title`
  - `content`
  - `mood`
  - `emoji`
  - `habit_id`
  - `local_habit_id`
  - `family_id`
  - `source`
  - `is_deleted`
- Important mismatch:
  - the remote table supports `title`, but the current local model and save flow do not persist a dedicated title field
  - the save flow also does not persist tags, attachments, or prompt data

## What Supports Each Requested Capability Today

- Date: yes, via `createdAt`
- Title: partially, only as composer input; not a first-class stored field locally
- Body/content: yes, via `text`
- Mood: yes
- Tags: no
- Favorite/saved state: partially, via `isPinned`, but the current flow/UI does not really use it
- Attachments/photo/voice: no
- Prompt: no

## How Entries Are Created, Edited, Saved, and Displayed

- Create/edit starts from `DiaryScreenFab` and from the detail screen actions.
- `showDiaryEntryComposerBottomSheet` builds a `DiaryEntry` from the draft and calls `addDiaryEntry` or `updateDiaryEntry`.
- `DiaryEntryComposerSheet` supports personal and habit-linked entries, mood, title, reflection, and habit selection.
- `DiaryScreen` routes:
  - open composer
  - open detail view
  - edit/delete from detail or swipe
- Display is currently list-first:
  - top header with menu, search, and filters
  - period chips
  - summary card
  - grouped entry list by day
  - floating add button
- The current detail screen is rich, but it is not the new mockup layout.

## Empty States

- The main entries list has no dedicated empty state; when there are no entries, the section returns `SizedBox.shrink()`.
- `DailySummaryCard` has an empty message state, but it is not the primary screen empty-state treatment.
- `DiaryFiltersSheet` is mostly placeholder UI and does not materially change results yet.

## Coupling Notes

- `DiaryScreen` is reachable from:
  - Home
  - Monthly screen
  - global drawer
- Habit coupling exists through:
  - `showAfterHabitCompleteNotePrompt`
  - habit-linked composer mode
  - habit metadata resolution in list and detail views
- Statistics coupling is indirect:
  - Diary uses the shared `UserStateStore`
  - the store and sync services are shared with the rest of the app
  - diary rewards touch global XP/coins state
- The current screen is not tightly coupled to Home layout, but it is coupled to the shared store and habit identity resolution.

## What Can Be Reused

- Shared entry persistence and sync pipeline
- `DiaryEntryComposerSheet` mood picker and text editing patterns
- Habit picker and habit-linked note flow
- Entry detail presentation patterns for date, mood, family metadata, and actions
- `AppViewDrawer` navigation shell
- Local diary reward behavior if the app still wants journaling to contribute to progression

## What Should Be Refactored

- Split the entry data shape so the UI can handle:
  - date
  - title
  - body
  - mood
  - tags
  - favorite state
  - attachments
  - prompt
- Separate the new mockup-focused Diary screen from the current list/detail composition.
- Replace the current period/filter chips with the mockup's weekly strip and content blocks.
- Make the composer sheet a real diary editor surface instead of a habit-first note composer.
- Decide whether `isPinned` becomes the real saved/favorite concept or if a new field is needed.

## Risks

- The local model currently loses structure because title and reflection are collapsed into one `text` blob.
- The remote schema already expects richer content than the current local save path provides.
- Habit-linked diary behavior is deeply embedded in the composer and detail resolution.
- Any redesign that assumes tags/attachments/prompt are already stored will need a data migration or backward-compatible mapping.
- Daily diary rewards are a cross-cutting side effect, so changes to save semantics can affect progression.

## Recommended Implementation Phases

### Phase 1: UI Refresh Only

- Rebuild the main Diary screen to match the mockup using existing data.
- Keep current storage and save behavior intact.
- Reuse existing mood and habit metadata where possible.
- Add only presentation-layer adapters for the new layout.

### Phase 2: Entry Structure

- Introduce explicit fields for title, body, tags, favorite, attachments, and prompt.
- Preserve backward compatibility with existing `text` entries.
- Update composer and detail screens to read/write the expanded shape.

### Phase 3: Interaction and Enrichment

- Add prompt cards, attachment actions, and richer favorites/save behavior.
- Revisit reward logic and habit-linked flows once the data model is stable.

## Suggested Files for Phase 1 UI Refresh

- [lib/screens/diary/diary_screen.dart](D:/dev/alpha/rutio_app/lib/screens/diary/diary_screen.dart)
- [lib/screens/diary/widgets/diary_screen_body.dart](D:/dev/alpha/rutio_app/lib/screens/diary/widgets/diary_screen_body.dart)
- [lib/screens/diary/widgets/diary_screen_header.dart](D:/dev/alpha/rutio_app/lib/screens/diary/widgets/diary_screen_header.dart)
- [lib/screens/diary/widgets/diary_screen_fab.dart](D:/dev/alpha/rutio_app/lib/screens/diary/widgets/diary_screen_fab.dart)
- [lib/screens/diary/widgets/diary_header.dart](D:/dev/alpha/rutio_app/lib/screens/diary/widgets/diary_header.dart)
- [lib/screens/diary/widgets/daily_summary_card.dart](D:/dev/alpha/rutio_app/lib/screens/diary/widgets/daily_summary_card.dart)
- [lib/screens/diary/widgets/weekly_emotional_streak_card.dart](D:/dev/alpha/rutio_app/lib/screens/diary/widgets/weekly_emotional_streak_card.dart)
- [lib/screens/diary/sections/diary_summary_section.dart](D:/dev/alpha/rutio_app/lib/screens/diary/sections/diary_summary_section.dart)
- [lib/screens/diary/sections/diary_entries_section.dart](D:/dev/alpha/rutio_app/lib/screens/diary/sections/diary_entries_section.dart)
- [lib/screens/diary/widgets/diary_entry_card.dart](D:/dev/alpha/rutio_app/lib/screens/diary/widgets/diary_entry_card.dart)

## Short Takeaway

- The current Diary feature is a local-store-backed journaling list with a rich habit-linked composer, mood support, and remote sync, but it does not yet model the new mockup's title/body/tags/attachments/prompt structure.
- The safest next step is a presentation-only refresh on top of the existing persistence path, then a separate data-model refactor.
