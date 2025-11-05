# GitHub Action Workflow Behavior Summary

## Build Strategy: Fail-Safe with Overall Failure Reporting

### How it Works:

1. **🔍 Discovery Phase** (`discover-samples` job):
   - Automatically finds all sample directories with `package.json` files
   - Creates a matrix of samples to build

2. **🔨 Build Phase** (`build-samples` job):
   - **Parallel Execution**: All samples build simultaneously using GitHub's matrix strategy
   - **Continue on Error**: Each individual build can fail without stopping other builds (`continue-on-error: true`)
   - **No Fail-Fast**: Uses `fail-fast: false` so one failure doesn't cancel remaining builds
   - **Result Tracking**: Each build saves its success/failure status to an artifact

3. **📊 Summary Phase** (`build-summary` job):
   - **Always Runs**: Uses `if: always()` to run even if some builds failed
   - **Collects Results**: Downloads all build result artifacts
   - **Dual Failure Detection**:
     - Checks the overall job status from the matrix builds
     - Counts individual success/failure result files
   - **Workflow Status**: Fails the entire workflow (`exit 1`) if ANY build failed

### Key Behaviors:

✅ **All builds run to completion** - One failing build doesn't stop others
✅ **Workflow fails if any build fails** - Overall GitHub Action shows red ❌ status
✅ **Detailed reporting** - Shows which specific samples succeeded/failed
✅ **Parallel execution** - Fast builds due to matrix strategy
✅ **Comprehensive logging** - Individual job logs for debugging failures

### Example Scenarios:

**Scenario 1: All builds succeed**
- All samples build successfully
- Workflow status: ✅ **SUCCESS**
- Summary shows: "🎉 All builds successful!"

**Scenario 2: Some builds fail**
- 2 out of 4 samples fail to build
- All 4 samples are attempted (no early termination)
- Workflow status: ❌ **FAILED**
- Summary shows: "⚠️ Some builds failed! Check the individual job logs for details."
- Individual job logs show specific failure reasons

**Scenario 3: All builds fail**
- All samples fail to build
- All samples are attempted
- Workflow status: ❌ **FAILED**
- Each failure reason is available in job logs

This meets your requirement: **"Report as failed if any builds fail, but don't let one build stop checking all builds."**