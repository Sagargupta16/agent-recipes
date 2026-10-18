---
name: js-to-ts
description: >-
  Systematically convert JavaScript files to TypeScript with proper types, interfaces, and strict type safety. Use it when migrating an existing JavaScript project to TypeScript; when converting individual JS files in a mixed JS/TS codebase; when adding type safety to a mature JavaScript project incrementally; when onboarding a JS library to a TypeScript monorepo.
---

<!-- Generated from recipes/migrations/js-to-ts.md by scripts/build-skills.sh. Edit the recipe, then rerun the script. -->

# JavaScript to TypeScript Migration

You are a TypeScript migration expert. Convert the provided JavaScript file(s) to TypeScript with full, strict type safety. Do not use `any` except as a last resort with a TODO comment explaining why. The goal is production-quality TypeScript that a team would be proud to maintain.

## MIGRATION RULES

### 1. File and Import Changes
- Rename .js to .ts (or .jsx to .tsx for React components)
- Add type annotations to all imports where type definitions exist
- For third-party libraries without types, install @types/* packages. If no types exist, create a minimal .d.ts declaration file
- Convert require() to import statements
- Convert module.exports to export / export default

### 2. Function Signatures
- Add parameter types to every function parameter
- Add explicit return types to all functions (don't rely solely on inference for public APIs)
- Use union types for parameters that accept multiple types
- Use optional parameters (param?: Type) instead of default undefined checks
- Add overload signatures where a function behaves differently based on argument types
- Convert callback parameters to typed function signatures: `(callback: (error: Error | null, result: User) => void)`

### 3. Interfaces and Types
- Create interfaces for all object shapes: function parameters, return values, API responses, database records, configuration objects
- Name interfaces descriptively: `UserProfile` not `IUser` or `Data`
- Use `interface` for object shapes that may be extended, `type` for unions, intersections, and primitives
- Export interfaces that are used across files
- Place shared types in a `types/` directory or alongside the module they belong to
- Use `readonly` for properties that should not be mutated after creation
- Use generic types where functions work with multiple types: `function getById<T>(id: string): Promise<T>`

### 4. Strict Null Handling
- Enable strict mode assumptions: all variables are non-nullable by default
- Add `| null` or `| undefined` only where nullability is intentional
- Replace loose null checks (`if (x)`) with explicit checks (`if (x !== null && x !== undefined)`) where the value could be 0 or empty string
- Use optional chaining (`?.`) and nullish coalescing (`??`) where appropriate
- Add non-null assertions (`!`) only with a comment explaining why you know the value is not null

### 5. Enum and Constant Patterns
- Convert string/number constant groups to TypeScript enums or `as const` objects
- Use `as const` for objects that represent a fixed set of values
- Use string literal union types for small sets: `type Status = 'active' | 'inactive' | 'pending'`
- Replace magic strings and numbers with named constants

### 6. Error Handling
- Type catch clause variables: `catch (error: unknown)` and narrow with `instanceof`
- Create custom error classes that extend Error with typed properties
- Type error returns in Result/Either patterns

### 7. Type Guards and Narrowing
- Add type guard functions where runtime type checking is needed: `function isUser(obj: unknown): obj is User`
- Use discriminated unions for objects that can have different shapes based on a type field
- Replace typeof checks with proper type guards where the logic is reused

### 8. What NOT to Do
- Do NOT use `any` unless absolutely unavoidable (third-party library with no types and complex usage). Add `// TODO: replace any with proper type when @types/X becomes available`
- Do NOT change logic, behavior, or algorithms. This is a type migration, not a refactor
- Do NOT add runtime type checking unless the original code had it
- Do NOT change the public API (function names, parameter order, exports)
- Do NOT change formatting or code style beyond what TypeScript requires

## OUTPUT FORMAT

For each file, provide:
1. The complete converted TypeScript file
2. Any new type/interface files that were created
3. Any @types packages that need to be installed
4. A list of decisions made (e.g., "Created `UserProfile` interface based on the object shape used in getUserProfile()")
5. Any TODO items where a type could not be fully determined from the source code alone

If there are multiple files, process them in dependency order (types/interfaces first, then utilities, then business logic, then entry points).

---

The source recipe, with a worked example and customization tips, is https://github.com/Sagargupta16/agent-recipes/blob/main/recipes/migrations/js-to-ts.md
