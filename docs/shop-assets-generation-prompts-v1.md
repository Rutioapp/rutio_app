# Shop Assets Generation Prompts V1

## 1. Purpose

This document defines reusable visual prompts for generating the V1 cosmetic assets of the Rutio shop.

It is based on:

* `docs/shop-assets-catalog-v1.md`

The asset types defined here are:

* wallpapers
* habit card skins
* user card skins

The visual families covered in this document are:

* `warm_beige`
* `soft_camel`
* `sand_plain`
* `cream_light`
* `calm_sand`
* `soft_linen`
* `paper_dawn`
* `lavender_mist`
* `dune_layers`
* `golden_dawn`

## 2. Global Rutio Visual Direction

Global style direction:

* calm
* minimal
* premium
* iOS-first
* beige/camel base palette
* soft warm neutrals
* subtle depth
* editorial wellness aesthetic
* readable behind mobile UI
* no text
* no logos
* no characters
* no objects unless explicitly required
* no strong contrast
* no harsh shadows
* no cartoon style
* no childish visual language
* no busy patterns

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio.

The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects.

The result must work inside a mobile app interface and must never reduce readability.
```

## 3. Rarity Prompt Rules

### Common / Green

Common assets should feel:

* flat colors
* very simple
* minimal or no texture
* starter cosmetic
* clean and accessible

```text
Rarity: Common.

Create a very simple, flat and clean cosmetic asset. Use a warm neutral color from the Rutio palette. Keep the design minimal, accessible and functional. Use little to no texture. The result should feel like a calm starter cosmetic, not a decorative illustration.
```

### Rare / Blue

Rare assets should feel:

* subtle texture
* light abstract feel
* refined
* core Rutio identity

```text
Rarity: Rare.

Create a refined minimal cosmetic asset with subtle texture or soft abstract depth. Keep the composition calm and elegant. Use warm beige, camel, cream, sand or paper-like tones. The asset should feel more polished than a flat color, but still quiet and highly readable.
```

### Epic / Purple

Epic assets should feel:

* more personality
* recognizable composition
* still calm
* subtle accents

```text
Rarity: Epic.

Create a cosmetic asset with more visual personality and a recognizable abstract composition. Keep it calm, premium and readable. Use soft warm neutrals with restrained accents such as lavender, terracotta, sage or dune-inspired tones. Avoid visual noise and avoid making it look like a decorative poster.
```

### Legendary / Gold

Legendary assets should feel:

* premium
* more detail
* more depth
* elegant golden/camel details
* not flashy

```text
Rarity: Legendary.

Create a premium and highly polished cosmetic asset with elegant depth, refined texture and soft golden or camel details. The asset should feel exclusive and carefully crafted, but never flashy, shiny, overloaded or luxurious in a casino-like way. Maintain the calm Rutio identity.
```

## 4. Category Prompt Rules

### Wallpaper Prompts

Wallpaper rules:

* vertical mobile background
* must work behind UI cards
* safe empty center area
* subtle composition
* no text
* no icons
* no objects
* recommended aspect ratio: vertical mobile, 1536x2048 or equivalent

```text
Create a vertical mobile wallpaper background for a calm premium habit tracking app.

The image must work behind white, cream and beige UI cards. Keep the center visually quiet with enough empty space for interface elements. Use subtle depth, soft texture and calm warm tones. Do not include text, logos, icons, characters, objects or strong patterns.

Recommended output: vertical mobile background, high resolution, 1536x2048 or equivalent.
```

### Habit Card Skin Prompts

Habit card skin rules:

* rectangular UI card skin
* must be readable
* should work behind text, emoji and progress indicators
* rounded rectangle composition
* subtle borders/shadows allowed
* transparent background preferred if possible
* recommended ratio: card-like horizontal/rectangular

```text
Create a premium minimal habit card skin for a mobile habit tracking app.

The design should work as the background of a rounded rectangular card containing habit text, emoji, progress indicators and small metadata. Keep contrast soft and readability high. Use subtle texture, gentle borders or very soft depth if needed. Avoid busy patterns, strong gradients, text, icons, characters or objects.

Recommended output: clean rounded rectangular card-style asset with transparent or neutral background.
```

### User Card Skin Prompts

User card skin rules:

* larger summary card
* for Home user card
* must support avatar/level/progress/stats
* slightly more personality than habit card, but still clean
* transparent background preferred if possible

```text
Create a premium minimal user summary card skin for a calm mobile habit tracking app.

The card should feel slightly more special than a standard habit card, while remaining clean and highly readable. It must support UI elements such as avatar, level, progress, coins and short stats. Use soft warm tones, subtle depth and refined texture. Avoid visual clutter, text, icons, characters, objects or strong decorative patterns.

Recommended output: clean rounded rectangular user card-style asset with transparent or neutral background.
```

## 5. Family-Specific Prompt Modifiers

| Family ID | Rarity | Visual Intent | Prompt Modifier |
| --- | --- | --- | --- |
| warm_beige | common | flat warm beige starter family | Use a flat warm beige tone, clean and simple, with almost no texture. The result should feel soft, accessible and neutral. |
| soft_camel | common | flat light camel starter family | Use a soft light camel tone, slightly warmer and richer than beige. Keep the design flat, minimal and clean. |
| sand_plain | common | neutral flat sand family | Use a neutral plain sand tone. Keep the asset sober, balanced and highly functional, with no visible decorative elements. |
| cream_light | common | bright light cream starter family | Use a very light cream tone, bright and airy. Keep the design minimal, clean and calm, with excellent readability. |
| calm_sand | rare | soft sand texture | Use warm sand tones with a subtle natural paper or sand-like texture. The asset should feel calm, soft and editorial. |
| soft_linen | rare | subtle linen/paper textile texture | Use a soft linen or textile-paper texture with warm cream and beige tones. Keep the texture subtle and refined. |
| paper_dawn | rare | warm paper-like dawn gradient | Use a warm dawn-inspired gradient with paper-like softness. Blend cream, beige, peach and camel tones gently, with no strong contrast. |
| lavender_mist | epic | beige base with soft lavender mist | Use a beige and cream base with soft lavender mist accents. The composition should feel atmospheric, calm and slightly more distinctive. |
| dune_layers | epic | organic dune-like layered composition | Create subtle organic dune-like layers using warm sand, beige, camel and soft terracotta tones. Add gentle depth while keeping the interface readable. |
| golden_dawn | legendary | premium warm golden dawn composition | Create a premium warm dawn composition with soft golden, camel, cream and sand tones. Use refined texture and elegant depth. Avoid shiny metallic gold or flashy luxury effects. |

## 6. Complete Wallpaper Prompts

### wallpaper_warm_beige

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Common. Create a very simple, flat and clean cosmetic asset. Use a warm neutral color from the Rutio palette. Keep the design minimal, accessible and functional. Use little to no texture. The result should feel like a calm starter cosmetic, not a decorative illustration.

Create a vertical mobile wallpaper background for a calm premium habit tracking app. The image must work behind white, cream and beige UI cards. Keep the center visually quiet with enough empty space for interface elements. Use subtle depth, soft texture and calm warm tones. Do not include text, logos, icons, characters, objects or strong patterns.

Use a flat warm beige tone, clean and simple, with almost no texture. The result should feel soft, accessible and neutral.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: vertical mobile background, high resolution, 1536x2048 or equivalent.

Asset ID: wallpaper_warm_beige
Family: warm_beige
Rarity: Common
```

### wallpaper_soft_camel

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Common. Create a very simple, flat and clean cosmetic asset. Use a warm neutral color from the Rutio palette. Keep the design minimal, accessible and functional. Use little to no texture. The result should feel like a calm starter cosmetic, not a decorative illustration.

Create a vertical mobile wallpaper background for a calm premium habit tracking app. The image must work behind white, cream and beige UI cards. Keep the center visually quiet with enough empty space for interface elements. Use subtle depth, soft texture and calm warm tones. Do not include text, logos, icons, characters, objects or strong patterns.

Use a soft light camel tone, slightly warmer and richer than beige. Keep the design flat, minimal and clean.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: vertical mobile background, high resolution, 1536x2048 or equivalent.

Asset ID: wallpaper_soft_camel
Family: soft_camel
Rarity: Common
```

### wallpaper_sand_plain

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Common. Create a very simple, flat and clean cosmetic asset. Use a warm neutral color from the Rutio palette. Keep the design minimal, accessible and functional. Use little to no texture. The result should feel like a calm starter cosmetic, not a decorative illustration.

Create a vertical mobile wallpaper background for a calm premium habit tracking app. The image must work behind white, cream and beige UI cards. Keep the center visually quiet with enough empty space for interface elements. Use subtle depth, soft texture and calm warm tones. Do not include text, logos, icons, characters, objects or strong patterns.

Use a neutral plain sand tone. Keep the asset sober, balanced and highly functional, with no visible decorative elements.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: vertical mobile background, high resolution, 1536x2048 or equivalent.

Asset ID: wallpaper_sand_plain
Family: sand_plain
Rarity: Common
```

### wallpaper_cream_light

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Common. Create a very simple, flat and clean cosmetic asset. Use a warm neutral color from the Rutio palette. Keep the design minimal, accessible and functional. Use little to no texture. The result should feel like a calm starter cosmetic, not a decorative illustration.

Create a vertical mobile wallpaper background for a calm premium habit tracking app. The image must work behind white, cream and beige UI cards. Keep the center visually quiet with enough empty space for interface elements. Use subtle depth, soft texture and calm warm tones. Do not include text, logos, icons, characters, objects or strong patterns.

Use a very light cream tone, bright and airy. Keep the design minimal, clean and calm, with excellent readability.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: vertical mobile background, high resolution, 1536x2048 or equivalent.

Asset ID: wallpaper_cream_light
Family: cream_light
Rarity: Common
```

### wallpaper_calm_sand

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Rare. Create a refined minimal cosmetic asset with subtle texture or soft abstract depth. Keep the composition calm and elegant. Use warm beige, camel, cream, sand or paper-like tones. The asset should feel more polished than a flat color, but still quiet and highly readable.

Create a vertical mobile wallpaper background for a calm premium habit tracking app. The image must work behind white, cream and beige UI cards. Keep the center visually quiet with enough empty space for interface elements. Use subtle depth, soft texture and calm warm tones. Do not include text, logos, icons, characters, objects or strong patterns.

Use warm sand tones with a subtle natural paper or sand-like texture. The asset should feel calm, soft and editorial.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: vertical mobile background, high resolution, 1536x2048 or equivalent.

Asset ID: wallpaper_calm_sand
Family: calm_sand
Rarity: Rare
```

### wallpaper_soft_linen

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Rare. Create a refined minimal cosmetic asset with subtle texture or soft abstract depth. Keep the composition calm and elegant. Use warm beige, camel, cream, sand or paper-like tones. The asset should feel more polished than a flat color, but still quiet and highly readable.

Create a vertical mobile wallpaper background for a calm premium habit tracking app. The image must work behind white, cream and beige UI cards. Keep the center visually quiet with enough empty space for interface elements. Use subtle depth, soft texture and calm warm tones. Do not include text, logos, icons, characters, objects or strong patterns.

Use a soft linen or textile-paper texture with warm cream and beige tones. Keep the texture subtle and refined.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: vertical mobile background, high resolution, 1536x2048 or equivalent.

Asset ID: wallpaper_soft_linen
Family: soft_linen
Rarity: Rare
```

### wallpaper_paper_dawn

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Rare. Create a refined minimal cosmetic asset with subtle texture or soft abstract depth. Keep the composition calm and elegant. Use warm beige, camel, cream, sand or paper-like tones. The asset should feel more polished than a flat color, but still quiet and highly readable.

Create a vertical mobile wallpaper background for a calm premium habit tracking app. The image must work behind white, cream and beige UI cards. Keep the center visually quiet with enough empty space for interface elements. Use subtle depth, soft texture and calm warm tones. Do not include text, logos, icons, characters, objects or strong patterns.

Use a warm dawn-inspired gradient with paper-like softness. Blend cream, beige, peach and camel tones gently, with no strong contrast.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: vertical mobile background, high resolution, 1536x2048 or equivalent.

Asset ID: wallpaper_paper_dawn
Family: paper_dawn
Rarity: Rare
```

### wallpaper_lavender_mist

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Epic. Create a cosmetic asset with more visual personality and a recognizable abstract composition. Keep it calm, premium and readable. Use soft warm neutrals with restrained accents such as lavender, terracotta, sage or dune-inspired tones. Avoid visual noise and avoid making it look like a decorative poster.

Create a vertical mobile wallpaper background for a calm premium habit tracking app. The image must work behind white, cream and beige UI cards. Keep the center visually quiet with enough empty space for interface elements. Use subtle depth, soft texture and calm warm tones. Do not include text, logos, icons, characters, objects or strong patterns.

Use a beige and cream base with soft lavender mist accents. The composition should feel atmospheric, calm and slightly more distinctive.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: vertical mobile background, high resolution, 1536x2048 or equivalent.

Asset ID: wallpaper_lavender_mist
Family: lavender_mist
Rarity: Epic
```

### wallpaper_dune_layers

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Epic. Create a cosmetic asset with more visual personality and a recognizable abstract composition. Keep it calm, premium and readable. Use soft warm neutrals with restrained accents such as lavender, terracotta, sage or dune-inspired tones. Avoid visual noise and avoid making it look like a decorative poster.

Create a vertical mobile wallpaper background for a calm premium habit tracking app. The image must work behind white, cream and beige UI cards. Keep the center visually quiet with enough empty space for interface elements. Use subtle depth, soft texture and calm warm tones. Do not include text, logos, icons, characters, objects or strong patterns.

Create subtle organic dune-like layers using warm sand, beige, camel and soft terracotta tones. Add gentle depth while keeping the interface readable.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: vertical mobile background, high resolution, 1536x2048 or equivalent.

Asset ID: wallpaper_dune_layers
Family: dune_layers
Rarity: Epic
```

### wallpaper_golden_dawn

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Legendary. Create a premium and highly polished cosmetic asset with elegant depth, refined texture and soft golden or camel details. The asset should feel exclusive and carefully crafted, but never flashy, shiny, overloaded or luxurious in a casino-like way. Maintain the calm Rutio identity.

Create a vertical mobile wallpaper background for a calm premium habit tracking app. The image must work behind white, cream and beige UI cards. Keep the center visually quiet with enough empty space for interface elements. Use subtle depth, soft texture and calm warm tones. Do not include text, logos, icons, characters, objects or strong patterns.

Create a premium warm dawn composition with soft golden, camel, cream and sand tones. Use refined texture and elegant depth. Avoid shiny metallic gold or flashy luxury effects.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: vertical mobile background, high resolution, 1536x2048 or equivalent.

Asset ID: wallpaper_golden_dawn
Family: golden_dawn
Rarity: Legendary
```

## 7. Complete Habit Card Skin Prompts

### habit_card_warm_beige

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Common. Create a very simple, flat and clean cosmetic asset. Use a warm neutral color from the Rutio palette. Keep the design minimal, accessible and functional. Use little to no texture. The result should feel like a calm starter cosmetic, not a decorative illustration.

Create a premium minimal habit card skin for a mobile habit tracking app. The design should work as the background of a rounded rectangular card containing habit text, emoji, progress indicators and small metadata. Keep contrast soft and readability high. Use subtle texture, gentle borders or very soft depth if needed. Avoid busy patterns, strong gradients, text, icons, characters or objects.

Use a flat warm beige tone, clean and simple, with almost no texture. The result should feel soft, accessible and neutral.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular card-style asset with transparent or neutral background.

Asset ID: habit_card_warm_beige
Family: warm_beige
Rarity: Common
```

### habit_card_soft_camel

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Common. Create a very simple, flat and clean cosmetic asset. Use a warm neutral color from the Rutio palette. Keep the design minimal, accessible and functional. Use little to no texture. The result should feel like a calm starter cosmetic, not a decorative illustration.

Create a premium minimal habit card skin for a mobile habit tracking app. The design should work as the background of a rounded rectangular card containing habit text, emoji, progress indicators and small metadata. Keep contrast soft and readability high. Use subtle texture, gentle borders or very soft depth if needed. Avoid busy patterns, strong gradients, text, icons, characters or objects.

Use a soft light camel tone, slightly warmer and richer than beige. Keep the design flat, minimal and clean.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular card-style asset with transparent or neutral background.

Asset ID: habit_card_soft_camel
Family: soft_camel
Rarity: Common
```

### habit_card_sand_plain

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Common. Create a very simple, flat and clean cosmetic asset. Use a warm neutral color from the Rutio palette. Keep the design minimal, accessible and functional. Use little to no texture. The result should feel like a calm starter cosmetic, not a decorative illustration.

Create a premium minimal habit card skin for a mobile habit tracking app. The design should work as the background of a rounded rectangular card containing habit text, emoji, progress indicators and small metadata. Keep contrast soft and readability high. Use subtle texture, gentle borders or very soft depth if needed. Avoid busy patterns, strong gradients, text, icons, characters or objects.

Use a neutral plain sand tone. Keep the asset sober, balanced and highly functional, with no visible decorative elements.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular card-style asset with transparent or neutral background.

Asset ID: habit_card_sand_plain
Family: sand_plain
Rarity: Common
```

### habit_card_cream_light

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Common. Create a very simple, flat and clean cosmetic asset. Use a warm neutral color from the Rutio palette. Keep the design minimal, accessible and functional. Use little to no texture. The result should feel like a calm starter cosmetic, not a decorative illustration.

Create a premium minimal habit card skin for a mobile habit tracking app. The design should work as the background of a rounded rectangular card containing habit text, emoji, progress indicators and small metadata. Keep contrast soft and readability high. Use subtle texture, gentle borders or very soft depth if needed. Avoid busy patterns, strong gradients, text, icons, characters or objects.

Use a very light cream tone, bright and airy. Keep the design minimal, clean and calm, with excellent readability.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular card-style asset with transparent or neutral background.

Asset ID: habit_card_cream_light
Family: cream_light
Rarity: Common
```

### habit_card_calm_sand

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Rare. Create a refined minimal cosmetic asset with subtle texture or soft abstract depth. Keep the composition calm and elegant. Use warm beige, camel, cream, sand or paper-like tones. The asset should feel more polished than a flat color, but still quiet and highly readable.

Create a premium minimal habit card skin for a mobile habit tracking app. The design should work as the background of a rounded rectangular card containing habit text, emoji, progress indicators and small metadata. Keep contrast soft and readability high. Use subtle texture, gentle borders or very soft depth if needed. Avoid busy patterns, strong gradients, text, icons, characters or objects.

Use warm sand tones with a subtle natural paper or sand-like texture. The asset should feel calm, soft and editorial.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular card-style asset with transparent or neutral background.

Asset ID: habit_card_calm_sand
Family: calm_sand
Rarity: Rare
```

### habit_card_soft_linen

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Rare. Create a refined minimal cosmetic asset with subtle texture or soft abstract depth. Keep the composition calm and elegant. Use warm beige, camel, cream, sand or paper-like tones. The asset should feel more polished than a flat color, but still quiet and highly readable.

Create a premium minimal habit card skin for a mobile habit tracking app. The design should work as the background of a rounded rectangular card containing habit text, emoji, progress indicators and small metadata. Keep contrast soft and readability high. Use subtle texture, gentle borders or very soft depth if needed. Avoid busy patterns, strong gradients, text, icons, characters or objects.

Use a soft linen or textile-paper texture with warm cream and beige tones. Keep the texture subtle and refined.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular card-style asset with transparent or neutral background.

Asset ID: habit_card_soft_linen
Family: soft_linen
Rarity: Rare
```

### habit_card_paper_dawn

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Rare. Create a refined minimal cosmetic asset with subtle texture or soft abstract depth. Keep the composition calm and elegant. Use warm beige, camel, cream, sand or paper-like tones. The asset should feel more polished than a flat color, but still quiet and highly readable.

Create a premium minimal habit card skin for a mobile habit tracking app. The design should work as the background of a rounded rectangular card containing habit text, emoji, progress indicators and small metadata. Keep contrast soft and readability high. Use subtle texture, gentle borders or very soft depth if needed. Avoid busy patterns, strong gradients, text, icons, characters or objects.

Use a warm dawn-inspired gradient with paper-like softness. Blend cream, beige, peach and camel tones gently, with no strong contrast.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular card-style asset with transparent or neutral background.

Asset ID: habit_card_paper_dawn
Family: paper_dawn
Rarity: Rare
```

### habit_card_lavender_mist

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Epic. Create a cosmetic asset with more visual personality and a recognizable abstract composition. Keep it calm, premium and readable. Use soft warm neutrals with restrained accents such as lavender, terracotta, sage or dune-inspired tones. Avoid visual noise and avoid making it look like a decorative poster.

Create a premium minimal habit card skin for a mobile habit tracking app. The design should work as the background of a rounded rectangular card containing habit text, emoji, progress indicators and small metadata. Keep contrast soft and readability high. Use subtle texture, gentle borders or very soft depth if needed. Avoid busy patterns, strong gradients, text, icons, characters or objects.

Use a beige and cream base with soft lavender mist accents. The composition should feel atmospheric, calm and slightly more distinctive.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular card-style asset with transparent or neutral background.

Asset ID: habit_card_lavender_mist
Family: lavender_mist
Rarity: Epic
```

### habit_card_dune_layers

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Epic. Create a cosmetic asset with more visual personality and a recognizable abstract composition. Keep it calm, premium and readable. Use soft warm neutrals with restrained accents such as lavender, terracotta, sage or dune-inspired tones. Avoid visual noise and avoid making it look like a decorative poster.

Create a premium minimal habit card skin for a mobile habit tracking app. The design should work as the background of a rounded rectangular card containing habit text, emoji, progress indicators and small metadata. Keep contrast soft and readability high. Use subtle texture, gentle borders or very soft depth if needed. Avoid busy patterns, strong gradients, text, icons, characters or objects.

Create subtle organic dune-like layers using warm sand, beige, camel and soft terracotta tones. Add gentle depth while keeping the interface readable.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular card-style asset with transparent or neutral background.

Asset ID: habit_card_dune_layers
Family: dune_layers
Rarity: Epic
```

### habit_card_golden_dawn

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Legendary. Create a premium and highly polished cosmetic asset with elegant depth, refined texture and soft golden or camel details. The asset should feel exclusive and carefully crafted, but never flashy, shiny, overloaded or luxurious in a casino-like way. Maintain the calm Rutio identity.

Create a premium minimal habit card skin for a mobile habit tracking app. The design should work as the background of a rounded rectangular card containing habit text, emoji, progress indicators and small metadata. Keep contrast soft and readability high. Use subtle texture, gentle borders or very soft depth if needed. Avoid busy patterns, strong gradients, text, icons, characters or objects.

Create a premium warm dawn composition with soft golden, camel, cream and sand tones. Use refined texture and elegant depth. Avoid shiny metallic gold or flashy luxury effects.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular card-style asset with transparent or neutral background.

Asset ID: habit_card_golden_dawn
Family: golden_dawn
Rarity: Legendary
```

## 8. Complete User Card Skin Prompts

### user_card_warm_beige

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Common. Create a very simple, flat and clean cosmetic asset. Use a warm neutral color from the Rutio palette. Keep the design minimal, accessible and functional. Use little to no texture. The result should feel like a calm starter cosmetic, not a decorative illustration.

Create a premium minimal user summary card skin for a calm mobile habit tracking app. The card should feel slightly more special than a standard habit card, while remaining clean and highly readable. It must support UI elements such as avatar, level, progress, coins and short stats. Use soft warm tones, subtle depth and refined texture. Avoid visual clutter, text, icons, characters, objects or strong decorative patterns.

Use a flat warm beige tone, clean and simple, with almost no texture. The result should feel soft, accessible and neutral.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular user card-style asset with transparent or neutral background.

Asset ID: user_card_warm_beige
Family: warm_beige
Rarity: Common
```

### user_card_soft_camel

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Common. Create a very simple, flat and clean cosmetic asset. Use a warm neutral color from the Rutio palette. Keep the design minimal, accessible and functional. Use little to no texture. The result should feel like a calm starter cosmetic, not a decorative illustration.

Create a premium minimal user summary card skin for a calm mobile habit tracking app. The card should feel slightly more special than a standard habit card, while remaining clean and highly readable. It must support UI elements such as avatar, level, progress, coins and short stats. Use soft warm tones, subtle depth and refined texture. Avoid visual clutter, text, icons, characters, objects or strong decorative patterns.

Use a soft light camel tone, slightly warmer and richer than beige. Keep the design flat, minimal and clean.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular user card-style asset with transparent or neutral background.

Asset ID: user_card_soft_camel
Family: soft_camel
Rarity: Common
```

### user_card_sand_plain

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Common. Create a very simple, flat and clean cosmetic asset. Use a warm neutral color from the Rutio palette. Keep the design minimal, accessible and functional. Use little to no texture. The result should feel like a calm starter cosmetic, not a decorative illustration.

Create a premium minimal user summary card skin for a calm mobile habit tracking app. The card should feel slightly more special than a standard habit card, while remaining clean and highly readable. It must support UI elements such as avatar, level, progress, coins and short stats. Use soft warm tones, subtle depth and refined texture. Avoid visual clutter, text, icons, characters, objects or strong decorative patterns.

Use a neutral plain sand tone. Keep the asset sober, balanced and highly functional, with no visible decorative elements.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular user card-style asset with transparent or neutral background.

Asset ID: user_card_sand_plain
Family: sand_plain
Rarity: Common
```

### user_card_cream_light

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Common. Create a very simple, flat and clean cosmetic asset. Use a warm neutral color from the Rutio palette. Keep the design minimal, accessible and functional. Use little to no texture. The result should feel like a calm starter cosmetic, not a decorative illustration.

Create a premium minimal user summary card skin for a calm mobile habit tracking app. The card should feel slightly more special than a standard habit card, while remaining clean and highly readable. It must support UI elements such as avatar, level, progress, coins and short stats. Use soft warm tones, subtle depth and refined texture. Avoid visual clutter, text, icons, characters, objects or strong decorative patterns.

Use a very light cream tone, bright and airy. Keep the design minimal, clean and calm, with excellent readability.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular user card-style asset with transparent or neutral background.

Asset ID: user_card_cream_light
Family: cream_light
Rarity: Common
```

### user_card_calm_sand

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Rare. Create a refined minimal cosmetic asset with subtle texture or soft abstract depth. Keep the composition calm and elegant. Use warm beige, camel, cream, sand or paper-like tones. The asset should feel more polished than a flat color, but still quiet and highly readable.

Create a premium minimal user summary card skin for a calm mobile habit tracking app. The card should feel slightly more special than a standard habit card, while remaining clean and highly readable. It must support UI elements such as avatar, level, progress, coins and short stats. Use soft warm tones, subtle depth and refined texture. Avoid visual clutter, text, icons, characters, objects or strong decorative patterns.

Use warm sand tones with a subtle natural paper or sand-like texture. The asset should feel calm, soft and editorial.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular user card-style asset with transparent or neutral background.

Asset ID: user_card_calm_sand
Family: calm_sand
Rarity: Rare
```

### user_card_soft_linen

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Rare. Create a refined minimal cosmetic asset with subtle texture or soft abstract depth. Keep the composition calm and elegant. Use warm beige, camel, cream, sand or paper-like tones. The asset should feel more polished than a flat color, but still quiet and highly readable.

Create a premium minimal user summary card skin for a calm mobile habit tracking app. The card should feel slightly more special than a standard habit card, while remaining clean and highly readable. It must support UI elements such as avatar, level, progress, coins and short stats. Use soft warm tones, subtle depth and refined texture. Avoid visual clutter, text, icons, characters, objects or strong decorative patterns.

Use a soft linen or textile-paper texture with warm cream and beige tones. Keep the texture subtle and refined.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular user card-style asset with transparent or neutral background.

Asset ID: user_card_soft_linen
Family: soft_linen
Rarity: Rare
```

### user_card_paper_dawn

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Rare. Create a refined minimal cosmetic asset with subtle texture or soft abstract depth. Keep the composition calm and elegant. Use warm beige, camel, cream, sand or paper-like tones. The asset should feel more polished than a flat color, but still quiet and highly readable.

Create a premium minimal user summary card skin for a calm mobile habit tracking app. The card should feel slightly more special than a standard habit card, while remaining clean and highly readable. It must support UI elements such as avatar, level, progress, coins and short stats. Use soft warm tones, subtle depth and refined texture. Avoid visual clutter, text, icons, characters, objects or strong decorative patterns.

Use a warm dawn-inspired gradient with paper-like softness. Blend cream, beige, peach and camel tones gently, with no strong contrast.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular user card-style asset with transparent or neutral background.

Asset ID: user_card_paper_dawn
Family: paper_dawn
Rarity: Rare
```

### user_card_lavender_mist

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Epic. Create a cosmetic asset with more visual personality and a recognizable abstract composition. Keep it calm, premium and readable. Use soft warm neutrals with restrained accents such as lavender, terracotta, sage or dune-inspired tones. Avoid visual noise and avoid making it look like a decorative poster.

Create a premium minimal user summary card skin for a calm mobile habit tracking app. The card should feel slightly more special than a standard habit card, while remaining clean and highly readable. It must support UI elements such as avatar, level, progress, coins and short stats. Use soft warm tones, subtle depth and refined texture. Avoid visual clutter, text, icons, characters, objects or strong decorative patterns.

Use a beige and cream base with soft lavender mist accents. The composition should feel atmospheric, calm and slightly more distinctive.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular user card-style asset with transparent or neutral background.

Asset ID: user_card_lavender_mist
Family: lavender_mist
Rarity: Epic
```

### user_card_dune_layers

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Epic. Create a cosmetic asset with more visual personality and a recognizable abstract composition. Keep it calm, premium and readable. Use soft warm neutrals with restrained accents such as lavender, terracotta, sage or dune-inspired tones. Avoid visual noise and avoid making it look like a decorative poster.

Create a premium minimal user summary card skin for a calm mobile habit tracking app. The card should feel slightly more special than a standard habit card, while remaining clean and highly readable. It must support UI elements such as avatar, level, progress, coins and short stats. Use soft warm tones, subtle depth and refined texture. Avoid visual clutter, text, icons, characters, objects or strong decorative patterns.

Create subtle organic dune-like layers using warm sand, beige, camel and soft terracotta tones. Add gentle depth while keeping the interface readable.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular user card-style asset with transparent or neutral background.

Asset ID: user_card_dune_layers
Family: dune_layers
Rarity: Epic
```

### user_card_golden_dawn

```text
Create a premium minimal visual asset for a calm habit tracking mobile app called Rutio. The visual direction is calm, warm, elegant, iOS-first and editorial. Use a beige, camel, cream and soft sand color palette with subtle natural depth. The asset must feel modern, clean, premium and emotionally quiet.

Rarity: Legendary. Create a premium and highly polished cosmetic asset with elegant depth, refined texture and soft golden or camel details. The asset should feel exclusive and carefully crafted, but never flashy, shiny, overloaded or luxurious in a casino-like way. Maintain the calm Rutio identity.

Create a premium minimal user summary card skin for a calm mobile habit tracking app. The card should feel slightly more special than a standard habit card, while remaining clean and highly readable. It must support UI elements such as avatar, level, progress, coins and short stats. Use soft warm tones, subtle depth and refined texture. Avoid visual clutter, text, icons, characters, objects or strong decorative patterns.

Create a premium warm dawn composition with soft golden, camel, cream and sand tones. Use refined texture and elegant depth. Avoid shiny metallic gold or flashy luxury effects.

Avoid cartoon style, childish aesthetics, strong contrast, harsh shadows, busy patterns, glossy effects, aggressive gradients, visible text, logos, icons, characters or objects. Recommended output: clean rounded rectangular user card-style asset with transparent or neutral background.

Asset ID: user_card_golden_dawn
Family: golden_dawn
Rarity: Legendary
```

## 9. Negative Prompt Guidelines

Terms and ideas to avoid:

* text
* logo
* watermark
* character
* mascot
* cartoon
* childish
* toy-like
* glossy
* neon
* metallic gold
* casino luxury
* aggressive shadows
* high contrast
* busy pattern
* complex illustration
* realistic objects
* people
* faces
* icons
* buttons
* UI text
* unreadable texture

```text
Avoid text, logos, watermarks, characters, mascots, cartoon style, childish aesthetics, glossy effects, neon colors, metallic gold, casino-like luxury, harsh shadows, strong contrast, busy patterns, complex illustrations, realistic objects, people, faces, icons, buttons, UI text and textures that reduce readability.
```

## 10. Generation Review Checklist

* Does it match Rutio's calm premium identity?
* Does it match the correct rarity?
* Does it match the family intent?
* Is it readable behind or inside UI?
* Is it too saturated?
* Is it too busy?
* Does it contain accidental text/logos/icons?
* Does it feel iOS-first?
* Does it work with beige/camel UI?
* Can it be reused across multiple screens?
* Does it need cropping or WebP optimization?

## 11. Output Naming

Final output files should respect the catalog IDs:

Wallpapers:
`assets/shop/wallpapers/<rarity>/<asset_id>.webp`

Habit cards:
`assets/shop/habit_cards/<rarity>/<asset_id>.webp`

User cards:
`assets/shop/user_cards/<rarity>/<asset_id>.webp`

This document does not create files. It only defines prompts.

## 12. Next Steps

* Generate draft visual assets from these prompts.
* Review consistency across families.
* Export optimized WebP files.
* Add assets to Flutter project in a later implementation phase.
* Update `pubspec.yaml` only when real assets are added.
* Implement catalog and equipment logic in a later phase.
