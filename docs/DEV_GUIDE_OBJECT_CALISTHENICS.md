# Development Guide — Object Calisthenics (TypeScript)

This guide explains how we apply Object Calisthenics to keep code simple, robust, and maintainable. These are review guidelines rather than hard lint rules. Prefer clarity over cleverness.

## Core principles

- One level of indentation per method
- Don’t use `else` (prefer early returns / guard clauses)
- Wrap primitives and strings (Value Objects)
- First-class collections (encapsulate arrays in classes)
- One dot per line (avoid deep chains, break expressions)
- Don’t abbreviate (use meaningful names)
- Keep entities small (≈50 lines max, extract behavior)
- No classes with more than two instance variables (favor cohesion)
- No getters/setters/properties unless meaningful behavior is attached

## How to apply

- **Small functions**: extract pure helpers; aim for ≤ 10–15 lines per function.
- **Early returns**: validate inputs first, exit on invalid states; reduces nested conditionals.
- **Value Objects**: introduce types for domain concepts (e.g., `SkuCode`, `Money`, `Deadline`). Validation and invariants live in VOs.
- **Collections**: create a `VendorList` instead of using `Vendor[]` everywhere; add domain operations there.
- **Reduce chaining**: break at each step, name the result (improves readability and logging).
- **Meaningful names**: avoid `data`/`obj`; prefer `rfq`, `quote`, `vendor`, etc.
- **Small classes**: extract responsibilities; avoid classes with >2 fields.
- **Behavior over state**: methods that expose domain actions; avoid anemic models.

## Examples

### Early return (no `else`)

```ts
function approveQuote(quote: Quote): void {
  if (!quote.canBeApproved()) return;
  quote.approve();
}
```

### Value Object with validation

```ts
export class SkuCode {
  constructor(private readonly value: string) {
    if (!value || value.length < 3) throw new Error('Invalid SkuCode');
  }
  toString() {
    return this.value;
  }
}
```

### First-class collection

```ts
export class VendorList {
  constructor(private readonly items: Vendor[]) {}
  add(v: Vendor) {
    if (this.contains(v.id)) throw new Error('Duplicate vendor');
    this.items.push(v);
  }
  contains(id: VendorId) {
    return this.items.some((v) => v.id.equals(id));
  }
  isEmpty() {
    return this.items.length === 0;
  }
}
```

## Code review checklist

- Is there at most one indentation level per method?
- Are guard clauses used instead of `else` blocks?
- Are domain primitives wrapped as Value Objects with validation?
- Are repeated arrays modeled as first-class collections?
- Are functions/classes small and cohesive?
- Are names descriptive and non-abbreviated?
- Is behavior placed on domain objects rather than exposing raw state?

## Lint and tooling

- We intentionally do not enforce all rules via ESLint. Use `eslint` and `prettier` for hygiene, apply Object Calisthenics via reviews.
- Prefer `no-console` except `console.error`, `console.warn`, `console.info` in infra/bootstrapping.

## When to be pragmatic

- Small utilities may use primitives directly if a VO would add no value.
- Data-mapping boundaries (DTOs) can break some rules for simplicity, but keep them isolated.

## References

- budtrainer/arquitetura.md (Object Calisthenics section)
- Object Calisthenics by Jeff Bay / 9 rules for better OO design
