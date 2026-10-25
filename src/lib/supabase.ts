import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

/**
 * Creates a Supabase client for use in Server Components and Route Handlers.
 * Uses cookies for session management via the global cookie store.
 */
export async function createSupabaseClient() {
  const cookieStore = await cookies();

  const cookieGet = (name: string): string | undefined => {
    try {
      const result = cookieStore.get(name);
      if (result && typeof result === "object" && "value" in result) {
        return result.value as string;
      }
      return undefined;
    } catch {
      return undefined;
    }
  };

  const cookieSet = (name: string, value: string, opts: Record<string, unknown> = {}): void => {
    try {
      const store = cookieStore as unknown as {
        set: (opts: Record<string, unknown>) => void;
      };
      store.set({ name, value, ...opts });
    } catch {
      // Called from Server Components where setting cookies is not allowed.
    }
  };

  const cookieRemove = (name: string, opts: Record<string, unknown> = {}): void => {
    try {
      const store = cookieStore as unknown as {
        set: (opts: Record<string, unknown>) => void;
      };
      store.set({ name, value: "", ...opts });
    } catch {
      // Called from Server Components where setting cookies is not allowed.
    }
  };

  const options = {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
      storage: {
        getItem: (key: string) => {
          return cookieGet(key) ?? null;
        },
        setItem: (key: string, value: string) => {
          cookieSet(key, value);
        },
        removeItem: (key: string) => {
          cookieRemove(key);
        },
      },
    },
  };

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    options as any
  );
}
