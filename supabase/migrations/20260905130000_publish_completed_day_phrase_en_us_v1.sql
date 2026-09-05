-- GENERATED FILE. Do not edit manually.
-- Source: supabase/catalog/completed_day_phrase/en-US.v1.json
-- Regenerate: dart run tool/completed_day_phrase/generate_release_sql.dart supabase/catalog/completed_day_phrase/en-US.v1.json
-- This file never calls Supabase remotely; apply it only after the migrations.

begin;

-- A published v1 is immutable. Re-running fails as a controlled no-op.
do $$
declare
  v_status text;
  v_entry_count integer;
begin
  select status into v_status
  from public.phrase_catalog_releases
  where locale = 'en-US' and release_version = 1;
  if v_status = 'published' then
    select count(*) into v_entry_count
    from public.phrase_catalog_release_entries e
    join public.phrase_catalog_releases r on r.id = e.release_id
    where r.locale = 'en-US' and r.release_version = 1;
    if v_entry_count = 300 then
      raise exception 'completed_day_phrase en-US v1 is already published; seed aborted as a controlled no-op check';
    end if;
    raise exception 'completed_day_phrase en-US v1 is published but incomplete; refusing to mutate it';
  end if;
end;
$$;

-- Expected locale-specific release payload.
create temporary table _completed_day_phrase_expected (
  id text primary key,
  category text not null,
  tone text not null,
  source_type text not null,
  author text,
  required_tokens text[] not null,
  weight numeric not null,
  enabled boolean not null,
  template text not null,
  content_version integer not null
) on commit drop;

insert into _completed_day_phrase_expected (
  id, category, tone, source_type, author, required_tokens,
  weight, enabled, template, content_version
) values
  ('personal_001', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, '{name}, today you proved you can count on yourself.', 1),
  ('personal_002', 'personal', 'balanced', 'original', null, array['name', 'progress']::text[], 100, true, '{name}, you reached {progress}. Take a moment to enjoy it.', 1),
  ('personal_003', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'Well done, {name}. Today you stood by yourself too.', 1),
  ('personal_004', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, what you did today is also building your tomorrow.', 1),
  ('personal_005', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'Today you added another day to be proud of, {name}.', 1),
  ('personal_006', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, your effort today deserves a moment of calm.', 1),
  ('personal_007', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, 'You made it here by showing up for yourself, {name}. Let that sink in.', 1),
  ('personal_008', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, '{name}, you did not need to do it perfectly today; you just needed to make it yours.', 1),
  ('personal_009', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'This day carries your mark too, {name}.', 1),
  ('personal_010', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, hold on to this feeling: you can keep moving forward.', 1),
  ('personal_011', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'Today you chose yourself, {name}. That counts too.', 1),
  ('personal_012', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, your progress reflects everything you are taking care of.', 1),
  ('personal_013', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'You did it in your own way, {name}, and that means a lot.', 1),
  ('personal_014', 'personal', 'energetic', 'original', null, array['name']::text[], 100, true, '{name}, today you turned intention into action.', 1),
  ('personal_015', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'Another day complete, {name}. Quietly done, deeply meaningful.', 1),
  ('personal_016', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, your best pace is the one you can sustain.', 1),
  ('personal_017', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'Today you gave yourself more reasons to trust yourself, {name}.', 1),
  ('personal_018', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, '{name}, enjoy the quiet pride of keeping your word to yourself.', 1),
  ('personal_019', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, 'What you did today may look small, {name}, but it is building something meaningful.', 1),
  ('personal_020', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, you reached the end of the day without leaving yourself behind.', 1),
  ('personal_021', 'personal', 'balanced', 'original', null, array['streak_label', 'name']::text[], 100, true, 'Your {streak_label} streak tells a story of consistency, {name}.', 1),
  ('personal_022', 'personal', 'gentle', 'original', null, array['streak_label', 'name']::text[], 100, true, 'Your {streak_label} journey says more than any promise could, {name}.', 1),
  ('personal_023', 'personal', 'gentle', 'original', null, array['streak_label', 'name']::text[], 100, true, 'You have been choosing to continue for {streak_label}, {name}.', 1),
  ('personal_024', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, every day in your streak confirms that you can choose yourself again.', 1),
  ('personal_025', 'personal', 'gentle', 'original', null, array['streak_label', 'name']::text[], 100, true, 'Your {streak_label} streak does not ask for perfection, only presence, {name}.', 1),
  ('personal_026', 'personal', 'balanced', 'original', null, array['name', 'streak_label']::text[], 100, true, '{name}, {streak_label} are already shaping a more consistent version of you.', 1),
  ('personal_027', 'personal', 'balanced', 'original', null, array['streak_label', 'name']::text[], 100, true, 'Behind these {streak_label} are choices only you know about, {name}.', 1),
  ('personal_028', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, '{name}, your streak grows because you keep showing up.', 1),
  ('personal_029', 'personal', 'gentle', 'original', null, array['streak_label', 'name']::text[], 100, true, 'After {streak_label}, you are still here. Well done, {name}.', 1),
  ('personal_030', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, '{name}, let your streak remind you of your capacity, not pressure you.', 1),
  ('personal_031', 'personal', 'balanced', 'original', null, array['progress', 'name']::text[], 100, true, 'Today your progress reached {progress}, {name}. Breathe and celebrate it.', 1),
  ('personal_032', 'personal', 'gentle', 'original', null, array['name', 'progress']::text[], 100, true, '{name}, {progress} is not just a number: it is what you chose to care for today.', 1),
  ('personal_033', 'personal', 'energetic', 'original', null, array['progress', 'name']::text[], 100, true, 'You reached {progress}, {name}. Now it is time to rest too.', 1),
  ('personal_034', 'personal', 'balanced', 'original', null, array['name', 'progress']::text[], 100, true, '{name}, today’s {progress} has your effort behind it.', 1),
  ('personal_035', 'personal', 'gentle', 'original', null, array['progress', 'name']::text[], 100, true, 'Your day is at {progress}, {name}; your worth was never tied to the number.', 1),
  ('personal_036', 'personal', 'balanced', 'original', null, array['name', 'progress']::text[], 100, true, '{name}, reaching {progress} shows what you can do one step at a time.', 1),
  ('personal_037', 'personal', 'gentle', 'original', null, array['progress', 'name']::text[], 100, true, '{name}, today you closed the loop at {progress}.', 1),
  ('personal_038', 'personal', 'gentle', 'original', null, array['name', 'progress']::text[], 100, true, '{name}, you carried your intention through to {progress}.', 1),
  ('personal_039', 'personal', 'energetic', 'original', null, array['progress', 'name']::text[], 100, true, 'Today’s {progress} is a small victory that deserves room, {name}.', 1),
  ('personal_040', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, today you completed what you planned and kept your own pace.', 1),
  ('personal_041', 'personal', 'balanced', 'original', null, array['name', 'streak_label', 'progress']::text[], 100, true, '{name}, {streak_label} of consistency and a day at {progress}. Well done.', 1),
  ('personal_042', 'personal', 'balanced', 'original', null, array['progress', 'streak_label', 'name']::text[], 100, true, 'Your progress is at {progress} and your streak is {streak_label}, {name}. Keep going at your own pace.', 1),
  ('personal_043', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, today your consistency and progress moved together.', 1),
  ('personal_044', 'personal', 'balanced', 'original', null, array['streak_label', 'progress', 'name']::text[], 100, true, '{streak_label} of building something that is yours. Today, you also reached {progress}, {name}.', 1),
  ('personal_045', 'personal', 'gentle', 'original', null, array['name', 'progress', 'streak_label']::text[], 100, true, '{name}, today’s {progress} adds to a {streak_label} streak.', 1),
  ('personal_046', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'Today you completed your day without losing yourself, {name}.', 1),
  ('personal_047', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, your progress shows; the effort behind it matters too.', 1),
  ('personal_048', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'You have done your part for today, {name}. You can let the day go gently.', 1),
  ('personal_049', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, keep building from care, not pressure.', 1),
  ('personal_050', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, 'Today you kept your word to yourself, {name}. Tomorrow will be a new choice.', 1),
  ('consistency_001', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Consistency is quiet, but it leaves a mark.', 1),
  ('consistency_002', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Every time you return, you strengthen the path.', 1),
  ('consistency_003', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'What is sustainable is always worth more than what is perfect.', 1),
  ('consistency_004', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'One well-cared-for day can change the direction of a week.', 1),
  ('consistency_005', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'Showing up again is also a form of courage.', 1),
  ('consistency_006', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Repetition turns what is difficult into something familiar.', 1),
  ('consistency_007', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Your pace does not need to look like anyone else’s.', 1),
  ('consistency_008', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Continuity is built through small decisions.', 1),
  ('consistency_009', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'Do not underestimate the power of keeping your word to yourself once more.', 1),
  ('consistency_010', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Self-trust grows from the promises you actually keep.', 1),
  ('consistency_011', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Each repeated step opens a clearer path.', 1),
  ('consistency_012', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Consistency grows better without punishment.', 1),
  ('consistency_013', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Returning matters just as much as never stopping.', 1),
  ('consistency_014', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'What you repeat with care eventually becomes part of you.', 1),
  ('consistency_015', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Gentle discipline can transform you too.', 1),
  ('consistency_016', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'You do not need intensity every day; you need a direction.', 1),
  ('consistency_017', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Big improvements often arrive dressed as routine.', 1),
  ('consistency_018', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Today you strengthened something that will feel more natural tomorrow.', 1),
  ('consistency_019', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'A small step is still movement.', 1),
  ('consistency_020', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Patience gives progress room to take root.', 1),
  ('consistency_021', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Keeping your direction matters more than moving fast.', 1),
  ('consistency_022', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Consistency is choosing again, even when the feeling is not there.', 1),
  ('consistency_023', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Each repetition narrows the gap between intention and identity.', 1),
  ('consistency_024', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Not every kind of progress is visible right away.', 1),
  ('consistency_025', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Results take time; identity is practiced starting today.', 1),
  ('consistency_026', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Your daily system can take you where motivation cannot.', 1),
  ('consistency_027', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'What needs attention today may feel natural tomorrow.', 1),
  ('consistency_028', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Moving slowly can also protect what you are building.', 1),
  ('consistency_029', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'Regularity gives strength to ordinary days.', 1),
  ('consistency_030', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'A good direction can make up for many slow steps.', 1),
  ('consistency_031', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Consistency is easier to recognize when you look back.', 1),
  ('consistency_032', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Repeating with intention is one way of learning who you are.', 1),
  ('consistency_033', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Every day does not have to be extraordinary to be valuable.', 1),
  ('consistency_034', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'The point is not to make it huge, but to make it possible.', 1),
  ('consistency_035', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Your progress lives in what you choose to repeat.', 1),
  ('consistency_036', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Stability is built before it is felt.', 1),
  ('consistency_037', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Small acts of follow-through train big trust.', 1),
  ('consistency_038', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Lasting improvement rarely needs to be rushed.', 1),
  ('consistency_039', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'A good habit is a support, not a debt.', 1),
  ('consistency_040', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Consistency also means knowing when to adapt your pace.', 1),
  ('consistency_041', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Doing less and sustaining it can take you farther.', 1),
  ('consistency_042', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'The path becomes more yours each time you walk it.', 1),
  ('consistency_043', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Consistency does not require identical days.', 1),
  ('consistency_044', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Continuing does not always mean pushing harder.', 1),
  ('consistency_045', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'Caring for your frequency is also caring for your energy.', 1),
  ('consistency_046', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'Conscious repetition turns actions into foundations.', 1),
  ('consistency_047', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Your progress accumulates even when you cannot see it today.', 1),
  ('consistency_048', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'What you sustain calmly gains depth.', 1),
  ('consistency_049', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Discipline works best when it fits into your life.', 1),
  ('consistency_050', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'One repeated decision can change a story.', 1),
  ('consistency_051', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Simple days build results too.', 1),
  ('consistency_052', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Today you fed the version of yourself you want to keep.', 1),
  ('consistency_053', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Consistency transforms without asking for the spotlight.', 1),
  ('consistency_054', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Real progress often looks ordinary while it is happening.', 1),
  ('consistency_055', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Every return keeps a stumble from becoming an abandonment.', 1),
  ('consistency_056', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'Your strength also lies in knowing how to continue gently.', 1),
  ('consistency_057', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Habits grow when they find room, not pressure.', 1),
  ('consistency_058', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'What you do often matters more than what you do once in a while.', 1),
  ('consistency_059', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Repetition gives stability to your good intentions.', 1),
  ('consistency_060', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'A strong chain is formed one link at a time.', 1),
  ('consistency_061', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'You do not need to make up the time; just return to your direction.', 1),
  ('consistency_062', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Consistency allows pauses, while remembering the way forward.', 1),
  ('consistency_063', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Progress is better protected by human expectations.', 1),
  ('consistency_064', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Every day you sustain makes it easier to trust the next one.', 1),
  ('consistency_065', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'A small action can be a powerful signal to yourself.', 1),
  ('consistency_066', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'A habit takes root when it stops being a daily battle.', 1),
  ('consistency_067', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Regularity turns effort into structure.', 1),
  ('consistency_068', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Moving forward without exhausting yourself is still moving forward well.', 1),
  ('consistency_069', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Patience is part of the practice.', 1),
  ('consistency_070', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Continuity is not broken by one difficult day.', 1),
  ('consistency_071', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Your system should support you when motivation dips too.', 1),
  ('consistency_072', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'A calm foundation can hold deep change.', 1),
  ('consistency_073', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'The most useful commitment is the one you can renew tomorrow.', 1),
  ('consistency_074', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Every day adds context, experience, and trust.', 1),
  ('consistency_075', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Consistency is not trying to impress; it is trying to remain.', 1),
  ('consistency_076', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Your steady pace can outlast many brief bursts.', 1),
  ('consistency_077', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Today you made it easier to do this again.', 1),
  ('consistency_078', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'What you repeat with meaning eventually shapes your identity.', 1),
  ('consistency_079', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Maintaining a practice also means learning how to care for it.', 1),
  ('consistency_080', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Small acts of follow-through shorten the distance to your goals.', 1),
  ('consistency_081', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Being consistent does not mean being inflexible.', 1),
  ('consistency_082', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'A healthy routine adapts without losing its intention.', 1),
  ('consistency_083', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Continuity is measured in months, not isolated moments.', 1),
  ('consistency_084', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'What you sustain eventually sustains you.', 1),
  ('consistency_085', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Daily practice sharpens even what you cannot measure.', 1),
  ('consistency_086', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'Each aligned decision strengthens the next one.', 1),
  ('consistency_087', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'A complete day does not define everything, but it adds a piece.', 1),
  ('consistency_088', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Consistency turns desire into evidence.', 1),
  ('consistency_089', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'What you choose to repeat today can make the future easier.', 1),
  ('consistency_090', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Discipline does not have to hurt to work.', 1),
  ('consistency_091', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Your progress needs room to be slow.', 1),
  ('consistency_092', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'The best chain is the one that does not chain you.', 1),
  ('consistency_093', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Continuity is born from starting again as many times as needed.', 1),
  ('consistency_094', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Imperfect days can still keep a direction.', 1),
  ('consistency_095', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Kind repetition is an investment in your well-being.', 1),
  ('consistency_096', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'Each aligned action is a vote for the person you want to be.', 1),
  ('consistency_097', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Do not measure only speed; notice how much you have sustained.', 1),
  ('consistency_098', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Consistency grows when the plan respects your reality.', 1),
  ('consistency_099', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Staying present is worth more than demanding flawlessness.', 1),
  ('consistency_100', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'What is built little by little tends to hold up better.', 1),
  ('motivation_001', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Today can also be a good place to begin.', 1),
  ('motivation_002', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'What comes next is not written yet; you can still influence it.', 1),
  ('motivation_003', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Your energy deserves a direction that is good for you.', 1),
  ('motivation_004', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'There are more possibilities ahead of you than you can see right now.', 1),
  ('motivation_005', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Trust the part of you that decided to try.', 1),
  ('motivation_006', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'You do not need everything figured out to take the next step.', 1),
  ('motivation_007', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Make room to notice what you are accomplishing.', 1),
  ('motivation_008', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Your effort counts even when no one sees it.', 1),
  ('motivation_009', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Today you can be proud without having to prove anything.', 1),
  ('motivation_010', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'What you do for yourself also changes your surroundings.', 1),
  ('motivation_011', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Let yourself move forward without asking doubt for permission.', 1),
  ('motivation_012', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Your story still has many open pages.', 1),
  ('motivation_013', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'The next step does not have to be big; it only has to be honest.', 1),
  ('motivation_014', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'You have the right to grow at your own pace.', 1),
  ('motivation_015', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Resting after moving forward is part of the path too.', 1),
  ('motivation_016', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Your capacity does not disappear on difficult days.', 1),
  ('motivation_017', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Sometimes victory is ending the day at peace with yourself.', 1),
  ('motivation_018', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Do not forget to notice how much you have already changed.', 1),
  ('motivation_019', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'The version of yourself you are seeking is moving closer too.', 1),
  ('motivation_020', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'You can feel afraid and keep moving forward.', 1),
  ('motivation_021', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Your best moment does not have to be behind you.', 1),
  ('motivation_022', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Give hope one concrete action today.', 1),
  ('motivation_023', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'You are more than any difficult day.', 1),
  ('motivation_024', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Your future will thank you for the care you give yourself today.', 1),
  ('motivation_025', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'You do not need a perfect sign to continue.', 1),
  ('motivation_026', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'The way you try also deserves respect.', 1),
  ('motivation_027', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'There is strength in choosing yourself even when it is hard.', 1),
  ('motivation_028', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Do not minimize the value of making it this far.', 1),
  ('motivation_029', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'You can change direction without having lost your way.', 1),
  ('motivation_030', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Today can leave something good with you too.', 1),
  ('motivation_031', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Your inner voice can learn to care for you too.', 1),
  ('motivation_032', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'What is possible begins when you make room to try.', 1),
  ('motivation_033', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'You do not need to run to get closer to what matters.', 1),
  ('motivation_034', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Thank yourself for your effort before asking for the next thing.', 1),
  ('motivation_035', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'The capacity to begin again already exists within you.', 1),
  ('motivation_036', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Do it for the peace of knowing you tried.', 1),
  ('motivation_037', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Your path can be different and still be valid.', 1),
  ('motivation_038', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Some days are for conquering, others are for saving your strength.', 1),
  ('motivation_039', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'A brave decision can simply be refusing to give up today.', 1),
  ('motivation_040', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Your progress does not have to be visible to be real.', 1),
  ('motivation_041', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Do not let a passing doubt choose your direction.', 1),
  ('motivation_042', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'What you care for today can support you tomorrow.', 1),
  ('motivation_043', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'You also deserve to benefit from your effort.', 1),
  ('motivation_044', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Keep building a life where you can breathe.', 1),
  ('motivation_045', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Calm can also be a form of power.', 1),
  ('motivation_046', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Your next chapter does not need to repeat the last.', 1),
  ('motivation_047', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'You are not late to your own life.', 1),
  ('motivation_048', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Sometimes moving forward means releasing what has become too heavy.', 1),
  ('motivation_049', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Make room for the person you are becoming.', 1),
  ('motivation_050', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Trust grows when you act despite uncertainty.', 1),
  ('motivation_051', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Today you did something your earlier self may have found difficult.', 1),
  ('motivation_052', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Your worth does not shrink when you need a pause.', 1),
  ('motivation_053', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'The right direction can feel slow at first.', 1),
  ('motivation_054', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Not everything has to be solved today for today to matter.', 1),
  ('motivation_055', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Life also changes through quiet choices.', 1),
  ('motivation_056', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'You can be kind to yourself and still be ambitious.', 1),
  ('motivation_057', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Do not give up on a possibility just because you do not master it yet.', 1),
  ('motivation_058', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Your effort deserves continuity, not punishment.', 1),
  ('motivation_059', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'The discomfort of growth does not last forever.', 1),
  ('motivation_060', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'When you treat yourself better, you also make better decisions.', 1),
  ('motivation_061', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'You do not have to feel invincible to act with courage.', 1),
  ('motivation_062', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Your path does not lose value because it has curves.', 1),
  ('motivation_063', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Each season teaches you a different way to move forward.', 1),
  ('motivation_064', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'What seems far away today can begin with one choice.', 1),
  ('motivation_065', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'You are allowed to celebrate before reaching the final goal.', 1),
  ('motivation_066', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Healthy pride can fuel the next step too.', 1),
  ('motivation_067', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Do not turn your goals into a reason to stop caring for yourself.', 1),
  ('motivation_068', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Your life improves when your choices include you too.', 1),
  ('motivation_069', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Motivation can begin after the action.', 1),
  ('motivation_070', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Do not wait to feel ready to give yourself a chance.', 1),
  ('motivation_071', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Your intention deserves a real chance.', 1),
  ('motivation_072', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Today you can end the day knowing you added something good.', 1),
  ('motivation_073', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'A tired mind deserves kind words too.', 1),
  ('motivation_074', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Do not let comparison erase your own journey.', 1),
  ('motivation_075', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'What is difficult for you may also be making you stronger.', 1),
  ('motivation_076', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Your way of moving forward can evolve with you.', 1),
  ('motivation_077', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'You are not required to be the same person you were yesterday.', 1),
  ('motivation_078', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Small decisions can change the way you see yourself.', 1),
  ('motivation_079', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'You can choose a life that feels more like yours, one step at a time.', 1),
  ('motivation_080', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Your well-being is not a reward; it is part of the path.', 1),
  ('motivation_081', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Fear having a voice does not mean it is in charge.', 1),
  ('motivation_082', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Today’s effort can open options for tomorrow.', 1),
  ('motivation_083', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'You do not need a perfect version of yourself to start caring for yourself.', 1),
  ('motivation_084', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'What you do with intention has a special strength.', 1),
  ('motivation_085', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Let your progress take up space in your memory too.', 1),
  ('motivation_086', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'You can want more and value what you already have.', 1),
  ('motivation_087', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'A mindful pause can return you to your direction.', 1),
  ('motivation_088', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Not everything valuable produces immediate results.', 1),
  ('motivation_089', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Your present deserves attention too, not only your goals.', 1),
  ('motivation_090', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'There is power in choosing to continue calmly.', 1),
  ('motivation_091', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Do not let one bad moment define the whole day.', 1),
  ('motivation_092', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'You can learn without speaking harshly to yourself.', 1),
  ('motivation_093', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Your capacity grows each time you move through something new.', 1),
  ('motivation_094', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Let your next decision be on your side.', 1),
  ('motivation_095', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'You do not have to win every day to build a good life.', 1),
  ('motivation_096', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Your energy is limited; spend it on something that brings you closer to yourself.', 1),
  ('motivation_097', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Sometimes change begins when you stop postponing your well-being.', 1),
  ('motivation_098', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'You may still surprise yourself with what you can do.', 1),
  ('motivation_099', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Your life does not need to look perfect to feel meaningful.', 1),
  ('motivation_100', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Choose a reason that helps you return tomorrow.', 1),
  ('motivation_101', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'You are not starting from zero; you are starting with experience.', 1),
  ('motivation_102', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Your perspective can change before your circumstances do.', 1),
  ('motivation_103', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'There is strength in acknowledging that you did well today.', 1),
  ('motivation_104', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Not every challenge asks for more strength; some ask for more patience.', 1),
  ('motivation_105', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Your next opportunity may grow from what you learned today.', 1),
  ('motivation_106', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Dare to build something that cares for you too.', 1),
  ('motivation_107', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Do not confuse moving slowly with standing still.', 1),
  ('motivation_108', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'The way you accompany yourself matters as much as the goal.', 1),
  ('motivation_109', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Today you can choose to move forward without fighting yourself.', 1),
  ('motivation_110', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Your potential also needs rest to unfold.', 1),
  ('motivation_111', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Real change often begins quietly.', 1),
  ('motivation_112', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Do not postpone the recognition you deserve today.', 1),
  ('motivation_113', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Your path becomes clearer as you walk it.', 1),
  ('motivation_114', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Courage can speak softly too.', 1),
  ('motivation_115', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Do something today that helps you trust tomorrow.', 1),
  ('motivation_116', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Your life can become lighter without becoming smaller.', 1),
  ('motivation_117', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'You do not need to justify every step you take for yourself.', 1),
  ('motivation_118', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Hope grows stronger when you turn it into movement.', 1),
  ('motivation_119', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'You can turn pressure into a kinder direction.', 1),
  ('motivation_120', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Your best answer to doubt may be to keep trying.', 1),
  ('motivation_121', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Do not demand that you bloom in every season.', 1),
  ('motivation_122', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'There is progress in learning when to persist and when to adjust.', 1),
  ('motivation_123', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Your effort does not need applause to have value.', 1),
  ('motivation_124', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Today you also gathered experience for what comes next.', 1),
  ('motivation_125', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Do not be afraid to start small; be afraid of not giving yourself the chance.', 1),
  ('motivation_126', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'The energy you invest in yourself is never completely lost.', 1),
  ('motivation_127', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'You can acknowledge tiredness without giving up on your dreams.', 1),
  ('motivation_128', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'What you choose to believe about yourself today can change your next steps.', 1),
  ('motivation_129', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'You do not have to solve your life; just care for the next decision.', 1),
  ('motivation_130', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Your progress can be quiet and still be deep.', 1),
  ('motivation_131', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Some days do not change everything, but they change something important.', 1),
  ('motivation_132', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Let yourself feel satisfied with how far you have come.', 1),
  ('motivation_133', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Do not wait for the finish line to treat yourself as someone valuable.', 1),
  ('motivation_134', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Determination works best when it listens too.', 1),
  ('motivation_135', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Your next attempt will arrive with more experience than the last.', 1),
  ('motivation_136', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'What you are building deserves time to mature.', 1),
  ('motivation_137', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Do not abandon a good direction because of one difficult day.', 1),
  ('motivation_138', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Keep going; you may be closer than you can measure right now.', 1),
  ('motivation_139', 'motivation', 'energetic', 'proverb', 'Popular proverb', '{}'::text[], 100, true, 'The one who keeps going gets there.', 1),
  ('motivation_140', 'motivation', 'balanced', 'proverb', 'Traditional proverb', '{}'::text[], 100, true, 'Little by little, you can go far.', 1),
  ('motivation_141', 'motivation', 'energetic', 'proverb', 'Popular proverb', '{}'::text[], 100, true, 'Practice makes progress.', 1),
  ('motivation_142', 'motivation', 'energetic', 'proverb', 'Latin proverb', '{}'::text[], 100, true, 'Fortune favors the bold.', 1),
  ('motivation_143', 'motivation', 'balanced', 'proverb', 'Popular proverb', '{}'::text[], 100, true, 'After the storm comes calm.', 1),
  ('motivation_144', 'motivation', 'gentle', 'proverb', 'Popular proverb', '{}'::text[], 100, true, 'While there is life, there is hope.', 1),
  ('motivation_145', 'motivation', 'energetic', 'proverb', 'Popular proverb', '{}'::text[], 100, true, 'Those who persevere succeed.', 1),
  ('motivation_146', 'motivation', 'gentle', 'proverb', 'Popular proverb', '{}'::text[], 100, true, 'Every cloud has a silver lining.', 1),
  ('motivation_147', 'motivation', 'energetic', 'proverb', 'Popular proverb', '{}'::text[], 100, true, 'Together, we are stronger.', 1),
  ('motivation_148', 'motivation', 'balanced', 'proverb', 'Popular proverb', '{}'::text[], 100, true, 'Better a steady step than a tiring sprint.', 1),
  ('motivation_149', 'motivation', 'balanced', 'quote', 'Antonio Machado', '{}'::text[], 100, true, 'Traveler, there is no path; the path is made by walking.', 1),
  ('motivation_150', 'motivation', 'gentle', 'quote', 'Delphic maxim', '{}'::text[], 100, true, 'Know yourself.', 1)
;

-- Existing base metadata must match; it is never overwritten.
do $$
begin
  if exists (
    select 1
    from _completed_day_phrase_expected e
    left join public.motivational_phrases p on p.id = e.id
    where p.id is null
  ) then
    raise exception 'Missing motivational phrase base metadata.';
  end if;
  if exists (
    select 1
    from _completed_day_phrase_expected e
    join public.motivational_phrases p on p.id = e.id
    where p.category is distinct from e.category
       or p.tone is distinct from e.tone
       or p.source_type is distinct from e.source_type
       or p.required_tokens is distinct from e.required_tokens
       or p.weight is distinct from e.weight
  ) then
    raise exception 'Motivational phrase structural metadata mismatch.';
  end if;
end;
$$;

insert into public.motivational_phrases (
  id, category, tone, source_type, author, required_tokens, weight, enabled
)
select id, category, tone, source_type, author, required_tokens, weight, enabled
from _completed_day_phrase_expected
on conflict (id) do nothing;

insert into public.motivational_phrase_translations (
  phrase_id, locale, template, review_status, translator_note, content_version
)
select id, 'en-US', template, 'reviewed', null, content_version
from _completed_day_phrase_expected
on conflict (phrase_id, locale) do update set
  template = excluded.template,
  review_status = excluded.review_status,
  translator_note = excluded.translator_note,
  content_version = excluded.content_version;

create temporary table _completed_day_phrase_seed_release (
  release_id uuid primary key
) on commit drop;

do $$
declare
  v_release_id uuid;
begin
  select id into v_release_id
  from public.phrase_catalog_releases
  where locale = 'en-US' and release_version = 1;
  if v_release_id is null then
    insert into public.phrase_catalog_releases (locale, release_version, schema_version, status, is_current)
    values ('en-US', 1, 1, 'draft', false)
    returning id into v_release_id;
  else
    update public.phrase_catalog_releases
    set schema_version = 1, status = 'draft', is_current = false, published_at = null
    where id = v_release_id;
  end if;
  insert into _completed_day_phrase_seed_release values (v_release_id);
end;
$$;

delete from public.phrase_catalog_release_entries
where release_id = (select release_id from _completed_day_phrase_seed_release);

insert into public.phrase_catalog_release_entries (
  release_id, phrase_id, category, tone, source_type, author, template,
  required_tokens, weight, enabled, content_version
)
select
  s.release_id, e.id, e.category, e.tone, e.source_type, e.author, e.template,
  e.required_tokens, e.weight, e.enabled, e.content_version
from _completed_day_phrase_seed_release s
join _completed_day_phrase_expected e on true;

-- Pre-publication integrity checks.
do $$
declare
  v_release_id uuid;
  v_count integer;
begin
  select release_id into v_release_id from _completed_day_phrase_seed_release;
  select count(*) into v_count from public.motivational_phrase_translations t
    join _completed_day_phrase_expected e on e.id = t.phrase_id
    where t.locale = 'en-US';
  if v_count <> 300 then raise exception 'Expected 300 en-US translations, got %', v_count; end if;
  select count(*) into v_count from public.phrase_catalog_release_entries where release_id = v_release_id;
  if v_count <> 300 then raise exception 'Expected 300 en-US release entries, got %', v_count; end if;
  if (select count(*) from public.phrase_catalog_release_entries where release_id = v_release_id and category = 'personal') <> 50 then raise exception 'Expected 50 personal entries'; end if;
  if (select count(*) from public.phrase_catalog_release_entries where release_id = v_release_id and category = 'consistency') <> 100 then raise exception 'Expected 100 consistency entries'; end if;
  if (select count(*) from public.phrase_catalog_release_entries where release_id = v_release_id and category = 'motivation') <> 150 then raise exception 'Expected 150 motivation entries'; end if;
  if exists (select 1 from public.phrase_catalog_release_entries where release_id = v_release_id and btrim(template) = '') then raise exception 'Empty release template'; end if;
  if exists (select 1 from public.phrase_catalog_release_entries where release_id = v_release_id and weight <= 0) then raise exception 'Invalid release weight'; end if;
  if exists (select 1 from public.phrase_catalog_release_entries where release_id = v_release_id and content_version <= 0) then raise exception 'Invalid release content version'; end if;
  if exists (select 1 from public.phrase_catalog_release_entries where release_id = v_release_id and not (required_tokens <@ array['name', 'streak_label', 'progress']::text[])) then raise exception 'Invalid required token'; end if;
  if (select count(distinct phrase_id) from public.phrase_catalog_release_entries where release_id = v_release_id) <> 300 then raise exception 'Duplicate release phrase IDs'; end if;
end;
$$;

update public.phrase_catalog_releases set is_current = false where locale = 'en-US' and status = 'published' and is_current = true and id <> (select release_id from _completed_day_phrase_seed_release);
update public.phrase_catalog_releases set status = 'published', published_at = now(), is_current = true where id = (select release_id from _completed_day_phrase_seed_release);

commit;
