# Issue Management - Action Checklist

**Quick reference for implementing issue responses and organization**

---

## ✅ Step-by-Step Actions

### Phase 1: Respond to Issues (30 minutes)

#### Issue #30 - Critical Bug (Dataflow Download)
- [ ] Go to: https://github.com/unicef-drp/unicefData/issues/30
- [ ] Add labels: `priority: high`, `type: bug`, `component: r`, `component: api`, `status: needs-review`
- [ ] Post comment from: `ISSUE_RESPONSES.md` (Issue #30 section)
- [ ] Create milestone "v2.1.1" and assign issue
- [ ] Ask contributor for PR link

#### Issue #24 - Documentation (Partial Complete)
- [ ] Go to: https://github.com/unicef-drp/unicefData/issues/24
- [ ] Add labels: `priority: medium`, `type: documentation`, `status: in-progress`, `help wanted`
- [ ] Post comment from: `ISSUE_RESPONSES.md` (Issue #24 section)
- [ ] Update issue with checklist of remaining roxygen work
- [ ] Link to v2.1.0 release notes

#### Issue #27 - Performance Research
- [ ] Go to: https://github.com/unicef-drp/unicefData/issues/27
- [ ] Add labels: `priority: low`, `type: performance`, `type: research`, `component: r`, `good first issue`
- [ ] Post comment from: `ISSUE_RESPONSES.md` (Issue #27 section)
- [ ] Encourage benchmarking work

#### Issue #26 - Feature Request (Shapefile)
- [ ] Go to: https://github.com/unicef-drp/unicefData/issues/26
- [ ] Add labels: `priority: medium`, `type: feature`, `component: r`, `component: python`, `help wanted`
- [ ] Post comment from: `ISSUE_RESPONSES.md` (Issue #26 section)
- [ ] Ask for community input on approach

---

### Phase 2: Close PR #28 (10 minutes)

- [ ] Go to: https://github.com/unicef-drp/unicefData/pull/28
- [ ] Post comment from: `PR28_CLOSING_COMMENT.md`
- [ ] Click "Close pull request"
- [ ] Reference in Issue #24 comment

---

### Phase 3: Create Milestones (5 minutes)

#### Milestone: v2.1.1
- [ ] Go to: https://github.com/unicef-drp/unicefData/milestones/new
- [ ] Title: "v2.1.1"
- [ ] Due date: 1 week from today
- [ ] Description: "Patch release - critical bug fixes"
- [ ] Add Issue #30

#### Milestone: v2.2.0
- [ ] Go to: https://github.com/unicef-drp/unicefData/milestones/new
- [ ] Title: "v2.2.0"
- [ ] Due date: March 31, 2026
- [ ] Description: "Minor release - features and enhancements"
- [ ] Add Issues #24, #26, #27

---

### Phase 4: Create Labels (15 minutes)

#### Priority Labels
- [ ] Create label: `priority: critical` (color: #d73a4a - red)
- [ ] Create label: `priority: high` (color: #ff9800 - orange)
- [ ] Create label: `priority: medium` (color: #fbca04 - yellow)
- [ ] Create label: `priority: low` (color: #0e8a16 - green)

#### Type Labels
- [ ] Create label: `type: bug` (color: #d73a4a - red)
- [ ] Create label: `type: feature` (color: #a2eeef - light blue)
- [ ] Create label: `type: enhancement` (color: #84b6eb - blue)
- [ ] Create label: `type: documentation` (color: #0075ca - dark blue)
- [ ] Create label: `type: performance` (color: #c5def5 - pale blue)
- [ ] Create label: `type: research` (color: #d4c5f9 - lavender)

#### Status Labels
- [ ] Create label: `status: in-progress` (color: #fbca04 - yellow)
- [ ] Create label: `status: blocked` (color: #b60205 - dark red)
- [ ] Create label: `status: needs-review` (color: #ff9800 - orange)
- [ ] Create label: `status: needs-info` (color: #d876e3 - purple)

#### Component Labels
- [ ] Create label: `component: python` (color: #3572A5 - python blue)
- [ ] Create label: `component: r` (color: #198CE7 - R blue)
- [ ] Create label: `component: stata` (color: #1a5490 - stata blue)
- [ ] Create label: `component: api` (color: #fbca04 - yellow)
- [ ] Create label: `component: tests` (color: #0e8a16 - green)

#### Help Labels
- [ ] Create label: `good first issue` (color: #7057ff - purple)
- [ ] Create label: `help wanted` (color: #008672 - teal)

**Quick way:** Go to https://github.com/unicef-drp/unicefData/labels and create all labels

---

### Phase 5: Create Issue Templates (20 minutes)

#### Bug Report Template
- [ ] Create file: `.github/ISSUE_TEMPLATE/bug_report.md`
- [ ] Copy content from: `ISSUE_MANAGEMENT_PLAN.md` (Bug Report section)
- [ ] Commit and push

#### Feature Request Template
- [ ] Create file: `.github/ISSUE_TEMPLATE/feature_request.md`
- [ ] Copy content from: `ISSUE_MANAGEMENT_PLAN.md` (Feature Request section)
- [ ] Commit and push

#### Documentation Template
- [ ] Create file: `.github/ISSUE_TEMPLATE/documentation.md`
- [ ] Copy content from: `ISSUE_MANAGEMENT_PLAN.md` (Documentation section)
- [ ] Commit and push

---

### Phase 6: Update Documentation (15 minutes)

#### Update CONTRIBUTING.md
- [ ] Add "Reporting Issues" section
- [ ] Link to issue templates
- [ ] Explain label system
- [ ] Commit and push

#### Create SUPPORT.md
- [ ] Create new file: `SUPPORT.md`
- [ ] Add support information
- [ ] Link from README.md
- [ ] Commit and push

#### Update README.md
- [ ] Add "Support & Issues" section
- [ ] Link to issue templates
- [ ] Link to SUPPORT.md
- [ ] Commit and push

---

## 📊 Progress Tracking

**Phase 1:** ☐ Respond to Issues (0/4)
**Phase 2:** ☐ Close PR #28
**Phase 3:** ☐ Create Milestones (0/2)
**Phase 4:** ☐ Create Labels (0/17)
**Phase 5:** ☐ Create Templates (0/3)
**Phase 6:** ☐ Update Docs (0/3)

**Overall:** 0/30 tasks complete

---

## 🎯 Priority Order (If Short on Time)

**Must Do (30 min):**
1. Respond to Issue #30 (critical bug)
2. Close PR #28
3. Create v2.1.1 milestone

**Should Do (45 min):**
4. Respond to Issues #24, #26, #27
5. Create priority labels
6. Create type labels

**Nice to Have (45 min):**
7. Create status/component labels
8. Create issue templates
9. Update documentation

---

## 📝 Copy-Paste Resources

**All responses ready in:**
- `ISSUE_RESPONSES.md` - Individual issue responses
- `PR28_CLOSING_COMMENT.md` - PR closing comment
- `ISSUE_MANAGEMENT_PLAN.md` - Full organization plan

**GitHub Label Creation (Quick Copy):**
```bash
# Priority labels
priority: critical #d73a4a
priority: high #ff9800
priority: medium #fbca04
priority: low #0e8a16

# Type labels
type: bug #d73a4a
type: feature #a2eeef
type: enhancement #84b6eb
type: documentation #0075ca
type: performance #c5def5
type: research #d4c5f9

# Component labels
component: python #3572A5
component: r #198CE7
component: stata #1a5490
component: api #fbca04
component: tests #0e8a16
```

---

## ✅ Completion Checklist

When all done:
- [ ] All 4 issues have responses
- [ ] PR #28 is closed
- [ ] Milestones created (v2.1.1, v2.2.0)
- [ ] Labels created and applied
- [ ] Issue templates in place
- [ ] Documentation updated
- [ ] Commit message: "chore: implement issue management system and respond to all open issues"

---

**Estimated total time:** 1.5 - 2 hours

**Let me know when you're ready to start, and I can help with specific steps!**
