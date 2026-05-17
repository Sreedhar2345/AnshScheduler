# Ansh's Scheduler

iOS scheduler app that stores daily task reminders and sends local notifications at each task's scheduled time.

## Open in Xcode

1. Open `TaskReminderApp.xcodeproj` in Xcode.
2. Select the **TaskReminderApp** target → **Signing & Capabilities** → choose your **Team**.
3. Select an iPhone simulator or your device, then press **Run** (⌘R).

If you change `project.yml`, regenerate the project (this also restores `Assets.xcassets` in the build):

```bash
rm -rf TaskReminderApp.xcodeproj
xcodegen generate
```

### If the app fails to launch on a physical device

1. **Product → Clean Build Folder** (⇧⌘K).
2. On the iPhone, **delete** the old “Ansh's Scheduler” app.
3. Re-open the project, confirm **Signing & Capabilities** has your team selected.
4. Run again (⌘R).

If Xcode still reports a SpringBoard / CoreDevice error, reboot the iPhone once, then try again.

## Features

- **Home** — Lists all tasks (name + time). Shows **Create Task** when the list is empty.
- **Settings** — **Add a New Task** or tap an existing task to edit.
- **SAVE** — Persists tasks and schedules a repeating daily notification with the task name.
- **Theme** — Light background `#9CD5FF`, dark background `#355872`, with high-contrast text in both modes.
- **App icon** — Uses the uploaded image set in `Assets.xcassets/AppIcon.appiconset`.

## App-specific architecture

All types and storage keys are prefixed for **Ansh's Scheduler** only:

- `AnshSchedulerStore`, `AnshScheduledTask`, `AnshSchedulerTheme`, etc.
- UserDefaults suite: `{bundleId}.preferences`
- Storage key: `{bundleId}.scheduledTasks.v1`
- Notification IDs: `{bundleId}.dailyReminder.{taskId}`

Existing tasks saved under the older `ansh-scheduler.tasks` key are migrated automatically on first launch.

## Notifications

On first launch the app requests notification permission. Each task fires every day at its chosen time.
