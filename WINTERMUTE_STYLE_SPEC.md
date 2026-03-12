# Wintermute Dashboard Style Specification

## Design System

### Colors
- **Primary Color:** Cyan #00FFFF (neon glow effect)
- **Accent:** Neon Green #39FF14
- **Background:** Pure Black #000000
- **Secondary BG:** Dark gray #0A0A0A, #111111
- **Text:** White #FFFFFF, cyan #00FFFF
- **Borders:** Cyan #00FFFF with glow
- **Cards:** Black bg with cyan border + outer glow
- **Buttons:** Black bg, cyan border, cyan text, glow on hover
- **Typography:** Monospace/tech fonts (Courier New, Roboto Mono)

### NO UNDERLINES
- Remove ALL text underlines (especially on research page)
- Use other hover effects: glow, scale, color change

## Pages to Restyle

### 1. Login Screen
- Black background
- Cyan glowing borders on input fields
- Cyan glowing button
- Wintermute logo/branding
- Tech aesthetic

### 2. Signup Screen
- Match login style
- Consistent with dashboard theme

### 3. Dashboard
- Already good but ensure consistency
- Cards should have cyan glow
- Syringe icons keep their style

### 4. Calendar
- Black background
- Cells with cyan borders
- Date numbers in cyan
- Red glow for missed doses (keep current logic)
- Green glow for completed
- Maintain grid layout

### 5. Cycles Screen
- Black cards with cyan borders
- Cycle progress bars with cyan/green gradients
- Expand/collapse with smooth animation

### 6. Profile Screen (Cyberpunk ID Card)
- **ADD PROFILE PICTURE OPTION**
- Allow user to upload/select profile photo
- Display on ID card (circular with cyan border glow)
- Default avatar if no photo
- Photo picker functionality (camera or gallery)
- Store in Supabase storage
- Update user_profiles table with photo URL

### 7. Research Screen
- Fix those weird underlines
- Black background
- Cyan section headers
- Links should glow, not underline

### 8. Settings/Other Screens
- Consistent black + cyan theme
- All inputs with cyan glow borders
- All buttons with cyan glow

## Components to Update
- AppBar/header
- Bottom navigation
- Buttons
- Text fields
- Cards
- Lists
- Dialogs/modals

## Profile Picture Implementation
1. Add image_picker package if not present
2. Add camera/gallery permission handling
3. Create profile photo upload service
4. Store in Supabase storage bucket 'profile-photos'
5. Update user_profiles table with photo_url column (add migration if needed)
6. Update profile screen to show photo picker
7. Display photo on ID card (circular, 80x80, cyan glow border)

## Reference
See DASHBOARD_FINAL.md for complete dashboard styling reference.
