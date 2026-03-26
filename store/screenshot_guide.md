# Play Store Screenshot Guide

**DRAFT - REVIEW REQUIRED**

## Overview

Google Play Store requires high-quality screenshots to showcase your app. This guide specifies which screens to capture, dimensions, and annotation requirements.

---

## Screenshot Requirements

### Technical Specifications
- **Dimensions:** 1080 x 1920 pixels (9:16 portrait aspect ratio)
- **Format:** PNG or JPEG (PNG preferred for text clarity)
- **Max File Size:** 8 MB per screenshot
- **Quantity:** Minimum 2, maximum 8 (recommend 6-8 for best presentation)
- **Device:** Capture on a high-resolution Android device or emulator

### Quality Guidelines
- Use high-quality device frames (optional but recommended)
- Ensure text is legible and UI elements are crisp
- Use consistent device/frame style across all screenshots
- Show real or realistic demo data (not Lorem Ipsum placeholders)
- Avoid screenshots of loading states or error messages
- Use dark mode OR light mode consistently (not mixed)

**Recommendation:** Use **dark mode** for screenshots—matches biohacker aesthetic and looks premium.

---

## Required Screenshots

### Screenshot 1: Login/Onboarding Screen
**Purpose:** First impression—showcase security and branding  
**Screen to Capture:** Login screen with biometric authentication prompt  
**Key Elements:**
- Biohacker logo prominently displayed
- Fingerprint/Face ID icon
- "Secure Login" or "Military-Grade Encryption" badge
- Clean, minimalist design

**Caption (optional overlay):**  
"Secure biometric login with military-grade encryption"

**Notes:**
- Use a high-quality device frame (e.g., Pixel 8, Samsung S24)
- Show biometric authentication UI if possible

---

### Screenshot 2: Cycles Dashboard (Home Screen)
**Purpose:** Show core functionality—cycle tracking  
**Screen to Capture:** Cycles tab with active and past cycles  
**Key Elements:**
- Active cycle card with progress indicator
- Past cycles list with dates
- Floating Action Button (FAB) for adding new cycle
- Timeline visualization or calendar view
- "AI Insights" badge or indicator (if available)

**Caption:**  
"Track multiple peptide cycles with intelligent timeline views"

**Notes:**
- Populate with 2-3 realistic demo cycles (e.g., "GH Stack Q1 2026", "Metabolic Reset Cycle")
- Show cycle status (active, completed, upcoming)

---

### Screenshot 3: Lab Results Screen
**Purpose:** Highlight lab tracking and AI insights  
**Screen to Capture:** Lab Results tab with uploaded results and insights  
**Key Elements:**
- Lab result cards showing biomarker names (Testosterone, IGF-1, HbA1c, etc.)
- Trend indicators (↑ ↓ arrows or color-coded)
- "AI Insights" panel at top with at least one recommendation
- Upload button or icon
- Date range filter (if implemented)

**Caption:**  
"Upload and analyze lab results with AI-powered insights"

**Notes:**
- Use realistic demo data (avoid extreme outliers)
- Show 4-6 biomarker cards
- Highlight one AI insight prominently

---

### Screenshot 4: Protocol Management
**Purpose:** Show protocol creation and dosing features  
**Screen to Capture:** Protocols tab with protocol cards  
**Key Elements:**
- Protocol cards showing name, peptides, dosages
- Active protocols badge or indicator
- Protocol categories or tags (if implemented)
- FAB for creating new protocol
- Schedule/notification icon

**Caption:**  
"Create and manage peptide protocols with precision dosing"

**Notes:**
- Populate with 2-3 demo protocols (e.g., "Morning GH Stack", "Evening Recovery")
- Show dosage amounts and frequencies clearly

---

### Screenshot 5: Biomarker Trend Chart
**Purpose:** Showcase data visualization capabilities  
**Screen to Capture:** Chart view (inside Lab Results or dedicated Charts tab)  
**Key Elements:**
- Line chart showing biomarker trends over time (3-6 months)
- Multiple biomarkers on one chart OR side-by-side comparison
- Axis labels and legend
- Zoom/pan controls (if visible)
- Date range selector

**Caption:**  
"Visualize your health data with beautiful interactive charts"

**Notes:**
- Use smooth, realistic trend lines (not jagged random data)
- Color-code different biomarkers (e.g., blue = Testosterone, green = IGF-1)
- Show at least 4-6 data points per biomarker

---

### Screenshot 6: Research Library
**Purpose:** Highlight educational content  
**Screen to Capture:** Research tab with categorized articles  
**Key Elements:**
- Research article cards with titles and summaries
- Category tabs or filters (Peptides, Hormones, Metabolic Health, etc.)
- Search bar
- Save/bookmark icon on articles
- High-quality article thumbnails (if available)

**Caption:**  
"Access curated research on peptides, hormones, and longevity"

**Notes:**
- Populate with 6-8 realistic article titles (use real research topics)
- Show category organization clearly

---

### Screenshot 7: Profile/Settings
**Purpose:** Emphasize data control and security features  
**Screen to Capture:** Profile tab or Settings screen  
**Key Elements:**
- User profile info (name, email)
- "Export Data" button prominently displayed
- "Delete Account" option visible
- Security settings (biometric toggle, session timeout)
- Dark mode toggle
- Privacy Policy / Terms links

**Caption:**  
"Complete control over your data—export or delete anytime"

**Notes:**
- Highlight data ownership and privacy controls
- Show export format options (JSON, CSV, PDF) if in modal

---

### Screenshot 8 (Optional): AI Insights Detail
**Purpose:** Show off AI analysis capabilities  
**Screen to Capture:** AI Insights expanded view or detail modal  
**Key Elements:**
- Correlation analysis (e.g., "Your testosterone increases 2 weeks post-GH protocol")
- Recommendation cards
- Data visualization (scatter plot, correlation matrix, etc.)
- Confidence indicators or badges

**Caption:**  
"Get intelligent recommendations based on your biomarker patterns"

**Notes:**
- Use realistic AI-generated language (avoid generic placeholders)
- Show at least 2-3 insights

---

## Annotation Guidelines

### Text Overlays (Optional but Recommended)
- **Font:** Clean sans-serif (Roboto, Open Sans, Inter)
- **Size:** Large enough to read on mobile (min 24pt)
- **Color:** High contrast (white text on dark overlay, or vice versa)
- **Placement:** Top or bottom third of screen (avoid covering critical UI)
- **Content:** Short, benefit-focused captions (see examples above)

### Device Frames
**Tools:**
- [Screely](https://screely.com/) - Free browser mockups
- [Mockuphone](https://mockuphone.com/) - Device frame templates
- [Figma](https://figma.com) - Manual frame design

**Recommended Frame Style:**
- Modern flagship Android device (Pixel 8, Samsung S24)
- Consistent across all screenshots
- Optional: Add subtle shadow/background gradient

---

## Capture Process

### Using Android Studio Emulator
1. Launch emulator with 1080x1920 resolution
2. Set density to 440 dpi (xxhdpi)
3. Populate app with demo data
4. Navigate to each screen
5. Use built-in screenshot tool (camera icon in emulator toolbar)

### Using Physical Device
1. Connect device via USB (enable USB debugging)
2. Run `adb shell screencap -p /sdcard/screenshot.png`
3. Pull file: `adb pull /sdcard/screenshot.png`
4. Repeat for each screen

### Post-Processing
1. Crop to exact 1080x1920 if needed
2. Add device frames (optional)
3. Add text overlays/captions (optional)
4. Optimize file size (TinyPNG, ImageOptim)
5. Save as PNG with descriptive filenames:
   - `01_login.png`
   - `02_cycles_dashboard.png`
   - `03_lab_results.png`
   - etc.

---

## Demo Data Requirements

### Cycles
- **Cycle 1 (Active):** "GH Stack Q1 2026" — Started Jan 15, 2026, 8 weeks duration
- **Cycle 2 (Past):** "Metabolic Reset" — Completed Dec 2025
- **Cycle 3 (Upcoming):** "Summer Cut" — Starts April 2026

### Lab Results (Realistic Ranges)
- **Testosterone:** 650-850 ng/dL (male), 15-70 ng/dL (female)
- **IGF-1:** 150-300 ng/mL
- **HbA1c:** 4.8-5.6% (optimal)
- **Fasting Glucose:** 75-90 mg/dL
- **TSH:** 1.0-2.5 μIU/mL

### Protocols
- **Protocol 1:** "Morning GH Stack" — 5 IU GH, 250 mcg GHRPs
- **Protocol 2:** "Evening Recovery" — BPC-157, TB-500
- **Protocol 3:** "Metabolic Support" — Metformin, Berberine

### Research Articles (Example Titles)
- "GH Secretagogue Mechanisms and Metabolic Effects"
- "Optimizing IGF-1 Levels for Longevity"
- "BPC-157 and Tissue Repair: Recent Clinical Evidence"
- "Peptide Stacking Strategies for Body Recomposition"

---

## Final Checklist

- [ ] All 7-8 screenshots captured at 1080x1920
- [ ] Consistent device frame style used
- [ ] Dark mode applied consistently
- [ ] Realistic demo data populated
- [ ] Text overlays added (if using captions)
- [ ] Files optimized (< 1 MB each preferred)
- [ ] Descriptive filenames (01_login.png, etc.)
- [ ] Screenshots reviewed for clarity and professionalism
- [ ] No personal/real user data visible
- [ ] UI elements crisp and legible

---

**Document Control:**  
Version: 1.0 DRAFT  
Review Required: Design, Product, Marketing  
Next Steps: Capture screenshots → Review → Upload to Play Console  
