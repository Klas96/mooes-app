# GitHub Pages Setup for Mooves Web

This guide explains how to deploy the Flutter web version of Mooves to GitHub Pages.

## Prerequisites

1. A GitHub repository (e.g., `username/mooves` or `username/username.github.io`)
2. GitHub Actions enabled in your repository
3. GitHub Pages enabled in repository settings

## Setup Steps

### 1. Enable GitHub Pages

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Pages**
3. Under **Source**, select:
   - **Deploy from a branch**: Choose `gh-pages` branch and `/ (root)` folder
   - OR use **GitHub Actions** (recommended - the workflow handles this automatically)

### 2. Configure Base Href

The base href in the workflow is set to `/mooves/` by default. Adjust this based on your GitHub Pages URL:

- **If your repo is `username/mooves`**: Use `/mooves/` (default)
- **If your repo is `username.github.io`**: Use `/`
- **If your repo is `username.github.io/mooves`**: Use `/mooves/`

To change it, edit `.github/workflows/deploy-web.yml` and update the `--base-href` parameter:

```yaml
run: flutter build web --release --base-href /mooves/
```

### 3. Deploy

The workflow will automatically deploy when you:
- Push to `main` or `master` branch
- Manually trigger it from the Actions tab

## Manual Deployment

If you want to deploy manually:

```bash
cd mooves-frontend
flutter pub get
flutter build web --release --base-href /mooves/
# Then copy build/web/* to your gh-pages branch
```

## Accessing Your Site

After deployment, your site will be available at:
- `https://username.github.io/mooves/` (if repo is `username/mooves`)
- `https://username.github.io/` (if repo is `username.github.io`)

## Troubleshooting

### 404 Errors

- Check that the base href matches your GitHub Pages URL structure
- Ensure GitHub Pages is enabled in repository settings
- Wait a few minutes after deployment for changes to propagate

### Assets Not Loading

- Verify the base href is correct
- Check browser console for 404 errors
- Ensure all assets are included in the build

### Build Failures

- Check the Actions tab for error logs
- Ensure Flutter is properly installed in the workflow
- Verify all dependencies are listed in `pubspec.yaml`

## Notes

- The workflow uses Flutter 3.24.0 stable channel
- Builds are cached for faster deployments
- The workflow only runs when files in `mooves-frontend/` change

