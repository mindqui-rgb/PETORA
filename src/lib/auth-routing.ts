const publicRoutes = ["/login", "/api/health"];
const redirectOrigin = "https://petora.invalid";

export function isPublicRoute(pathname: string): boolean {
  return publicRoutes.some(
    (route) => pathname === route || pathname.startsWith(`${route}/`)
  );
}

export function getPostLoginPath(path: string | null): string {
  if (!path || !path.startsWith("/") || path.startsWith("//") || path.includes("\\")) {
    return "/";
  }

  try {
    const destination = new URL(path, redirectOrigin);
    if (destination.origin !== redirectOrigin) {
      return "/";
    }
    return `${destination.pathname}${destination.search}${destination.hash}`;
  } catch {
    return "/";
  }
}
