# Add a "Join the Beta" Link in Settings

## Summary

The settings screen should include a link that lets users invite others to
join the TestFlight beta. This is a standard pattern — Podcatcher already does
it with a simple `Link` to the TestFlight public invite URL.

## Affected Code

### `Ruckus/Views/SettingsView.swift:27-44`

```swift
Section {
  Button(action: requestReview) {
    Label("Leave a Review", systemImage: "star.fill")
      .labelStyle(SettingsLabelStyle(backgroundColor: .yellow))
  }
  NavigationLink {
    SupportView()
  } label: {
    Label("Support", systemImage: "lifepreserver")
      .labelStyle(SettingsLabelStyle(backgroundColor: .accentColor))
  }
  NavigationLink {
    AboutView()
  } label: {
    Label("About", systemImage: "info")
      .labelStyle(SettingsLabelStyle(backgroundColor: .blue))
  }
}
```

A "Join the Beta" link should be added to this section, next to "Leave a
Review".

## Impact

There is currently no way for users to share the beta with others from within
the app.

## Suggested Fix

1. Define a TestFlight invite URL constant (the actual invite code needs to be
   filled in once the public link is created in App Store Connect):

```swift
private let testFlightURL = URL(string: "https://testflight.apple.com/join/dgRamw3P")!
```

2. Add a `Link` row right after "Leave a Review":

```swift
Link(destination: testFlightURL) {
  Label("Join the Beta", systemImage: "paperplane.fill")
    .labelStyle(SettingsLabelStyle(backgroundColor: .accentColor))
}
```

This matches the pattern used in Podcatcher's `SettingsView.swift`.

## Related

- Reference implementation: `~/work/podcatcher/Podcatcher/SettingsView.swift:9,126-129`
