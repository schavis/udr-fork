# TFE Release Notes Workflow: Conditional Directory Copy Implementation

**Date**: February 10, 2026  
**Status**: Proposed  
**Authors**: Infrastructure Team

---

## Issue Details

### Problem Statement

The TFE release workflow was designed to copy entire version directories for every release. With Terraform Enterprise's transition to semantic versioning (X.Y.Z), this approach is inefficient for patch releases which only need to update existing release notes rather than create new directories.

### Background

**TFE Versioning Scheme**: `MILESTONE.MAJOR.PATCH` (X.Y.Z)
- **Milestone/Major releases** (X.Y.0): Published quarterly, require new version directories
- **Patch releases** (X.Y.Z where Z > 0): Published monthly, only update existing release notes

**Directory Structure**:
```
content/terraform-enterprise/
  ├── 1.0.x/
  │   └── docs/enterprise/releases/1.0.x/index.mdx  # All 1.0.x releases
  └── 1.1.x/
      └── docs/enterprise/releases/1.1.x/index.mdx  # All 1.1.x releases
```

Release notes for an entire version series (e.g., 1.1.0, 1.1.1, 1.1.2) are maintained in a single `index.mdx` file that grows with each patch release.

### Pain Points

1. **Inefficient Operations**: Copying entire directories for patch releases wastes time and resources
2. **Single Workflow Gap**: The workflow needed to handle both major/minor and patch releases intelligently
3. **User Confusion**: No clear mechanism to distinguish between release types
4. **Workflow Validation**: Need a single, well-tested workflow path for reliability

---

## Current Design (Before Changes)

### Workflow Architecture

```
copy-cloud-docs-for-tfe.yml (Published & Validated)
├── Creates new version directory
├── Copies all files from previous version
├── Creates tfe-release/X.Y.x branch
├── Creates HCPTF-diff/X.Y.x branch
├── Syncs HCP TF documentation
└── Creates PRs

→ Used for ALL releases (no distinction between major/minor and patch)
```

### Process Flow

**For All Releases** (1.1.0, 1.1.1, 1.1.2, etc.):
1. Run `create-tfe-release-notes.yml` with appropriate checkbox state
   - Internally calls `copy-cloud-docs-for-tfe.yml`
2. Workflow completes automatically

### Issues with Current Design

| Issue | Impact |
|-------|--------|
| **No release type distinction** | All releases copy entire directories unnecessarily |
| **Inefficient for patches** | Patch releases copy hundreds of unchanged files |
| **Slower execution** | Wasted time on file operations for every release |
| **No conditional logic** | Workflow cannot adapt based on release type |

---

## Proposed Design (After Changes)

### High-Level Architecture

```
create-tfe-release-notes.yml (Single Entry Point)
├── Input: major-minor-release checkbox (default: true)
│
├── Calls: copy-cloud-docs-for-tfe.yml
│   ├── Parameter: skip-release-notes-copy = !major-minor-release
│   │
│   ├── IF skip-release-notes-copy = false (Major/Minor):
│   │   ├── Create new content/terraform-enterprise/X.Y.x/ directory
│   │   ├── Copy all files from previous version
│   │   ├── Create tfe-release/X.Y.Z branch
│   │   ├── Create HCPTF-diff/X.Y.Z branch
│   │   ├── Create new PRs
│   │   └── Sync HCP TF docs
│   │
│   └── IF skip-release-notes-copy = true (Patch):
│       ├── Validate directory exists
│       ├── Skip directory creation/copy
│       ├── Update release notes in existing X.Y.x/ directory
│       ├── Create tfe-release/X.Y.Z branch
│       ├── Create HCPTF-diff/X.Y.Z branch
│       ├── Create new PRs
│       └── Sync HCP TF docs
│
└── Generate release notes
```

### Decision Logic

```
User checks/unchecks checkbox → Single workflow handles everything

IF major-minor-release = true (CHECKED):
  skip-release-notes-copy = false
  → Major/Minor mode: Create new directory, copy files, create new branches + PRs

IF major-minor-release = false (UNCHECKED):
  skip-release-notes-copy = true
  → Patch mode: Use existing directory, update release notes, create new branches + PRs
```

### Key Design Decisions

1. **Single Workflow**: Consolidated `copy-cloud-docs-for-tfe.yml` handles both scenarios
2. **Boolean Parameter**: `skip-release-notes-copy` controls directory creation behavior
3. **Unique Branches**: Each release gets unique branches (tfe-release/X.Y.Z, HCPTF-diff/X.Y.Z)
4. **Validation**: Patch mode validates directory exists before proceeding
5. **Default Safe**: Checkbox defaults to `true` (major/minor mode) to prevent accidental skips

---

## Technical Implementation

### Modified Files

#### 1. `.github/workflows/create-tfe-release-notes.yml`

**Changes**:
- Add `major-minor-release` boolean input (default: `true`)
- Always call `copy-cloud-docs-for-tfe.yml` internally
- Pass `skip-release-notes-copy: ${{ !inputs.major-minor-release }}` parameter
- Simplify job dependencies (single copy-docs job, no conditional branching)

#### 2. `.github/workflows/copy-cloud-docs-for-tfe.yml`

**Changes**:
- Add `skip-release-notes-copy` boolean input (default: `false`)
- Enhance directory creation step with conditional logic (create new vs use existing)
- Create unique branches for each release (tfe-release/X.Y.Z format)
- Create new PRs for each release
- Add validation for patch mode (directory must exist)

---

## Usage Examples

### Example 1: Major Release (1.1.0)

**User Action**:
- Run `create-tfe-release-notes.yml`
- Version: `1.1.0`
- Major-Minor Release: ✅ **CHECKED**

**Workflow Behavior**:
- Creates new `content/terraform-enterprise/1.1.x/` directory
- Copies all files from previous version
- Creates `tfe-release/1.1.x` and `HCPTF-diff/1.1.x` branches
- Creates new PRs
- Syncs HCP TF documentation
- Generates release notes

---

### Example 2: First Patch Release (1.1.1)

**User Action**:
- Run `create-tfe-release-notes.yml`
- Version: `1.1.1`
- Major-Minor Release: ❌ **UNCHECKED**

**Workflow Behavior**:
- Validates `content/terraform-enterprise/1.1.x/` exists
- Skips directory creation
- Updates release notes in existing directory
- Creates `tfe-release/1.1.1` and `HCPTF-diff/1.1.1` branches
- Creates new PRs
- Syncs HCP TF documentation
- Appends release notes to `1.1.x/docs/enterprise/releases/1.1.x/index.mdx`

---

### Example 3: Subsequent Patch (1.1.2)

**User Action**: Same as 1.1.1 - run with checkbox unchecked

**Workflow Behavior**: Same as 1.1.1 - uses existing directory, creates new branches (tfe-release/1.1.2, HCPTF-diff/1.1.2) and PRs

---

## Error Handling

### Scenario 1: Patch Mode Without Existing Directory

**User Action**: Runs `create-tfe-release-notes.yml` for 1.1.1 with checkbox unchecked, but directory doesn't exist

**Workflow Response**: Fails with error indicating version directory must exist and suggests running with checkbox checked first

**Resolution**: Run workflow again with checkbox **CHECKED**

---

### Scenario 2: Incorrect Checkbox State

**User Action**: Runs `create-tfe-release-notes.yml` for 1.1.1 with checkbox **checked** (should be unchecked)

**Workflow Response**: Attempts to create new directory, which already exists from 1.1.0

**Resolution**: Re-run with checkbox **UNCHECKED** for patch releases

---

## Migration Path

### Implementation Steps

1. Modify `create-tfe-release-notes.yml` to add boolean input
2. Modify `copy-cloud-docs-for-tfe.yml` to add conditional logic
3. Test major/minor release scenario (1.1.0)
4. Test patch release scenario (1.1.1)
5. Update documentation
6. Deploy to production
- Leave checkbox **CHECKED** (no change from before)

**Patch Releases**:
- **UNCHECK** the `major-minor-release` checkbox
- Workflow automatically uses existing directory/branches

### Approach

Enhance existing validated workflow with conditional logic:
- Single workflow will handle both scenarios intelligently
- Backward compatible (defaults to existing behavior)
- No new workflows introduced - using proven foundation

### For Users

**Major/Minor Releases**:
- Leave checkbox **CHECKED** (no change from before)
- Creates new directory and branches

**Patch Releases**:
- **UNCHECK** the `major-minor-release` checkbox
- Uses existing directory, creates new branches for the specific patch version

### Why One Workflow?

**Reliability**: The existing `copy-cloud-docs-for-tfe.yml` is already tested and validated in production. Rather than introducing a new workflow that would require separate validation and testing, we enhanced the existing workflow with conditional logic. This approach:
- Maintains the proven workflow foundation
- Reduces testing overhead
- Ensures consistent behavior
- Minimizes risk of introducing new bugs
- Provides a single source of truth

- [TFE Release Process Documentation](../workflows/infrastructure-group/publish-tfe-docs.md)
- [Semantic Versioning Announcement](../../content/terraform-enterprise/releases/v202506-1.md)
- Modified workflows:
  - [create-tfe-release-notes.yml](../../.github/workflows/create-tfe-release-notes.yml)
  - [copy-cloud-docs-for-tfe.yml](../../.github/workflows/copy-cloud-docs-for-tfe.yml)
