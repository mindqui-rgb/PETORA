import { createBrowserClient } from "@supabase/ssr";

/**
 * Creates a Supabase client for use in client components.
 * This client uses localStorage for session management.
 */
export const supabase = createBrowserClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!
);
