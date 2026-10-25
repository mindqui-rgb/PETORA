import "@testing-library/jest-dom";

// Mock Supabase client for unit tests
vi.mock("@/lib/supabase", () => ({
  createClient: () => ({
    auth: {
      getUser: vi.fn(),
      signOut: vi.fn(),
      signInWithPassword: vi.fn(),
      resetPasswordForEmail: vi.fn(),
      verifyOtp: vi.fn(),
      enroll: vi.fn(),
      verify: vi.fn(),
      refreshSession: vi.fn(),
    },
    from: vi.fn(() => ({
      select: vi.fn().returnThis(),
      insert: vi.fn().returnThis(),
      update: vi.fn().returnThis(),
      delete: vi.fn().returnThis(),
      eq: vi.fn().returnThis(),
      single: vi.fn(),
      order: vi.fn().returnThis(),
      limit: vi.fn().returnThis(),
      maybeSingle: vi.fn(),
      rpc: vi.fn(),
    })),
    storage: {
      from: vi.fn(() => ({
        upload: vi.fn(),
        download: vi.fn(),
        remove: vi.fn(),
        createSignedUrl: vi.fn(),
      })),
    },
    channel: vi.fn(() => ({
      on: vi.fn().returnThis(),
      subscribe: vi.fn(),
    })),
  }),
}));

// Mock fetch globally
global.fetch = vi.fn();
