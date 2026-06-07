// Safe navigation helper — prevents blank views and JS crashes from
// navigating to routes that have no screen file yet.
//
// Rules:
//   • Route is registered AND implemented → navigate directly.
//   • Route is registered AND placeholder → navigate; the placeholder
//     screen renders ComingSoonScreen rather than crashing.
//   • Route is NOT registered at all → navigate to /+not-found so the
//     user sees a graceful error instead of a blank or red screen.

import { type Router } from "expo-router";
import { REGISTERED_ROUTES } from "./screen-registry";

export function safeNavigate(router: Router, route: string): void {
  if (!REGISTERED_ROUTES.has(route)) {
    // Unregistered route — send to not-found rather than crashing.
    router.push("/+not-found" as never);
    return;
  }
  router.push(route as never);
}
