begin;

create unique index
  idx_habit_currency_reward_ledger_user_op_habit_date_unique
on public.habit_currency_reward_ledger (
  user_id,
  operation_type,
  habit_id,
  logical_date_key
);

commit;
