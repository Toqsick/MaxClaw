---
name: security-attestation-patterns
description: Adding audit-guaranteed properties (attestations) to runtime data structures and enforcing them at architectural boundaries — the Kernel-Ebene-4-Attest pattern. Type extension → runtime injection → reviewer gating → config exposure. Works for any codebase with security-kernel, review-gate, or audit-trail patterns.
version: 1.0.0
author: Yuno
license: MIT
platforms:
- linux
- macos
- windows
metadata:
  hermes:
    category: security
    tags:
    - security
    - attestation
    - audit
    - review-gate
    - typescript
    - architecture
---
# Security Attestation Patterns

## Trigger

Load this skill when:
- A task involves adding cryptographically-signed / audited properties to runtime data structures (e.g. intentHash, nonce, attestation token)
- Work needs enforcement of those properties at a review/inspection/gate boundary
- A security assessment doc lists "gap: missing attestation field X on type Y — enforce at boundary Z"
- Adding a new config block to expose runtime security parameters

## The Pattern: Kernel-Ebene-4-Attest

The core pattern is a 4-step chain that guarantees every tool call or public action is Kernel-attested:

```
Step 1: Type Extension
  → Add attestation field (optional on type, required by gate)
  → Never breaking — old ToolCalls without field still compile

Step 2: Runtime Injection
  → After Kernel logs the intent (logIntent / auditIntention),
    persist the resulting hash/attestation onto the object
  → Single line: call.attestationField = inputHash

Step 3: Reviewer / Gate Enforcement
  → Check at the START of every review, before business logic
  → If attestation field is missing: BLOCK immediately
  → Order: attestation check FIRST (Kernel-Bypass detection)
            → contract checks (failed-without-Delta)
            → output/artifact checks

Step 4: Config Exposure
  → Make attestation parameters configurable via a config block
  → Block must be additive (old configs still parse)
  → Block must be fail-closed by default
    (enabled: true, bypassAllowed: false, failOpen: false)
  → _comment inside JSON explains single-point-of-control for operators
```

### Step Details

#### Step 1: Type Extension

```typescript
// BEFORE
interface ToolCall {
  toolName: string;
  input: Record<string, unknown>;
  outcome: 'success' | 'failure';
  outputArtifactIds: string[];
}

// AFTER — additive, non-breaking
interface ToolCall {
  toolName: string;
  input: Record<string, unknown>;
  outcome: 'success' | 'failure';
  outputArtifactIds: string[];
  intentHash?: string;  // Kernel-Ebene-4-Attest
}
```

Key rule: Make it optional (`?`) on the type. Compliance is enforced at the gate, not the type system. This lets old objects parse without migration.

#### Step 2: Runtime Injection

```typescript
// Find the exact line where logIntent / auditIntention fires
const inputHash = hashString(someInput);
logIntent({ taskId, role, tool, hash: inputHash });

// Persist onto the ToolCall — ONE line
const call: ToolCall = {
  ...existingFields,
  intentHash: inputHash,  // ← Kernel attestation
};
```

Place it so it hits both success AND failure paths (same object literal or assignment).

#### Step 3: Reviewer Gate Enforcement

```typescript
async review(task: TaskCard): Promise<TaskCard> {
  // Check 0 — attestation gate, FIRST
  const missing = task.toolCalls.some(c => !c.intentHash);
  if (missing) {
    task.status = 'blocked';
    task.notes.push('Reviewer: tool call without attestation — Bypass detected');
    task.updatedAt = new Date().toISOString();
    return task;
  }

  // Existing checks follow (contract, output, etc.)
}
```

**Check ordering matters:**
1. Attestation check (Kernel-Bypass detection)
2. Contract checks (failed-without-Delta, atomic contract violations)
3. Output checks (artifacts exist for expected outputs)

This way a bypass attempt is flagged before other violations could confuse the audit trail.

#### Step 4: Config Exposure

```typescript
// In the config type — additive, optional
interface HermesConfig {
  // ... existing fields
  securityKernel?: {
    enabled: boolean;
    bypassAllowed: boolean;
    failOpen: boolean;
  };
}
```

```json
// In the JSON config — fail-closed defaults
{
  "securityKernel": {
    "_comment": "Single-point-of-control for operators — requires explicit action to weaken",
    "enabled": true,
    "bypassAllowed": false,
    "failOpen": false
  }
}
```

**Semantics of each default:**
- `enabled: true` — Kernel actively checks attestations. Set `false` during transition, not permanently.
- `bypassAllowed: false` — No legitimate bypass path exists. Set `true` for trusted debugging contexts.
- `failOpen: false` — If the attestation cannot be verified, block (closed) rather than allow (open).

## Test Patterns

### Attestation Tests (3 scenarios)

| # | Scenario | Expectation |
|---|----------|-------------|
| 1 | Mixed: some toolCalls have attestation, some don't | BLOCKED |
| 2 | All missing attestation + all other checks pass | BLOCKED (attestation fires first) |
| 3 | All toolCalls have attestation, happy path | Passes to next stage |

### Config Defaults Tests (2 scenarios)

| # | Scenario | Expectation |
|---|----------|-------------|
| 1 | Read live config JSON, verify defaults | fail-closed (enabled=true, bypassAllowed=false, failOpen=false) |
| 2 | Schema validation: object with/without securityKernel block | Both compile |

### Anti-Patterns in Testing

- Do NOT test that the *orchestrator* sets the attestation — test that the *gate* enforces it.
- Do NOT test the hash function directly (it changes when input format changes).
- Do NOT test config file path resolution — test the in-memory defaults and type boundaries.

## Verification

After implementing the 4-step chain:

```bash
# Run the full test suite (excluding pre-existing failures)
npx jest --passWithNoTests --testPathIgnorePatterns="/node_modules/" 2>&1 | tail -15

# Specifically verify the attestation + gate tests
npx jest src/roles/__tests__/reviewer-a.test.ts 2>&1 | tail -10

# Verify gate + orchestrator + kernel tests together
npx jest src/security/__tests__/kernel.test.ts src/roles/__tests__/orchestrator.test.ts 2>&1 | tail -10
```

## Pitfalls

- **Do NOT add attestation as a required (non-optional) type field.** Old objects won't parse. Gate enforcement is the correct enforcement point.
- **Do NOT reorder checks.** Attestation FIRST means a bypass is caught even when other checks would also block. The audit trail stays clean.
- **Do NOT make test scenarios too coupled to hash implementation.** Test that the *presence* of the field gates correctly, not that a specific hash value matches.
- **Do NOT forget both success AND failure paths** when injecting attestation at runtime. A failure-path call still needs the attestation.
- **Config defaults MUST be fail-closed**, not fail-open. `failOpen: true` as default is a security incident waiting to happen.
- **The config block is additive** — existing config files without it must still parse. Use `?` on the type field.
- **Pre-existing test failures in unrelated files** — always run with `--testPathIgnorePatterns` to isolate new work from pre-existing issues.

## Related Skills

- `test-driven-development` — For RED-GREEN-REFACTOR cycles that pair with attestation gate tests
- `security-code-checker` — For scanning existing code for missing attestation fields
- `verify-before-fix` — For finding the exact location where attestation should be injected

## References

- `references/intent-hash-chain-hermes-v7.md` — Concrete session example (Issue #1 intent-hash chain implementation)
