import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const jsonHeaders = {
  'Content-Type': 'application/json',
};

Deno.serve(async (request) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing server configuration.' }),
        { status: 500, headers: jsonHeaders },
      );
    }

    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.toLowerCase().startsWith('bearer ')) {
      return new Response(
        JSON.stringify({ success: false, error: 'Not authenticated.' }),
        { status: 401, headers: jsonHeaders },
      );
    }

    const userScopedClient = createClient(supabaseUrl, anonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    });

    const {
      data: { user },
      error: userError,
    } = await userScopedClient.auth.getUser();

    if (userError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Not authenticated.' }),
        { status: 401, headers: jsonHeaders },
      );
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // Strategy:
    // - Delete auth.users row for the currently authenticated user.
    // - User-owned tables should cascade via FK ON DELETE CASCADE
    //   (profiles, habits, habit_logs, journal_entries, user_progress, xp_events,
    //    currency_events, user_achievements).
    // - Do not touch global tables such as achievement_definitions.
    const { error: deleteUserError } = await adminClient.auth.admin.deleteUser(
      user.id,
    );

    if (deleteUserError) {
      return new Response(
        JSON.stringify({
          success: false,
          error: deleteUserError.message || 'Failed to delete account.',
        }),
        { status: 500, headers: jsonHeaders },
      );
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: jsonHeaders,
    });
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Internal server error.',
      }),
      { status: 500, headers: jsonHeaders },
    );
  }
});
