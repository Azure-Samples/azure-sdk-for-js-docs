# Build Process

This repository includes automated build validation for all samples through GitHub Actions and local scripts.

## GitHub Action

The repository includes a comprehensive GitHub Action (`.github/workflows/build-samples.yml`) that:

1. **Discovers all samples** - Automatically finds all directories containing `package.json` files in the `samples/` folder
2. **Builds each sample** - Uses a matrix strategy to build all samples in parallel
3. **Reports results** - Provides detailed success/failure reporting with:
   - Individual build status for each sample
   - Summary statistics
   - Detailed job logs for debugging failures

### Trigger Events

The build action runs on:
- Push to `main` or `develop` branches
- Pull requests to `main` branch
- Manual workflow dispatch

### Build Strategy

For each sample, the action:
1. Installs dependencies with `npm ci`
2. Determines the appropriate build method:
   - If `npm run build` exists, uses that
   - If `tsconfig.json` exists, runs `npx tsc --noEmit`
   - If TypeScript files exist, validates syntax with TypeScript compiler
   - If no TypeScript files found, reports success

## Local Testing

You can test builds locally before pushing using the provided script:

### Bash Script (Linux/macOS/WSL/Git Bash)
```bash
# Make script executable
chmod +x build-samples.sh

# Run the build script
./build-samples.sh
# OR
npm run build:samples
```

### Individual Sample Building

To build a specific sample:
```bash
cd samples/path/to/sample
npm ci
npm run build  # if available, otherwise npx tsc --noEmit
```

## Build Output

Both the GitHub Action and local script provide:
- ✅ Success indicators for working builds
- ❌ Failure indicators for broken builds
- 📊 Summary statistics
- 📝 Detailed results for each sample

The GitHub Action also creates downloadable artifacts containing build results and provides rich summary reports in the Actions UI.

## Troubleshooting

If a build fails:
1. Check the detailed logs in the GitHub Actions run
2. Run the local build script to reproduce the issue
3. Navigate to the specific sample directory and run the build commands manually
4. Check for missing dependencies or TypeScript compilation errors

## Adding New Samples

When adding new samples:
1. Ensure the sample has a `package.json` file
2. Include appropriate dependencies in the package.json
3. Add a `build` script if custom build steps are needed
4. Test locally with the build scripts before committing

The GitHub Action will automatically discover and build new samples once they're added to the repository.