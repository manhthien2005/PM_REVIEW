# 📐 UI Plan: Email Verification Screen (6-Digit OTP)

## 1. Description
- **SRS Ref**: N/A (Authentication Module)
- **User Role**: User
- **Purpose**: Allow users to verify their email address by entering a 6-digit OTP sent to their email.

## 2. User Flow
1. User requests a password reset/email verification in the previous step.
2. System navigates to Email Verification Screen and sends a 6-digit OTP.
3. User opens their email app to find the 6-digit OTP.
4. User enters the 6 digits into the OTP input fields.
5. Upon entering all 6 digits, user taps "XÁC NHẬN" (or system auto-submits).
6. System displays success message and navigates to the next screen (Login or Home).

## 3. UI States
| State   | Description       | Display               |
| ------- | ----------------- | --------------------- |
| Idle    | Waiting for input | 6 empty OTP boxes, Resend button disabled with countdown |
| Loading | Verifying OTP     | Circular progress indicator over or replacing the Confirm button |
| Success | OTP is valid      | Verification successful, redirecting immediately |
| Error   | Invalid OTP       | Shake animation on OTP boxes, red error text displayed |

## 4. Widget Tree (proposed)
- `Scaffold` (backgroundColor: Colors.white or `AppColors.background`)
  - `SafeArea`
    - `Center`
      - `SingleChildScrollView`
        - `Column`
          - `Icon` / `Image` (pulsing mail icon with `flutter_animate`)
          - `Text` "Xác thực Email" (Title, bold, 24sp)
          - `Text` "Vui lòng nhập mã 6 số được gửi đến..." (Subtitle, 14sp, grey)
          - `Pinput` / `OtpInputWidget` (Row of 6 styled text fields)
          - `ElevatedButton` "XÁC NHẬN" (gradient/primary color)
          - `Row` 
            - `Text` "Chưa nhận được mã?"
            - `TextButton` "Gửi lại (30s)" (countdown timer)

## 5. UI Polish & Effects
- Use `flutter_animate` to gently slide up and fade in the elements sequentially when the screen loads.
- The mail icon at the top will have a gentle breathing/pulsing animation to look alive.
- Clean background to remove visual clutter and make it look premium (removing the heavy gradient background).
- "Gửi lại" button will have a countdown timer (e.g., 60s) to prevent spamming and clarify behavior.

## 6. Edge Cases Handled
- [x] Network loss when tapping Verify or Resend.
- [x] User tries to submit with fewer than 6 digits (button disabled or shows error).
- [x] User enters letters instead of numbers (keyboard type set to number pad).
- [x] Pasting a 6-digit code directly into the field (handled correctly if `pinput` is used).
- [x] Accessibility: Focus nodes managed gracefully, readable font sizes.

## 7. Dependencies
- Shared widgets needed: None if `pinput` is added, or a custom `OtpInputRow`.
- Suggested Package: `pinput: ^3.0.0` or newer for the most robust OTP handling.
- API endpoints: `verifyEmail(token)`, `resendVerificationToken(email)` via `AuthProvider`.

## 8. Confidence Score
- **Plan Confidence: 95%**
- Reasoning: The flow is standard. Using `flutter_animate` will satisfy the "smooth and clear" requirement. The countdown timer solves user confusion around resending emails.
- Uncertainties: Whether the project prefers `pinput` package or a custom-built OTP widget. A custom widget is fine but `pinput` saves time and handles edge cases perfectly.
