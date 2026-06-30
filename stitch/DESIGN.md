---
name: Playful Financial Companion
colors:
  surface: "#f7f9fb"
  surface-dim: "#d8dadc"
  surface-bright: "#f7f9fb"
  surface-container-lowest: "#ffffff"
  surface-container-low: "#f2f4f6"
  surface-container: "#eceef0"
  surface-container-high: "#e6e8ea"
  surface-container-highest: "#e0e3e5"
  on-surface: "#191c1e"
  on-surface-variant: "#434655"
  inverse-surface: "#2d3133"
  inverse-on-surface: "#eff1f3"
  outline: "#737686"
  outline-variant: "#c3c6d7"
  surface-tint: "#0053da"
  primary: "#004bc6"
  on-primary: "#ffffff"
  primary-container: "#2463eb"
  on-primary-container: "#eeefff"
  inverse-primary: "#b4c5ff"
  secondary: "#246a52"
  on-secondary: "#ffffff"
  secondary-container: "#a8eecf"
  on-secondary-container: "#296e56"
  tertiary: "#7e4726"
  on-tertiary: "#ffffff"
  tertiary-container: "#9b5e3b"
  on-tertiary-container: "#ffede5"
  error: "#ba1a1a"
  on-error: "#ffffff"
  error-container: "#ffdad6"
  on-error-container: "#93000a"
  primary-fixed: "#dbe1ff"
  primary-fixed-dim: "#b4c5ff"
  on-primary-fixed: "#00174b"
  on-primary-fixed-variant: "#003ea7"
  secondary-fixed: "#abf1d2"
  secondary-fixed-dim: "#90d5b7"
  on-secondary-fixed: "#002116"
  on-secondary-fixed-variant: "#00513b"
  tertiary-fixed: "#ffdbca"
  tertiary-fixed-dim: "#ffb68f"
  on-tertiary-fixed: "#331200"
  on-tertiary-fixed-variant: "#6d3919"
  background: "#f7f9fb"
  on-background: "#191c1e"
  surface-variant: "#e0e3e5"
typography:
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: "700"
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: "700"
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: "600"
    lineHeight: 32px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: "600"
    lineHeight: 28px
  body-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 18px
    fontWeight: "400"
    lineHeight: 28px
  body-md:
    fontFamily: Be Vietnam Pro
    fontSize: 16px
    fontWeight: "400"
    lineHeight: 24px
  label-md:
    fontFamily: Be Vietnam Pro
    fontSize: 14px
    fontWeight: "600"
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Be Vietnam Pro
    fontSize: 12px
    fontWeight: "500"
    lineHeight: 16px
  price-display:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: "800"
    lineHeight: 48px
    letterSpacing: -0.03em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-mobile: 20px
---

## Brand & Style

This design system is built on a foundation of **Cheerful Minimalism**. The goal is to transform the typically dry task of expense tracking into an engaging, low-stress activity for couples and individuals. The brand personality is optimistic, supportive, and organized.

The aesthetic leans heavily into soft, tactile forms with a focus on high-clarity layouts. It avoids the "serious" corporate look of traditional banking apps in favor of a friendly, approachable interface that feels more like a lifestyle app. Visual interest is generated through vibrant color blocking, organic shapes, and custom iconography rather than complex textures or shadows. The interface should evoke a sense of calm control over one's finances through generous whitespace and a clear visual hierarchy.

## Colors

The palette utilizes a "Vibrant Pastel" approach. The **Royal Blue** (Primary) provides the necessary grounding and trust for a financial application, used for primary actions and active states. **Mint Green** (Secondary) and **Soft Orange** (Tertiary) are used for category differentiation, success/warning states, and background accents to keep the mood light.

- **Primary (Royal Blue):** Main CTA buttons, active navigation icons, and key financial totals.
- **Secondary (Mint Green):** Income tracking, "on-budget" indicators, and secondary backgrounds.
- **Tertiary (Soft Orange):** Discretionary spending categories, alerts, and accent details.
- **Neutrals:** A range of cool grays and off-whites ensure the interface remains clean and readable.

Use light, tinted backgrounds (pale mint and pale orange) for large cards to create a "containerized" look that doesn't feel heavy.

## Typography

The system uses **Plus Jakarta Sans** for headlines and financial figures to provide a modern, friendly, and slightly geometric feel. Its soft terminals pair perfectly with the high-roundedness of the UI elements. **Be Vietnam Pro** is used for body copy and labels, offering excellent legibility and a contemporary, warm tone.

A specialized `price-display` role is defined for main account balances to ensure high impact. All headlines use a slightly tighter letter spacing to maintain a cohesive, "chunky" look that matches the brand personality.

## Layout & Spacing

This design system utilizes a **8px soft-grid system** to maintain consistency. The layout is fluid but constrained by generous safe-area margins (20px) on mobile to ensure content feels "tucked in" and protected.

- **Containers:** Use `lg` (24px) padding for primary cards to create an airy, premium feel.
- **Vertical Rhythm:** Group related items (like transaction lists) with `sm` (8px) gaps, while separating major sections with `xl` (32px) spacing.
- **Couples View:** For shared accounts, use a split-screen or side-by-side card layout with a `gutter` of 16px to clearly delineate "Mine" vs "Ours".

## Elevation & Depth

Visual hierarchy is achieved through **Tonal Layering** and **Soft Ambient Shadows**. Instead of traditional deep shadows, this design system uses low-opacity, tinted shadows that match the surface color (e.g., a subtle blue-tinted shadow under a primary button).

1. **Base Level:** The background is the neutral `#F8FAFC`.
2. **Card Level:** Floating cards use a very subtle, diffused shadow (Blur: 15px, Spread: 0, Opacity: 5%) to appear lifted.
3. **Interactive Level:** Buttons and active input fields use a slightly more pronounced "squishy" shadow to invite interaction.
4. **Modal Level:** Full-screen overlays use a background blur (Backdrop Filter: blur(8px)) to maintain context while focusing the user.

## Shapes

The shape language is the most distinctive element of this design system. It uses **Pill-shaped (Level 3)** roundedness across all primary components.

- **Primary Buttons:** Fully rounded (pill) ends.
- **Cards:** Large radius (rounded-xl: 32px) to make the containers feel soft and safe.
- **Input Fields:** Semi-rounded (rounded-lg: 16px) to maintain a distinction from buttons.
- **Icons:** All icons must feature rounded caps and corners; sharp angles are strictly prohibited.

## Components

### Buttons

Primary buttons are tall (min-height: 56px) with bold `headline-sm` text. They use the Primary Royal Blue with white text. Secondary buttons use a light tint of the primary color or a secondary color with a high-contrast label.

### Cards

Cards are the primary container for transactions and budget summaries. They should use white backgrounds with the soft-shadow elevation described above. For category-specific cards (e.g., "Food"), use a thin 2px colored top-border or a subtle background tint in Mint or Orange.

### Chips & Categories

Category chips use a combination of a circular icon container and a label. These should be color-coded based on the spending type. Icons should be custom-illustrated with thick, soft lines.

### Progress Bars

Used for budget tracking. These should be thick (12px height) with fully rounded ends. The "track" should be a very light version of the "fill" color to show the remaining limit clearly.

### Input Fields

Inputs use a "floating label" style with a 2px border that thickens and changes to Primary Blue on focus. The background of the input should be a slightly darker neutral than the page background to create a "sunken" feel.

### Shared Indicators

A specific "User" component—a small avatar stack—should appear on any transaction or budget that is shared, indicating collaborative tracking.
