# PROFILE (Mobile)

> Sprint 1-2 | JIRA: EP04-Login (Profile View), EP05-Register | UC: UC009 (View/Edit Profile)

## Purpose & Technique

- User profile view and edit functionality for Patient & Caregiver
- Logout functionality integrated with AuthProvider
- Placeholder screen with basic logout button (40 LOC)

## Screen Index

| Screen       | Path                                             | Status         | Note                        |
| ------------ | ------------------------------------------------ | -------------- | --------------------------- |
| Profile View | lib/features/profile/screens/profile_screen.dart | ⬜ Placeholder | Logout button only (40 LOC) |

## File Index

| Path                                             | Role                       | LOC |
| ------------------------------------------------ | -------------------------- | --- |
| lib/features/profile/screens/profile_screen.dart | Profile screen with logout | 40  |
| lib/features/profile/models/                     | Empty (only .gitkeep)      | —   |
| lib/features/profile/providers/                  | Empty (only .gitkeep)      | —   |
| lib/features/profile/repositories/               | Empty (only .gitkeep)      | —   |
| lib/features/profile/widgets/                    | Empty (only .gitkeep)      | —   |

## Implementation Details

**Current Features**:

- Logout button: Calls `authProvider.logout()` → clears JWT from secure storage
- Navigation: After logout, routes to login screen via `AppRouter.login`
- Integration: Uses `Provider` to access `AuthProvider`

**Planned Features** (Not Yet Implemented):

- Display user profile data (name, email, phone, role)
- Edit profile information
- Change avatar/profile picture
- View account statistics
- Settings/preferences

## Known Issues

- No profile data display — placeholder only with logout button
- No edit profile functionality
- Clean Architecture folders empty (models/, providers/, repositories/, widgets/ have only .gitkeep)
- No integration with backend `/api/auth/profile` endpoint yet
- No form validation for profile edits

## Cross-References

| Type             | Ref                                            |
| ---------------- | ---------------------------------------------- |
| DB Tables        | users (user profile data)                      |
| UC Files         | BA/UC/Profile/UC009_View_Edit_Profile.md       |
| Related Modules  | AUTH (provides AuthProvider)                   |
| Backend Endpoint | Backend route not yet implemented              |
| State Management | lib/features/auth/providers/auth_provider.dart |

## Review

| Date | Score | Detail                              |
| ---- | ----- | ----------------------------------- |
| —    | —     | Not reviewed yet — placeholder only |
