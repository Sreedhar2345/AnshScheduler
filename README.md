# TaskReminderApp (iOS SwiftUI)

This repository contains a complete SwiftUI implementation for the requested task reminder app.

## Features included

- Home screen showing all tasks
- Settings screen for:
  - Create new task (name, scheduled time, optional uploaded task image)
  - Edit task
  - Delete task
  - Theme selection (`Nature`, `Water`, `Personal`)
  - Personal theme background image upload
- Theme-based app background rendering
- Local notifications scheduled at each task's selected time
- Local persistence via `UserDefaults`

## Generate Xcode project with XcodeGen

This repository includes a full `project.yml`.

1. Install XcodeGen (if needed):

   ```bash
   brew install xcodegen
   ```

2. Generate the project:

   ```bash
   xcodegen generate
   ```

3. Open the generated project:

   ```bash
   open TaskReminderApp.xcodeproj
   ```

4. In Xcode, set your Apple Developer Team under Signing.
5. Build and run on simulator/device.
6. Allow notifications when prompted so reminders fire.

## Test targets included

- `TaskReminderAppTests` (unit tests)
- `TaskReminderAppUITests` (UI tests)
