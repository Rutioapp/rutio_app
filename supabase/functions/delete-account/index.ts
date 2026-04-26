import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const jsonHeaders = {
  ...corsHeaders,
  'Content-Type': 'application/json',
};

function jsonResponse(
  body: Record<string, unknown>,
  status: number,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: jsonHeaders,
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return jsonResponse(
      { success: false, error: 'method_not_allowed' },
      405,
    );
  }

  try {
    const authHeader = req.headers.get('Authorization');

    if (!authHeader?.toLowerCase().startsWith('bearer ')) {
      return jsonResponse({ success: false, error: 'unauthorized' }, 401);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
    const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceRoleKey) {
      console.error('delete-account missing server configuration');
      return jsonResponse(
        { success: false, error: 'server_not_configured' },
        500,
      );
    }

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return jsonResponse({ success: false, error: 'unauthorized' }, 401);
    }

    const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Delete user-owned data here in dependency order.
    // Current code references profiles.id and user_progress.user_id.
    // Future user-owned tables should be added here before deleting auth.users.
    const userOwnedDeletes = [
      {
        stage: 'user_progress',
        request: () =>
          adminClient.from('user_progress').delete().eq('user_id', user.id),
      },
      {
        stage: 'profiles',
        request: () =>
          adminClient.from('profiles').delete().eq('id', user.id),
      },
    ];

    for (const deleteRequest of userOwnedDeletes) {
      const { error } = await deleteRequest.request();
      if (error) {
        console.error(
          'delete-account data cleanup failed',
          { stage: deleteRequest.stage, code: error.code ?? 'unknown' },
        );
        return jsonResponse({ success: false, error: 'delete_failed' }, 500);
      }
    }

    const { error: deleteUserError } = await adminClient.auth.admin.deleteUser(
      user.id,
    );

    if (deleteUserError) {
      console.error(
        'delete-account auth user delete failed',
        { code: deleteUserError.code ?? 'unknown' },
      );
      return jsonResponse({ success: false, error: 'delete_failed' }, 500);
    }

    return jsonResponse({ success: true }, 200);
  } catch (error) {
    console.error(
      'delete-account unexpected error',
      error instanceof Error ? error.message : 'unknown',
    );
    return jsonResponse({ success: false, error: 'unexpected_error' }, 500);
  }
});
