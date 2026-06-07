---
name: TSX generic component Babel fix
description: How to fix <Component<T>> syntax that Babel/Vite can't parse in TSX files.
---

# TSX Generic Component — Babel Parse Fix

## The Rule
Never use explicit generic type arguments in JSX (`<Component<T> ...>`) in `.tsx` files
processed by Babel/Vite. Drop the type argument entirely and let TypeScript infer it.

**Why:** Babel's JSX parser sees `<FilterSelect<SeverityFilter>` and tries to parse
`<SeverityFilter>` as a JSX element attribute, throwing "Unexpected token". The trailing
comma workaround (`<FilterSelect<SeverityFilter,>`) fixes Babel but triggers
`TS1009: Trailing comma not allowed` from `tsc`.

**The fix:** Remove the explicit type arg. If the component's props are well-typed,
TypeScript infers `T` from the `value` or `options` props.

```tsx
// Bad — crashes Babel:
<FilterSelect<SeverityFilter> ... />

// Also bad — Babel OK but tsc TS1009:
<FilterSelect<SeverityFilter,> ... />

// Correct — TypeScript infers T from typed value prop:
<FilterSelect ... />
```

## How to Apply
Whenever `tsc` or Vite throws about an unexpected token in a `.tsx` component opening
tag, grep for `<[A-Z][a-zA-Z]*<[A-Z]` across `src/**/*.tsx`. Remove all explicit generic
args from JSX and verify TypeScript still accepts the usage via inference.
