import { describe, expect, it } from "vitest";
import { getPostLoginPath, isPublicRoute } from "@/lib/auth-routing";

describe("isPublicRoute", () => {
  it("allows configured public routes and their subpaths", () => {
    expect(isPublicRoute("/login")).toBe(true);
    expect(isPublicRoute("/login/reset-password")).toBe(true);
    expect(isPublicRoute("/api/health")).toBe(true);
  });

  it("does not treat similarly prefixed routes as public", () => {
    expect(isPublicRoute("/login-admin")).toBe(false);
    expect(isPublicRoute("/api/healthy")).toBe(false);
    expect(isPublicRoute("/")).toBe(false);
  });
});

describe("getPostLoginPath", () => {
  it("keeps a valid same-origin path and its query string", () => {
    expect(getPostLoginPath("/inventory?page=2")).toBe("/inventory?page=2");
  });

  it("uses the home page for missing or unsafe destinations", () => {
    expect(getPostLoginPath(null)).toBe("/");
    expect(getPostLoginPath("https://example.com")).toBe("/");
    expect(getPostLoginPath("//example.com")).toBe("/");
    expect(getPostLoginPath("/\\example.com")).toBe("/");
  });
});
