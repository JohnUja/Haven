# Theme Architecture Proposal

## Current Problem
- Shop themes (`Theme` model) are just metadata - they don't store actual theme values
- Light, Dark, Purple themes exist as `AppTheme` structs but aren't properly linked to shop
- No way to add new shop themes with their own values

## Recommended Solution: **Hybrid Approach**

### Option A: Keep AppTheme Structs + Link via ID (RECOMMENDED)
**Pros:**
- Type-safe (compile-time checking)
- Performant (no database lookups for theme values)
- Easy to maintain
- All theme properties available at compile time

**Cons:**
- Need code changes to add new themes
- Themes are hardcoded

**How it works:**
1. Create `AppTheme` struct for each shop theme (e.g., `SunsetTheme: AppTheme`)
2. Add it to `ThemeManager.themes` array
3. Create `Theme` database entry with matching `id`
4. When user selects theme, `ThemeManager.setTheme(to: id)` finds matching `AppTheme` struct

### Option B: Store All Properties in Database
**Pros:**
- Can add themes without code changes
- Fully dynamic

**Cons:**
- Complex serialization (Color, LinearGradient need encoding)
- Runtime errors instead of compile-time
- Performance overhead
- Hard to maintain

## Recommendation: **Option A**

### Implementation Plan:

1. **Fix Theme Database Entries**
   - Update `MainTabView.setupDefaultUser()` to create `Theme` entries with IDs matching `AppTheme` structs:
     - `Theme(id: "purple", ...)` → matches `PurpleTheme(id: "purple")`
     - `Theme(id: "light", ...)` → matches `LightTheme(id: "light")`
     - `Theme(id: "dark", ...)` → matches `DarkTheme(id: "dark")`

2. **Add Shop Themes as AppTheme Structs**
   - Create new `AppTheme` structs for shop themes (e.g., `SunsetTheme`, `VintageTheme`)
   - Add them to `ThemeManager.themes` array
   - Create matching `Theme` database entries

3. **Update Theme Shop Display**
   - Ensure shop shows all themes (default + purchasable)
   - Default themes (Light, Dark, Purple) show as "Default" or "Free"
   - Crystal-purchased themes show price

## Example Structure:

```swift
// AppTheme.swift
struct SunsetTheme: AppTheme {
    let id = "sunset"
    let name = "Sunset"
    // ... all theme properties
}

// ThemeManager.swift
private let themes: [any AppTheme] = [
    PurpleTheme(),
    LightTheme(),
    DarkTheme(),
    EnergeticTheme(),
    CalmTheme(),
    SunsetTheme(),  // New shop theme
    VintageTheme()  // New shop theme
]

// MainTabView.swift
let sunsetTheme = Theme(
    id: "sunset",  // Must match AppTheme.id
    name: "Sunset",
    unlockMethod: .currency,
    currencyPrice: 500
)
```

This approach is:
- ✅ Type-safe
- ✅ Performant
- ✅ Maintainable
- ✅ Follows existing pattern

