# ThreadCRAFT — Full App Context for Claude

## What Is ThreadCRAFT?
A Flutter/Android app that converts photos into nail-winding thread art guides.
User uploads a photo → app generates nail sequence → user physically hammers nails on a board and winds thread following the step-by-step guide.

---

## Tech Stack
- **Framework:** Flutter (Dart)
- **State:** Provider
- **DB:** Hive (local)
- **TTS:** flutter_tts
- **PDF:** pdf package
- **Image:** image package (Dart)
- **Android Studio** — development environment

---

## App Theme
- Dark neon premium UI
- Purple/pink gradients
- Glassmorphism cards
- Glow effects
- Primary colors: purple (#7C3AED), pink (#EC4899), cyan, orange

---

## File Structure
lib/
├── core/theme/
│ ├── app_colors.dart
│ └── app_theme.dart
├── features/
│ ├── thread_art/algorithm/
│ │ └── thread_algorithm.dart
│ ├── thread_art/canvas/
│ │ └── nail_ring_painter.dart
│ └── rgb_art/
│ ├── rgb_algorithm.dart
│ └── rgb_ring_painter.dart
├── models/
│ └── project_model.dart
├── services/
│ ├── premium_service.dart
│ ├── project_service.dart
│ ├── voice_service.dart
│ ├── settings_service.dart
│ ├── pdf_export_service.dart
│ └── nail_template_pdf_service.dart
├── screens/
│ ├── splash_screen.dart
│ ├── home_screen.dart
│ ├── new_project_screen.dart
│ ├── image_crop_screen.dart
│ ├── generating_screen.dart
│ ├── preview_screen.dart
│ ├── work_mode_screen.dart
│ ├── rgb_preview_screen.dart
│ ├── rgb_work_mode_screen.dart
│ ├── my_projects_screen.dart
│ ├── premium_screen.dart
│ ├── settings_screen.dart
│ └── voice_guide_screen.dart
└── widgets/
├── gradient_button.dart
├── glow_card.dart
└── neon_toggle.dart
---

## Screens & Flow

### New Project Screen
- Pick image from gallery
- Smart presets: Beginner / Balanced / Detailed / Ultra
- Frame shape: Circle / Square / Rectangle
- Nail count: 50–400 (slider)
- Thread density: Low / Medium / High
- Thread size: 0.11mm / 0.16mm / 0.19mm / 0.25mm
- Thread color: 10 preset circles (White/Black/Gold/Red/Blue/Purple/Pink/Cyan/Orange/Green)
- Board size: 30/50/75/100/120 cm
- Thread mode: [Selected Color] Thread OR RGB Thread
- Tapping preset fills all settings automatically

### Generation Flow
- NewProjectScreen → ImageCropScreen → GeneratingScreen → PreviewScreen (classic) or RGBPreviewScreen (RGB)
- Uses compute() for isolate-based generation

### Work Mode (Classic)
- Voice guide (TTS)
- Auto-advance with timer
- Pause/resume
- Background photo toggle
- Save progress every 10 steps
- Top bar save button

### Work Mode (RGB)
- Phase system: Blue → Red → Green
- Voice: "Blue thread. Nail 12 to 84"
- Thread switch alert when phase changes
- Auto-advance, voice on/off, repeat button
- Preview slider across all 3 phases combined
- Phase timeline showing progress %
- Settings sheet: voice gender/speed, auto delay

### My Projects
- Shows classic projects (% progress bar)
- Shows RGB projects (RGB badge + combined progress)
- Opens correct preview screen based on type

---

## Premium System

### Plan Types (PlanType enum)
| Plan | Price | Duration | Access |
|------|-------|----------|--------|
| none | Free | — | Black/White thread only |
| colorPass | Rs69 | 24 hours | Color thread |
| rgbPass | Rs99 | 24 hours | RGB thread |
| monthly | Rs199 | 30 days | Everything |
| yearly | Rs999 | 365 days | Everything |
| lifetime | Rs2499 | Forever | Everything |

### Access Checks
- hasColorAccess → colorPass / rgbPass / monthly / yearly / lifetime
- hasRGBAccess → rgbPass / monthly / yearly / lifetime
- Persisted via Hive keys: tc_plan_v2, tc_expiry_v2
- checkAndRefresh() → returns true if just expired
- Free users get paywall before generation
- "Continue with Black Thread" free fallback

---

## Project Model (Supports Both Classic + RGB)

```dart
ProjectModel {
  id, name, imagePath, nailCount, shape, density
  nailPath        // classic path OR blue path for RGB
  currentStep
  createdAt
  isRGB           // true for RGB projects
  redPath         // RGB only
  greenPath       // RGB only
  currentPhase    // 0=Blue, 1=Red, 2=Green
}
```

- progress getter handles both classic and RGB correctly
- isCompleted handles both modes

---

## PDF Export System
1. Step List PDF — numbered nail steps, purple themed
2. Nail Template PDF — real-scale printable A4 pages for physical board
    - Auto-splits by board size (30cm=1 page, 50cm=2-4, 100cm=6-9)
    - Every nail numbered (all 400 if needed)
    - Corner alignment marks for taping pages together
    - Overlap dashed guides
    - Nail numbers use pw.Positioned (not canvas.drawString)

---

## Algorithm Architecture

### Classic Thread Algorithm (thread_algorithm.dart)
- Luminance grayscale (ITU-R: 0.299R + 0.587G + 0.114B)
- Histogram equalization
- Unsharp masking (sharpens facial details)
- Sobel edge detection, blended 60/40 with grayscale
- Center boost (25% for portrait faces)
- Percentile scoring (avg x0.35 + p70 x0.35 + p90 x0.30)
- Recent nail penalty window (25 nails)
- Adaptive erasure (dark areas erase more)
- Candidate sampling (120 per step)
- Thread counts: Low=700, Medium=1500, High=3000

### RGB Algorithm (rgb_algorithm.dart) — 4-Part System
**Part 1 — Multi-pass interleaved rendering:**
- R(30) → G(30) → B(30) → R(30) → G(30) → B(30) → repeat
- Virtual canvas tracks accumulated color across all channels
- Additive model: high channel value = draw thread there
- S-curve contrast enhancement

**Part 2 — Error-based + importance scoring:**
- Sobel edge map (detects eyes, lips, jawline)
- Local contrast map (7x7 std-dev window)
- Importance map [1.0-4.5]: edges x2.0 + contrast x0.9 + center x0.8
- Zone grid 12x12 prevents thread clumping
- Nail pair tracking prevents same A-B reuse
- Perceptual error uses ITU-R weights

**Part 3 — Skin tone + opacity + channel balance:**
- Skin tone map using warm-pixel heuristic
- Smooth skin gets lighter thread treatment
- Stage opacity: 66→51→40→29→18 (early=solid, late=translucent)
- Zone-density opacity modifier
- Channel fill ratio prevents green/blue dominance

**Part 4 — Early stop + performance:**
- Sampled total error check every 5 passes
- Early stop when improvement less than 0.8% for 4 checks
- Adaptive thread count by image complexity (0.7x–1.35x)
- Dynamic candidates: 45/62/78 by stage
- Adaptive min-skip fraction
- Highlight preservation (lum above 215 = reduced target)
- Background suppression (far from center = 50% importance)

### RGB Ring Painter (rgb_ring_painter.dart)
- CRITICAL: Pure black background (#080808)
- Photo overlay at 8% opacity only (reference)
- Interleaved batch rendering: Red[0:50] → Blue[0:50] → Green[0:50] → Red[50:100] → ...
- Thread opacity: 0.38 per thread
- Normal BlendMode (NOT BlendMode.plus — that caused white canvas)

---

## KNOWN ISSUES — MUST FIX BEFORE PUBLISH

### CRITICAL 1 — RGB Generation Quality
**Problem:** Output looks whitish/washed out OR colors don't mix naturally
**Root cause:**
1. Background was too bright causing washed out result
2. Opacity mismatch between algorithm and painter
3. Sequential phases hide underlying threads

**Competitor app technique (confirmed from screenshots):**
- Renders 50 lines of Red thread
- Then 50 lines of Blue thread
- Then 50 lines of Green thread
- Repeats this cycle 100+ times until complete
- Each thread is semi-transparent (low opacity ~0.35-0.40)
- Background is DARK (#080808) so RGB colors accumulate naturally
- Final result: realistic portrait with natural RGB color mixing

**What needs fixing:**
- rgb_ring_painter.dart: interleaved 50-batch rendering (Red→Blue→Green→repeat)
- rgb_ring_painter.dart: black background, thread opacity ~0.38, normal BlendMode
- rgb_algorithm.dart: algorithm generates 3 path lists, painter does the interleaving

### CRITICAL 2 — Classic Color Thread Preview Too Dark
**Problem:** Color thread preview goes very dark/muddy after 50% completion
**Files to check:**
- lib/features/thread_art/canvas/nail_ring_painter.dart — thread opacity
- lib/features/thread_art/algorithm/thread_algorithm.dart — erasure amount
  **Fix needed:** Color threads should look like clean colored lines on dark background

### MEDIUM — Remove Debug Button Before Publish
- Remove debugUnlock button from settings_screen.dart before Play Store upload

---

## Settings
- Haptic feedback toggle
- Auto-save toggle
- Step history toggle
- Dark canvas toggle
- Auto advance (toggle + 4-20s delay slider)
- About section
- Debug premium toggle (REMOVE BEFORE PUBLISH)

---

## Voice Service
- Male pitch: 0.55 / Female pitch: 1.25
- _isSpeaking flag prevents voice overlap
- speakStep(from, to) says "Nail X+1 to Y+1"
- speak(text) for custom text in RGB mode
- 100ms delay before speaking
- Settings saved to Hive: setting_voice, setting_speed, setting_gender

---

## Before Publishing Checklist
- [ ] Remove debugUnlock button from settings_screen.dart
- [ ] Implement real payment gateway (currently simulated with delay)
- [ ] Fix RGB generation quality
- [ ] Fix classic color thread dark preview issue
- [ ] Test on multiple Android devices
- [ ] flutter build apk --release
- [ ] Upload APK to Play Store

---

## Build Command
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```