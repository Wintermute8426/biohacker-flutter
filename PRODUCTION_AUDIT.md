# Production Readiness Audit - March 6, 2026

## Goal
Remove mock data, standardize UI/fields, ensure all features are production-ready before Phase 10D.

## Completed Features Status

### ✅ Phase 10A: Onboarding
- 7-screen flow working
- User profile saved to Supabase
- Status: **READY** (minor polish possible)

### ✅ Phase 10B: Cycles → Dose Schedules
- Create cycle workflow
- DoseScheduleForm modal
- Doses populate calendar
- Status: **READY** (needs UI standardization)

### ✅ Phase 10C: Dose Logging (JUST TESTED)
- LogDoseModal form works
- Saves to dose_logs table
- Calendar integration working
- Status: **READY** (minimal fields, production OK)

### ⚠️ Phase 10E: Dashboard Insights
- All 6 components built
- Mock data seeded in dashboard_snapshots
- Status: **NEEDS CLEANUP** (remove mock data)

---

## UI Inconsistencies Identified

### 1. Peptide Selection
- **Cycles screen:** Uses free-text TextEditingController
- **Research screen:** Uses dropdown/searchable list
- **Decision:** Use Research screen's searchable approach (better UX)

### 2. Form Field Styling
- **LogDoseModal:** Uses TextField with cyan borders
- **DoseScheduleForm:** Uses similar but slightly different spacing
- **Research forms:** Different border colors
- **Decision:** Standardize all to: cyan border, 8px padding, same font size

### 3. Modal Behavior
- **LogDoseModal:** Full-screen Scaffold (Navigator.push)
- **DoseScheduleForm:** BottomSheet
- **Insights dialog:** Custom WintermmuteDialog
- **Decision:** Use full-screen Scaffold for all multi-field forms (better UX on mobile)

### 4. Button Styling
- **Primary buttons:** Cyan background, black text (LogDoseModal)
- **Outline buttons:** Cyan border, cyan text (Cycles)
- **Some buttons:** Different sizes
- **Decision:** Standardize to: primary = AppColors.primary bg, outline = AppColors.border

### 5. Snackbar Messages
- **Success:** Green snackbar (AppColors.primary)
- **Error:** Red snackbar (AppColors.error)
- **Info:** Gray snackbar
- **Status:** OK - consistent across app ✅

### 6. Form Headers
- **LogDoseModal:** "LOG DOSE" in appbar
- **DoseScheduleForm:** In-form header
- **Decision:** Consistent appbar for all full-screen forms

---

## Mock Data Removal Checklist

- [ ] dashboard_snapshots: Remove seeded test entry
- [ ] Remove test data from Supabase

---

## Standardization Tasks

### Priority 1: Critical for Launch
- [ ] Standardize peptide selection across all screens
- [ ] Standardize form field styling
- [ ] Standardize modal behavior (full-screen vs sheet)
- [ ] Remove all mock data

### Priority 2: Polish
- [ ] Consistent button styling
- [ ] Consistent header/title styling
- [ ] Validation message consistency
- [ ] Loading state indicators

### Priority 3: Nice-to-Have
- [ ] Animations consistency
- [ ] Icon consistency
- [ ] Spacing/padding audit

---

## Execution Plan

1. **Day 1 (Tonight):**
   - [ ] Identify all peptide selection implementations
   - [ ] Create standardized PeptideSelector component
   - [ ] Apply to Cycles + other screens
   - [ ] Remove dashboard mock data

2. **Day 2 (Tomorrow):**
   - [ ] Standardize form fields
   - [ ] Audit button styling
   - [ ] Test all screens end-to-end
   - [ ] Phase 10D: Push Notifications

---

## Testing Checklist (After Standardization)

- [ ] Onboarding flow (all 7 screens)
- [ ] Create cycle → configure doses → see in calendar
- [ ] Log dose from calendar
- [ ] View insights (should show "No insights yet" without mock data)
- [ ] All forms have consistent styling
- [ ] All modals work (no context errors)
- [ ] All snackbars display correctly
- [ ] No mock data in Supabase

