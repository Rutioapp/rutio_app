/**
 * Hand-maintained types for the RevenueCat RPCs used by the Edge Functions.
 *
 * The generated Supabase schema is not checked into this worktree, so keeping
 * these signatures explicit prevents supabase-js from falling back to an RPC
 * argument type of `undefined` while still checking every parameter name.
 */
export type Database = {
  public: {
    Tables: {
      revenuecat_backfill_runs: {
        Row: { run_id: string };
        Insert: Record<string, never>;
        Update: Partial<{ run_id: string }>;
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: {
      apply_revenuecat_entitlement_for_webhook: {
        Args: {
          p_event_id: string;
          p_lease_token: string;
          p_user_id: string;
          p_revenuecat_app_user_id: string;
          p_is_active: boolean;
          p_expires_at: string | null;
          p_product_id: string | null;
          p_store: string | null;
          p_environment: string;
          p_event_at: string | null;
          p_projection_event_id: string;
          p_app_id: string;
          p_observed_at: string | null;
          p_observed_reliable: boolean;
        };
        Returns: boolean;
      };
      fail_revenuecat_backfill_run: {
        Args: { p_run_id: string; p_lease_token: string; p_error_code: string };
        Returns: boolean;
      };
      apply_revenuecat_entitlement_for_backfill: {
        Args: {
          p_run_id: string;
          p_lease_token: string;
          p_user_id: string;
          p_revenuecat_app_user_id: string;
          p_is_active: boolean;
          p_expires_at: string | null;
          p_product_id: string | null;
          p_environment: string;
          p_event_at: string | null;
          p_projection_event_id: string;
          p_app_id: string;
          p_observed_at: string | null;
          p_observed_reliable: boolean;
        };
        Returns: boolean;
      };
      claim_revenuecat_backfill_run: {
        Args: { p_run_id: string };
        Returns: Record<string, unknown>;
      };
      advance_revenuecat_backfill_run_v2: {
        Args: {
          p_run_id: string;
          p_lease_token: string;
          p_page_key: string;
          p_next_starting_after: string | null;
          p_examined_delta: number;
          p_updated_delta: number;
        };
        Returns: boolean;
      };
      claim_revenuecat_reconciliation_batch: {
        Args: { p_limit: number };
        Returns: Array<Record<string, unknown>>;
      };
      fail_revenuecat_reconciliation: {
        Args: {
          p_user_id: string;
          p_lease_token: string;
          p_error_code: string;
          p_retry_after_seconds: number;
        };
        Returns: boolean;
      };
      apply_revenuecat_reconciliation: {
        Args: {
          p_user_id: string;
          p_lease_token: string;
          p_is_active: boolean;
          p_expires_at: string | null;
          p_product_id: string | null;
          p_observed_at: string;
          p_observed_reliable: boolean;
          p_event_id: string;
          p_app_id: string;
        };
        Returns: Record<string, unknown>;
      };
      claim_revenuecat_webhook_event: {
        Args: {
          p_event_id: string;
          p_event_type: string;
          p_app_user_id: string | null;
          p_event_at: string | null;
          p_environment: string | null;
        };
        Returns: Record<string, unknown>;
      };
      finalize_revenuecat_webhook_event: {
        Args: {
          p_event_id: string;
          p_lease_token: string;
          p_status: string;
          p_error_code: string | null;
        };
        Returns: boolean;
      };
      enqueue_revenuecat_premium_sync: {
        Args: {
          p_user_id: string;
          p_app_id: string;
          p_environment: string;
          p_event_id: string | null;
          p_priority: number;
          p_allowlisted: boolean;
        };
        Returns: Record<string, unknown>;
      };
      apply_revenuecat_positive_event: {
        Args: {
          p_event_id: string;
          p_lease_token: string;
          p_user_id: string;
          p_revenuecat_app_user_id: string;
          p_expires_at: string;
          p_product_id: string | null;
          p_store: string | null;
          p_environment: string;
          p_event_at: string | null;
          p_app_id: string;
          p_subscription_key: string;
          p_allowlisted: boolean;
        };
        Returns: boolean;
      };
      claim_revenuecat_premium_sync: {
        Args: {
          p_user_id: string;
          p_app_id: string;
          p_environment: string;
          p_allowlisted: boolean;
        };
        Returns: Record<string, unknown>;
      };
      apply_revenuecat_v2_reconciliation: {
        Args: {
          p_user_id: string;
          p_app_id: string;
          p_environment: string;
          p_lease_token: string;
          p_subscriptions: unknown[];
          p_read_complete: boolean;
        };
        Returns: Record<string, unknown>;
      };
      complete_revenuecat_premium_sync: {
        Args: {
          p_user_id: string;
          p_app_id: string;
          p_environment: string;
          p_lease_token: string;
          p_success: boolean;
          p_error_code: string | null;
        };
        Returns: boolean;
      };
    };
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};
