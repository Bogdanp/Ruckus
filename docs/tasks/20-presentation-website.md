# Presentation Website

## Summary

Create a simple presentation/landing website for the Ruckus app and host it
via GitHub Pages. The site should live under `website/` in the repo root and
showcase what the app does, with screenshots and a link to the App Store (or
TestFlight) once available.

## Affected Code

### `website/` (new directory)

This is a new addition — no existing code is affected.

## Impact

The app currently has no web presence. A landing page helps with
discoverability, provides a place to link from social media or documentation,
and is expected by the App Store review team.

## Suggested Fix

1. Create a `website/` directory at the repo root.
2. Add a static site (plain HTML/CSS or a minimal generator like Jekyll,
   which GitHub Pages supports natively).
3. Include at minimum:
   - Hero section with app icon, name, and tagline.
   - Feature highlights (brief descriptions + screenshots/mockups).
   - Download / TestFlight CTA button.
   - Footer with links (GitHub repo, privacy policy placeholder).
4. Add a GitHub Actions workflow (or configure the repo settings) to deploy
   from `website/` to GitHub Pages.
5. Add a `CNAME` file if a custom domain is desired later.

### Hosting setup

Configure GitHub Pages to serve from the `website/` directory on the `master`
branch (or use a `gh-pages` branch with a deploy action). The simplest option
is **Settings → Pages → Source → Deploy from a branch**, pointing at
`/website`.

## Related

- No related tasks.
