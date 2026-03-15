# 📐 UI Plan: StartScreen (UI/UX Refactor)

## 1. Description
- **SRS Ref**: N/A (Onboarding/Start Screen)
- **User Role**: All Users
- **Purpose**: A visually engaging, modern, and trust-inspiring welcome screen that introduces HealthGuard with smooth animations and polished typography, encouraging users to log in or sign up.

## 2. Refactor Goals & UI/UX Improvements
Current StartScreen lacks visual hierarchy and motion. The refactor will apply the following UI/UX upgrades:
1. **Header Cleanup**: Remove the redundant mini-logo on the top-left (since the main screen already features a large hero logo). Keep only the Language Switcher on the top-right, styled elegantly (e.g., `🌐 VN` button with subtle background).
2. **Staggered Entrance Animations**: 
   - Logo fades in and floats up slightly.
   - Title and subtitles slide up and fade in sequentially (200ms delay between each).
   - Footer (Button & Trust indicators) fades in last.
3. **Breathing/Engaging Elements**: 
   - The main Hero Logo will have a continuous, subtle "breathing" animation (scaling up and down by 2-3%).
   - The "Bắt đầu ngay" button will feature a soft pulsing shadow (glowing effect) to draw the user's eye, and the forward arrow will have a continuous subtle slide animation left and right.
4. **Component Decomposition**: Break down the massive `build` method into reusable widgets (`_StartScreenHeader`, `_StartScreenHero`, `_StartScreenContent`, `_StartScreenFooter`) to maintain Clean Architecture and keep animation logic isolated.

## 3. UI States 
| State   | Description       | Display               |
| ------- | ----------------- | --------------------- |
| Success | Static UI loaded  | Logo, Titles, Buttons (all with entrance and idle animations) |

*(Note: Loading, Empty, Error states are not applicable for this static start screen).*

## 4. Widget Tree (Proposed Refactoring)
- `Scaffold`
  - `Container` (Background Gradient: `AppColors.primaryLight` to `white` with smooth transition)
    - `SafeArea`
      - `Column`
        - `_StartScreenHeader` (Only Language selector on top right - animated SlideIn)
        - `Expanded`
          - `SingleChildScrollView`
            - `Column`
              - `_StartScreenHero` (Illustration/Logo with Breathing Animation)
              - `_StartScreenContent` (Titles & Subtitles with Staggered FadeIn + SlideUp)
              - `_StartScreenFooter` (Primary Button with Pulsing Shadow + Trust Indicators)

## 5. Edge Cases Handled
- [x] Small devices (height < 700) rendering correctly without overflow. The animations will not cause layout recalculation jumps.
- [x] Animation logic gracefully handled if the screen is nested inside a `PageView` (animations reset/play correctly).
- [x] Accessibility (min font 16sp applied across styles, high contrast for text on background).

## 6. Dependencies
- Shared constants needed: `AppColors.primary`, `AppColors.primaryLight`
- External packages:
  - Add `flutter_animate: ^4.5.0` to `pubspec.yaml` (Highly recommended for declarative, maintainable UI/UX animations). If not, we will use the built-in `AnimationController`, but it will require significantly more boilerplate code.

## 7. Confidence Score
- **Plan Confidence: 100%**
- Reasoning: The UX upgrades directly address the user's request for a more dynamic and engaging start screen, without overcomplicating core functionality. Removing the top-left icon balances the screen. Using `flutter_animate` will make implementation fast, clean, and beautiful.
- Uncertainties: Need user approval to install `flutter_animate`.
