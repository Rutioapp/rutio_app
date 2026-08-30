begin;

grant execute on function app_private.feedback_screenshot_path_is_valid(uuid, uuid, text)
to authenticated;

commit;
