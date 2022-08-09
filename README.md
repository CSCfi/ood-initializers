# OOD Initializers

Repo name is misleading as this was initially only a repo with a file for a custom initializer for OOD, but now containers the custom initalizer, other scripts, widgets, dashboard layout and localization file.

## `dashboard`

Contains the custom initializer `ood.rb`, Ruby scripts for quota and balance warnings and app info card script (extra information for interactive apps connection page). `ood.rb` is ran by OOD and loads the other scripts in `dashboard/`, sets up navigation bar content and configures quota and balance warnings.
`balance.rb` and `quota.rb` are heavily based on the Balance and Quota classes found in OOD.
Major change is the functionality that allows hiding warnings.

## `widgets`

Widgets used on the dashboard.
Contains three main widgets: the MOTD widget, the logo widget and the notification (quota/balance warning) widget, which use subwidgets.
For details about how the widgets work and how to create widgets, see [WIDGETS.md](./WIDGETS.md).

### MOTD
Wraps the normal OOD MOTD content in a styled box.

### Logo widget
Normal OOD logo does not scale nicely, so this custom logo widget simply inserts an image that scales correctly to all browser sizes.

### Quota/balance warnings
A less intrusive version of the OOD warnings.
Adds the quota and balance warnings in a box styled in the same way as the MOTD widget.
Allows hiding the warnings by updating files under `$HOME/ondemand` using AJAX, which is then read serverside to generate the widget with certain warnings hidden.
