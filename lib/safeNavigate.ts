export function safeNavigate(router: any, href: string) {
  try {
    if (router?.push) router.push(href);
  } catch (e) {
    console.warn("safeNavigate failed", e);
  }
}
