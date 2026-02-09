# Issue Management & Organization Plan

---

## 🎯 Current Issue Inventory

| # | Title | Status | Priority | Category | Target |
|---|-------|--------|----------|----------|--------|
| #30 | Dataflow Download Problems | 🔴 Open | HIGH | Bug | v2.1.1 |
| #24 | Documentation & Navigation | 🟡 Partial | MEDIUM | Docs | v2.2.0 |
| #27 | data.table Backend | 🔵 Open | LOW | Performance | v2.2.0+ |
| #26 | Indicator Map Function | 🔵 Open | MEDIUM | Feature | v2.2.0 |

---

## 📊 Issue Organization Strategy

### 1. **Label System** (Implement These)

#### Priority Labels
- `priority: critical` - 🔴 Blocking, data loss, security
- `priority: high` - 🟠 Core functionality broken
- `priority: medium` - 🟡 Important but has workaround
- `priority: low` - 🔵 Nice to have

#### Type Labels
- `type: bug` - Something broken
- `type: feature` - New functionality request
- `type: enhancement` - Improvement to existing feature
- `type: documentation` - Docs improvement
- `type: performance` - Speed/memory optimization
- `type: research` - Investigation/exploration task

#### Status Labels
- `status: in-progress` - Actively being worked on
- `status: blocked` - Waiting on dependency
- `status: needs-review` - Ready for code review
- `status: needs-info` - Waiting for reporter response

#### Component Labels
- `component: python` - Python-specific
- `component: r` - R-specific
- `component: stata` - Stata-specific
- `component: api` - SDMX API interaction
- `component: tests` - Testing infrastructure

#### Help Labels
- `good first issue` - Great for newcomers
- `help wanted` - Need community assistance

---

## 📋 Apply Labels to Current Issues

### Issue #30: Dataflow Download Problems
```
Labels to add:
- priority: high
- type: bug
- component: r
- component: api
- status: needs-review
```

### Issue #24: Documentation & Navigation
```
Labels to add:
- priority: medium
- type: documentation
- status: in-progress
- help wanted
```

### Issue #27: data.table Backend
```
Labels to add:
- priority: low
- type: performance
- type: research
- component: r
- good first issue (for benchmarking)
```

### Issue #26: Indicator Map Function
```
Labels to add:
- priority: medium
- type: feature
- component: r
- component: python
- help wanted
```

---

## 🗂️ Milestones to Create

### v2.1.1 (Patch Release)
**Target:** Within 1 week
**Focus:** Critical bug fixes

**Issues:**
- #30 - Dataflow download bugs

### v2.2.0 (Minor Release)
**Target:** March 2026
**Focus:** Features & enhancements

**Issues:**
- #24 - Complete roxygen standardization
- #26 - Spatial/shapefile export (if ready)
- #27 - data.table backend (if benchmarks positive)

### v3.0.0 (Major Release)
**Target:** Q2 2026
**Focus:** Breaking changes & major features

**Potential:**
- API redesign
- New backends
- Major performance overhaul

---

## 📝 Issue Templates to Create

### 1. Bug Report Template

Create `.github/ISSUE_TEMPLATE/bug_report.md`:

```markdown
---
name: Bug Report
about: Report a bug or unexpected behavior
labels: type: bug
---

## Bug Description
A clear description of what the bug is.

## To Reproduce
Steps to reproduce the behavior:
1. Run code: `unicefData(...)`
2. See error

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened (include error messages).

## Environment
- **Platform:** Python / R / Stata
- **Version:** (e.g., unicefData 2.1.0)
- **OS:** Windows / macOS / Linux
- **R version:** (if R) - `R.version.string`
- **Python version:** (if Python) - `python --version`

## Reproducible Example
```r
# Minimal code to reproduce the issue
library(unicefData)
unicefData(...)
```

## Additional Context
Any other information about the problem.
```

### 2. Feature Request Template

Create `.github/ISSUE_TEMPLATE/feature_request.md`:

```markdown
---
name: Feature Request
about: Suggest a new feature or enhancement
labels: type: feature
---

## Feature Description
A clear description of the feature you'd like to see.

## Use Case
Explain how this feature would be used and who would benefit.

## Proposed Solution
Describe how you envision this working.

**Example usage:**
```r
# How the feature would be used
unicefData_spatial(indicator = "CME_MRY0T4", ...)
```

## Alternatives Considered
What other solutions or workarounds have you considered?

## Additional Context
Any other information or screenshots.
```

### 3. Documentation Improvement Template

Create `.github/ISSUE_TEMPLATE/documentation.md`:

```markdown
---
name: Documentation Improvement
about: Suggest improvements to docs or examples
labels: type: documentation
---

## What Needs Improvement
Which documentation is unclear or missing?

## Current Documentation
Where is the current documentation (link or file)?

## Suggested Improvement
How should it be improved?

## Additional Context
Any examples or references?
```

---

## 🔄 Issue Triage Process

### Weekly Triage Checklist

**Every Monday:**
1. ✅ Review new issues (label, prioritize, assign)
2. ✅ Check for stale issues (no activity >30 days)
3. ✅ Update milestone assignments
4. ✅ Respond to blocked issues
5. ✅ Close resolved/duplicate issues

### Issue Response SLA

| Priority | First Response | Resolution Target |
|----------|----------------|-------------------|
| Critical | 24 hours | 1 week |
| High | 48 hours | 2 weeks |
| Medium | 1 week | 1 month |
| Low | 2 weeks | Best effort |

---

## 📊 Project Board Setup

### Create GitHub Project Board

**Columns:**
1. **Backlog** - Not yet prioritized
2. **To Do** - Prioritized, ready to start
3. **In Progress** - Actively being worked on
4. **Review** - Awaiting code review
5. **Testing** - In testing phase
6. **Done** - Completed & merged

**Automation:**
- New issues → Backlog
- Assigned → To Do
- PR opened → Review
- PR merged → Done

---

## 🎯 Current Action Plan

### Immediate (This Week)

**Issue #30 - Critical Bug:**
1. ✅ Add labels: `priority: high`, `type: bug`, `component: r`, `component: api`
2. ✅ Post response from ISSUE_RESPONSES.md
3. ✅ Create milestone: v2.1.1
4. ✅ Assign to @liuyanguu
5. ✅ Request PR link from contributor
6. ✅ Review and merge fix
7. ✅ Release v2.1.1 patch

**Issue #24 - Documentation:**
1. ✅ Add labels: `priority: medium`, `type: documentation`, `status: in-progress`
2. ✅ Post response acknowledging v2.1.0 progress
3. ✅ Update issue description with checklist
4. ✅ Keep open for roxygen work
5. ✅ Close PR #28 as superseded

### Short Term (This Month)

**Issue #27 - Performance:**
1. ✅ Add labels: `priority: low`, `type: performance`, `type: research`
2. ✅ Post response with benchmarking approach
3. ✅ Encourage @lucashertzog to share benchmark results
4. ✅ Create `benchmarks/` directory in repo

**Issue #26 - Feature Request:**
1. ✅ Add labels: `priority: medium`, `type: feature`, `help wanted`
2. ✅ Post response with implementation options
3. ✅ Ask community for input on approach
4. ✅ Create v2.2.0 milestone if feasible

### Medium Term (Next Quarter)

1. ✅ Implement issue templates
2. ✅ Create GitHub project board
3. ✅ Set up automated label workflows
4. ✅ Establish triage schedule
5. ✅ Document contribution process

---

## 📚 Documentation Updates Needed

### 1. CONTRIBUTING.md

Add section:
```markdown
## Reporting Issues

Before creating an issue:
1. Search existing issues
2. Use appropriate issue template
3. Provide reproducible example
4. Include environment details

Issue templates:
- Bug Report
- Feature Request
- Documentation Improvement
```

### 2. README.md

Add section:
```markdown
## Support & Issues

- **Bug reports:** Use [bug report template]
- **Feature requests:** Use [feature request template]
- **Questions:** Check [discussions] first
- **Security:** Email jpazevedo@unicef.org
```

### 3. Create SUPPORT.md

```markdown
# Support

## Getting Help

- **Documentation:** See README files in each platform directory
- **Examples:** Check `examples/` directory
- **FAQ:** See wiki
- **Community:** GitHub Discussions

## Reporting Issues

See CONTRIBUTING.md for issue reporting guidelines.

## Security Issues

Report security vulnerabilities to: jpazevedo@unicef.org
Do not create public issues for security problems.
```

---

## 🔧 GitHub Settings to Configure

### Repository Settings

**Issues:**
- ✅ Enable issue templates
- ✅ Enable discussions
- ✅ Set default labels

**Pull Requests:**
- ✅ Require PR reviews (1 approver)
- ✅ Require status checks to pass
- ✅ Require up-to-date branches
- ✅ Auto-delete head branches

**Branches:**
- ✅ Protect `main` (require PR)
- ✅ Protect `develop` (require tests)
- ✅ Allow `stage` direct pushes (for sync)

---

## 📈 Success Metrics

Track monthly:
- **Issue close rate:** >70% of new issues closed within 30 days
- **Response time:** <48 hours for first response
- **Bug fix time:** <7 days for critical, <14 days for high
- **Documentation coverage:** All functions have roxygen docs
- **Community engagement:** Issues with community contributions

---

## 🎯 Summary: Immediate Actions

1. **Label all 4 issues** (see label assignments above)
2. **Post responses** from ISSUE_RESPONSES.md
3. **Create milestones:** v2.1.1, v2.2.0
4. **Close PR #28** with comment from PR28_CLOSING_COMMENT.md
5. **Create issue templates** (3 templates)
6. **Update CONTRIBUTING.md** with issue guidelines

**Time estimate:** 2-3 hours for full setup

---

**Ready to implement? I can help with any of these steps!**
