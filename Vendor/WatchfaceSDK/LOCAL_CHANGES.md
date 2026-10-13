# Local WatchfaceSDK changes (sdkdemo)

Based on upstream `HWdan/WatchfaceSDK` @ `1.0.6` / commit used by the demo Podfile.

## Why this fork exists

Android `qjs-watchface` AAR exposes low-level widgets (`AppLinkWidget`, `ArcWidget`, …) as **public** API.
The CocoaPods Swift sources already implemented the same types but kept them **internal**, so app targets (Studio demo) could not use them.

## Changes

1. **Public low-level QJS API** — `Widget` / `ValueWidget` / all `Qjs/widgets/*`, `Point`, `Size` init, `SifliQjsWatchface` init + `widgetList` + `addWidget`.
2. **High-level wrappers** (for `SlifiCustomWatchface.addWidget`):
   - `QjsAppLinkWidget`
   - `QjsArcWidget`
3. **`QjsDotWidget.setCenter`** / **`QjsPointerWidget.setCenter`** made public.
4. **Pointer center bugfix** — Hour/Minute/Second no longer overwrite dial center with hardcoded `233,233` (broke 480/410 panels).
5. **`TextWidget`** color / fontFamily setters exposed.

## Consume

```ruby
pod 'WatchfaceSDK', :path => 'Vendor/WatchfaceSDK'
```

Merge these changes back to the official WatchfaceSDK repo when ready, then switch the Podfile to `:git` again.

6. **`QjsWidget` open** — apps can subclass and override `qjsWidgets()` (Studio TTF widgets).
7. **`QjsLinkTextWidget` / `QjsSequenceImageWidget`** high-level wrappers.
8. **`QjsFontGlyphRenderer`** — TTF → digit/week atlases for Group/Option widgets.
9. **SequenceImageWidget** uses `images.count` when packing (was stuck at 0 if only images set).
