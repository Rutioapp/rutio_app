# Shop Assets Catalog V1

## 1. Scope

This phase defines the initial cosmetic asset catalog for the Rutio shop. It is a product and technical specification only, with no Flutter implementation, runtime logic changes, asset generation, or asset registration included yet.

V1 includes the following cosmetic categories:

| Category | Internal ID |
| --- | --- |
| Wallpaper | `wallpaper` |
| Habit Card Skin | `habit_card` |
| User Card Skin | `user_card` |

The following items are explicitly out of scope for V1:

* complete profile skins
* avatar frames
* stickers
* animated assets
* per-habit individual skins
* advanced themes

## 2. Product Principles

The V1 asset catalog should follow these principles:

* calm, minimal and premium visual style
* iOS-first visual direction
* beige/camel base palette
* rarity should feel visual, not only numerical
* cosmetics should never reduce readability
* wallpapers apply globally to compatible screens
* habit cards apply globally to habit cards
* user cards apply to Home and any reused user card component
* profile screen customization is left for a later phase

## 3. Rarity System

| Rarity | Visual Color | Role | Visual Complexity |
| --- | --- | --- | --- |
| common | green | starter cosmetics | flat/simple |
| rare | blue | more refined cosmetics | subtle texture/abstract |
| epic | purple | stronger personality | medium composition |
| legendary | gold | premium/exclusive cosmetics | high visual detail |

### common

* flat colors
* clean starter assets
* minimal texture
* very accessible

### rare

* subtle textures
* soft abstract backgrounds
* refined but calm
* core Rutio visual identity

### epic

* more character
* more recognizable composition
* still calm and readable
* subtle lavender, terracotta, sage or dune-inspired accents

### legendary

* premium composition
* elegant golden/camel details
* more depth and texture
* never flashy or overloaded

## 4. Economy and Pricing

Reference assumption: a very active user can earn around 40-50 coins per day.

| Rarity | Individual Asset Price | Bundle Price | Approx. Days for Individual Asset | Approx. Days for Bundle |
| --- | ---: | ---: | ---: | ---: |
| common | 120 | 300 | 2-3 days | 6-8 days |
| rare | 250 | 650 | 5-6 days | 13-16 days |
| epic | 550 | 1400 | 11-14 days | 28-35 days |
| legendary | 1200 | 3000 | 24-30 days | 60-75 days |

This economy is reasonable because:

* common assets feel reachable early
* rare assets become small goals
* epic assets reward consistency
* legendary assets are long-term goals
* bundles include a discount but should not break progression

## 5. Asset Categories

| Category | Internal ID | Application |
| --- | --- | --- |
| Wallpaper | wallpaper | Global background for compatible screens |
| Habit Card Skin | habit_card | Global skin for habit cards |
| User Card Skin | user_card | Home and reused user card components |

In V1, only one skin can be equipped per category. The recommended state fields are:

* `equippedWallpaperId`
* `equippedHabitCardSkinId`
* `equippedUserCardSkinId`

## 6. Naming System

Recommended naming conventions:

* family id format: `snake_case`
* asset id format: `<category>_<family_id>`
* bundle id format: `bundle_<family_id>`

Examples:

* `wallpaper_calm_sand`
* `habit_card_calm_sand`
* `user_card_calm_sand`
* `bundle_calm_sand`

## 7. Visual Families V1

| Family ID | Name ES | Name EN | Rarity | Visual Description |
| --- | --- | --- | --- | --- |
| warm_beige | Beige cálido | Warm Beige | common | Flat warm beige, clean and easy to combine. |
| soft_camel | Camel suave | Soft Camel | common | Light camel tone, warmer and slightly richer. |
| sand_plain | Arena lisa | Plain Sand | common | Neutral sand color, sober and functional. |
| cream_light | Crema claro | Light Cream | common | Very light cream, bright and minimal. |
| calm_sand | Arena calma | Calm Sand | rare | Soft sand texture with a calm editorial feel. |
| soft_linen | Lino suave | Soft Linen | rare | Subtle linen or textile-paper texture. |
| paper_dawn | Amanecer de papel | Paper Dawn | rare | Warm soft gradient with paper-like depth. |
| lavender_mist | Niebla lavanda | Lavender Mist | epic | Beige base with soft lavender mist accents. |
| dune_layers | Capas de duna | Dune Layers | epic | Organic dune-like layers with subtle depth. |
| golden_dawn | Amanecer dorado | Golden Dawn | legendary | Premium warm composition with soft golden detail. |

## 8. Individual Asset Catalog

| Asset ID | Family ID | Category | Name ES | Name EN | Rarity | Price | Application |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| wallpaper_warm_beige | warm_beige | wallpaper | Fondo Beige cálido | Warm Beige Wallpaper | common | 120 | Global background |
| habit_card_warm_beige | warm_beige | habit_card | Card Beige cálido | Warm Beige Habit Card | common | 120 | Habit cards |
| user_card_warm_beige | warm_beige | user_card | Tarjeta Beige cálido | Warm Beige User Card | common | 120 | User card |
| wallpaper_soft_camel | soft_camel | wallpaper | Fondo Camel suave | Soft Camel Wallpaper | common | 120 | Global background |
| habit_card_soft_camel | soft_camel | habit_card | Card Camel suave | Soft Camel Habit Card | common | 120 | Habit cards |
| user_card_soft_camel | soft_camel | user_card | Tarjeta Camel suave | Soft Camel User Card | common | 120 | User card |
| wallpaper_sand_plain | sand_plain | wallpaper | Fondo Arena lisa | Plain Sand Wallpaper | common | 120 | Global background |
| habit_card_sand_plain | sand_plain | habit_card | Card Arena lisa | Plain Sand Habit Card | common | 120 | Habit cards |
| user_card_sand_plain | sand_plain | user_card | Tarjeta Arena lisa | Plain Sand User Card | common | 120 | User card |
| wallpaper_cream_light | cream_light | wallpaper | Fondo Crema claro | Light Cream Wallpaper | common | 120 | Global background |
| habit_card_cream_light | cream_light | habit_card | Card Crema claro | Light Cream Habit Card | common | 120 | Habit cards |
| user_card_cream_light | cream_light | user_card | Tarjeta Crema claro | Light Cream User Card | common | 120 | User card |
| wallpaper_calm_sand | calm_sand | wallpaper | Fondo Arena calma | Calm Sand Wallpaper | rare | 250 | Global background |
| habit_card_calm_sand | calm_sand | habit_card | Card Arena calma | Calm Sand Habit Card | rare | 250 | Habit cards |
| user_card_calm_sand | calm_sand | user_card | Tarjeta Arena calma | Calm Sand User Card | rare | 250 | User card |
| wallpaper_soft_linen | soft_linen | wallpaper | Fondo Lino suave | Soft Linen Wallpaper | rare | 250 | Global background |
| habit_card_soft_linen | soft_linen | habit_card | Card Lino suave | Soft Linen Habit Card | rare | 250 | Habit cards |
| user_card_soft_linen | soft_linen | user_card | Tarjeta Lino suave | Soft Linen User Card | rare | 250 | User card |
| wallpaper_paper_dawn | paper_dawn | wallpaper | Fondo Amanecer de papel | Paper Dawn Wallpaper | rare | 250 | Global background |
| habit_card_paper_dawn | paper_dawn | habit_card | Card Amanecer de papel | Paper Dawn Habit Card | rare | 250 | Habit cards |
| user_card_paper_dawn | paper_dawn | user_card | Tarjeta Amanecer de papel | Paper Dawn User Card | rare | 250 | User card |
| wallpaper_lavender_mist | lavender_mist | wallpaper | Fondo Niebla lavanda | Lavender Mist Wallpaper | epic | 550 | Global background |
| habit_card_lavender_mist | lavender_mist | habit_card | Card Niebla lavanda | Lavender Mist Habit Card | epic | 550 | Habit cards |
| user_card_lavender_mist | lavender_mist | user_card | Tarjeta Niebla lavanda | Lavender Mist User Card | epic | 550 | User card |
| wallpaper_dune_layers | dune_layers | wallpaper | Fondo Capas de duna | Dune Layers Wallpaper | epic | 550 | Global background |
| habit_card_dune_layers | dune_layers | habit_card | Card Capas de duna | Dune Layers Habit Card | epic | 550 | Habit cards |
| user_card_dune_layers | dune_layers | user_card | Tarjeta Capas de duna | Dune Layers User Card | epic | 550 | User card |
| wallpaper_golden_dawn | golden_dawn | wallpaper | Fondo Amanecer dorado | Golden Dawn Wallpaper | legendary | 1200 | Global background |
| habit_card_golden_dawn | golden_dawn | habit_card | Card Amanecer dorado | Golden Dawn Habit Card | legendary | 1200 | Habit cards |
| user_card_golden_dawn | golden_dawn | user_card | Tarjeta Amanecer dorado | Golden Dawn User Card | legendary | 1200 | User card |

## 9. Bundle Catalog

| Bundle ID | Family ID | Name ES | Name EN | Rarity | Price | Included Asset IDs |
| --- | --- | --- | --- | --- | ---: | --- |
| bundle_warm_beige | warm_beige | Pack Beige cálido | Warm Beige Bundle | common | 300 | `wallpaper_warm_beige`, `habit_card_warm_beige`, `user_card_warm_beige` |
| bundle_soft_camel | soft_camel | Pack Camel suave | Soft Camel Bundle | common | 300 | `wallpaper_soft_camel`, `habit_card_soft_camel`, `user_card_soft_camel` |
| bundle_sand_plain | sand_plain | Pack Arena lisa | Plain Sand Bundle | common | 300 | `wallpaper_sand_plain`, `habit_card_sand_plain`, `user_card_sand_plain` |
| bundle_cream_light | cream_light | Pack Crema claro | Light Cream Bundle | common | 300 | `wallpaper_cream_light`, `habit_card_cream_light`, `user_card_cream_light` |
| bundle_calm_sand | calm_sand | Pack Arena calma | Calm Sand Bundle | rare | 650 | `wallpaper_calm_sand`, `habit_card_calm_sand`, `user_card_calm_sand` |
| bundle_soft_linen | soft_linen | Pack Lino suave | Soft Linen Bundle | rare | 650 | `wallpaper_soft_linen`, `habit_card_soft_linen`, `user_card_soft_linen` |
| bundle_paper_dawn | paper_dawn | Pack Amanecer de papel | Paper Dawn Bundle | rare | 650 | `wallpaper_paper_dawn`, `habit_card_paper_dawn`, `user_card_paper_dawn` |
| bundle_lavender_mist | lavender_mist | Pack Niebla lavanda | Lavender Mist Bundle | epic | 1400 | `wallpaper_lavender_mist`, `habit_card_lavender_mist`, `user_card_lavender_mist` |
| bundle_dune_layers | dune_layers | Pack Capas de duna | Dune Layers Bundle | epic | 1400 | `wallpaper_dune_layers`, `habit_card_dune_layers`, `user_card_dune_layers` |
| bundle_golden_dawn | golden_dawn | Pack Amanecer dorado | Golden Dawn Bundle | legendary | 3000 | `wallpaper_golden_dawn`, `habit_card_golden_dawn`, `user_card_golden_dawn` |

## 10. Recommended Asset Paths

The following file structure is recommended for later implementation, but no files or folders should be created yet in this phase:

* `assets/shop/wallpapers/<rarity>/<asset_id>.webp`
* `assets/shop/habit_cards/<rarity>/<asset_id>.webp`
* `assets/shop/user_cards/<rarity>/<asset_id>.webp`

Examples:

* `assets/shop/wallpapers/common/wallpaper_warm_beige.webp`
* `assets/shop/wallpapers/rare/wallpaper_calm_sand.webp`
* `assets/shop/habit_cards/epic/habit_card_lavender_mist.webp`
* `assets/shop/user_cards/legendary/user_card_golden_dawn.webp`

In V1, `previewAssetPath` can be equal to `assetPath` to reduce complexity.

## 11. Store Ordering

Recommended tabs for V1:

* All
* Wallpapers
* Cards
* Packs

Recommended internal order:

1. common
2. rare
3. epic
4. legendary

Within each rarity, the recommended order is:

1. wallpaper
2. habit_card
3. user_card
4. bundle

## 12. Ownership and Equipment Rules

Recommended asset states:

* `locked`
* `owned`
* `equipped`
* `includedInOwnedBundle`

Rules:

* Only one wallpaper can be equipped at a time.
* Only one habit card skin can be equipped at a time.
* Only one user card skin can be equipped at a time.
* Buying a bundle unlocks all included assets.
* Bundles should not be equipable directly; only individual assets are equipped.
* If an equipped asset is replaced, the previous one remains owned.

## 13. Future Phases

Future phases may include:

* generate visual prompts for each family
* create actual WebP assets
* add pubspec asset declarations
* implement ShopAsset model
* implement ShopBundle model
* implement local catalog
* implement purchase flow
* implement equip flow
* apply wallpapers globally
* apply habit card skins
* apply user card skins
* add tests for catalog integrity, purchase, ownership and equipment

## 14. Implementation Notes for Later

This document is intentionally product-first and implementation-ready, but it should not introduce runtime behavior yet.

## Temporary Placeholder Note

The current assets integrated during Phase 4.3 are temporary placeholder files meant to validate Flutter asset loading and shop integration flows.

These placeholders should be replaced in a later phase by final exported assets generated from:

* `docs/shop-assets-generation-prompts-v1.md`
