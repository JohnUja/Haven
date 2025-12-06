# Theme Styling Guide - Haven 2.0

## Overview
This document describes the visual styling for **Light**, **Dark**, and **Purple** themes across all layouts in Haven 2.0.

---

## 🎨 Theme Styling Breakdown

### **PURPLE THEME** (Default)
**Color Palette:**
- **Background**: Purple → Blue → Pink gradient (vibrant, colorful)
- **Text Primary**: System primary (adapts to light/dark mode)
- **Text Secondary**: System secondary
- **Glass Cards**: White opacity (0.1 background, 0.2 border) - translucent glass effect
- **Card Borders**: White with 20% opacity
- **Accent**: Orange/Amber for highlights

**Visual Style:**
- ✨ **Vibrant & Colorful**: Rich purple/blue/pink gradients
- 🔮 **Glassmorphism**: Light translucent cards with white borders
- 📝 **Text**: System colors (adapts automatically)
- 🎯 **Icons**: Full color spectrum available

**Best For:** Default experience, colorful and engaging

---

### **LIGHT THEME** (Black/White/Grey Only)
**Color Palette:**
- **Background**: White → Light Grey → Medium Grey gradient (minimal, clean)
- **Text Primary**: **Black** (high contrast)
- **Text Secondary**: **Grey**
- **Glass Cards**: **White** (90% opacity) - solid white cards
- **Card Borders**: **Black** with 20-30% opacity (subtle black outlines)
- **Accent**: Grey

**Visual Style:**
- ⚪ **Minimal & Clean**: Pure white/grey palette
- 📄 **Solid Cards**: White cards with black borders (not translucent)
- ⚫ **High Contrast**: Black text on white backgrounds
- 🎨 **Monochromatic**: Only black, white, and grey colors

**Best For:** Minimalist aesthetic, high readability, professional look

**Key Features:**
- Timeline: Dark colors (black text, dark borders)
- Cards: White fill with black borders
- Text: Black with grey for secondary
- No colorful accents

---

### **DARK THEME** (Black/White/Grey Only)
**Color Palette:**
- **Background**: Black → Dark Grey → Medium Grey gradient (deep, immersive)
- **Text Primary**: **White** (high contrast)
- **Text Secondary**: **Grey**
- **Glass Cards**: **Black** (70% opacity) - dark translucent cards
- **Card Borders**: **White** with 20-30% opacity (subtle white outlines)
- **Accent**: Grey

**Visual Style:**
- ⚫ **Deep & Immersive**: Pure black/grey palette
- 🌑 **Dark Cards**: Black cards with white borders (translucent dark)
- ⚪ **High Contrast**: White text on black backgrounds
- 🎨 **Monochromatic**: Only black, white, and grey colors

**Best For:** Night mode, reduced eye strain, modern dark aesthetic

**Key Features:**
- Timeline: Light colors (white text, light borders)
- Cards: Black fill with white borders
- Text: White with grey for secondary
- No colorful accents

---

## 📐 Consistent Elements (All Themes)

### **Layout Structure:**
- **Card Corner Radius**: 16px (all cards)
- **Small Corner Radius**: 12px (buttons, chips)
- **Border Width**: 1px (all borders)
- **Card Padding**: 16px horizontal
- **Card Vertical Padding**: 12px
- **Section Spacing**: 24px
- **Item Spacing**: 12px

### **Typography:**
- **Headers**: System font, 28pt, Semi-bold, Uppercase
- **Titles**: System font, 20pt, Semi-bold
- **Body**: System font, 16pt, Regular
- **Captions**: System font, 12pt, Regular

### **Glassmorphism Effect:**
- **Purple Theme**: Translucent white glass (10% opacity)
- **Light Theme**: Solid white cards (90% opacity)
- **Dark Theme**: Translucent black glass (70% opacity)

---

## 🎯 Layout-Specific Styling

### **Homepage (Focus View)**
- **Dynamic Box**: Priority-based gradient background + glass overlay
- **Agenda Cards**: Priority-colored borders (red/orange/blue/teal)
- **Text**: Theme-aware (black in light, white in dark)
- **Background**: Theme primary gradient

### **Homepage (Plan View)**
- **Summary Card**: Glass card with circular progress ring
- **Task Cards**: Category-colored in Purple, glassmorphism in Light/Dark
- **Filter Button**: Up/down arrows icon, theme-aware color
- **Text**: Theme-aware throughout

### **Timeline View**
- **Time Labels**: Theme-aware (dark in light mode, light in dark mode)
- **Date Header**: Theme-aware text color
- **Filter Buttons**: Glass cards with theme borders
- **Task Blocks**: Category colors in Purple, glassmorphism in Light/Dark

### **Settings Page**
- **Cards**: Glassmorphism throughout
- **Icons**: Theme-aware colors (accent color)
- **Text**: Theme-aware with proper opacity levels
- **Toggle Switches**: Theme-aware accent color

### **Feed View**
- **Segmented Control**: Glass background with theme border
- **Feed Cards**: Glass cards
- **Empty State**: Theme-aware text colors

### **Goals View**
- **Goal Cards**: Glass cards
- **Progress Rings**: Theme-aware background (20% opacity)
- **Text**: Theme-aware with proper contrast

---

## 🔄 Theme Switching Behavior

### **Light → Dark:**
- Background: White → Black
- Text: Black → White
- Cards: White → Black
- Borders: Black → White
- All elements invert colors

### **Dark → Light:**
- Background: Black → White
- Text: White → Black
- Cards: Black → White
- Borders: White → Black
- All elements invert colors

### **Any → Purple:**
- Background: Gradient (Purple/Blue/Pink)
- Text: System primary (adapts)
- Cards: Translucent white glass
- Borders: White translucent
- Full color spectrum available

---

## ✅ Current Implementation Status

### **Fully Theme-Aware:**
- ✅ Homepage (Focus & Plan views)
- ✅ Dynamic Focus Box
- ✅ Timeline View
- ✅ Settings Page
- ✅ Feed View
- ✅ Goals View
- ✅ Profile View
- ✅ All cards and components

### **Theme Properties Used:**
- `primaryGradient` - Background gradients
- `glassBackground` - Card backgrounds
- `glassBorder` - Card borders
- `textPrimary` - Main text color
- `textSecondary` - Secondary text color
- `accentColor` - Accent highlights
- `cardCornerRadius` - Consistent rounding
- `cardBorderWidth` - Consistent borders
- `cardPadding` - Consistent spacing

---

## 🚀 Next Steps

See `NEXT_STEPS.md` for detailed implementation roadmap.

