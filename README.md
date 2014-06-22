checkoutloud
============

Check Out Loud is a ios7 app for configurable lists of checklists using speech, time delay
Main Features Implemented
Branching tree of checklists
Speech input uses OpenEars
Speech synthesis uses Flite (from same source as OpenEars)
Preferences can disable speech in (user commands) and out (announcing status/items)
Certain User actions are disabled until latest speech out is complete if speech is enabled (next Flite spoken item will not be spoken otherwise)
Branching checklists are linearized (wrapped) into a slide show for checking
Checked items persist a checked status until cleared (on preferences screen)
Already checked items are skipped when overlapping slide show is performed
Skipping can be disabled on preferences
On main view in Check mode Swipe right starts a specific list item and its descendants
On main view in Check mode tap navigates to the children of the item.
Return button navigates back to the parent.
Label on top announces current mode.
Edit mode button announces what to what mode will change if pressed

Known Issues Being Addressed

Need to assess whether there are memory leaks – believe it is set to automatically release items but not certain.  There are unpredictable, irreproducible crashes.

Preferences are not saved for next use of CheckOutLoud
Plans
Current version to be released
No major features planned
Next version
GPS to enable making a checklist contingent on altitude, speed, or position

