# PRD — B2C Growth Operating System MVP

**Product Name:** B2C Growth Operating System  
**MVP Focus:** KPI Tracker  
**Prepared For:** MAPID B2C Growth Team  
**Version:** v1.0  
**Format:** Markdown PRD  
**Design Direction:** Apple / Jony Ive-inspired — calm, minimal, spacious, contextual, and low-friction  

---

## 1. Executive Summary

B2C Growth Operating System adalah web internal untuk membantu tim B2C MAPID bekerja lebih transparan, disiplin, dan terukur. MVP pertama akan difokuskan pada **KPI Tracker**, karena masalah paling mendesak saat ini adalah tracking KPI per role yang masih sulit dilakukan secara konsisten.

Walaupun MVP hanya membangun KPI Tracker secara fungsional, struktur front-end sudah disiapkan sebagai operating system yang lebih luas. Nantinya sistem dapat dikembangkan menjadi beberapa module lain seperti **Campaign Library**, **Business Performance History**, dan **Intern Learning Journey**.

Prinsip utama produk ini adalah:

> Build the habit first. Expand the system later.

MVP tidak boleh menjadi sistem administrasi yang berat. Sistem harus membuat setiap anggota tim dapat melihat KPI, mengisi progress mingguan, memahami status, mencatat blocker, dan menyiapkan weekly review dengan cepat dan jelas.

---

## 2. Background & Context

Tim B2C MAPID sudah memiliki operating system, pembagian role, KPI per role, weekly cadence, dan prinsip kerja seperti single source of truth, weekly review, blocker visibility, dan evaluation loop.

Namun, problem utamanya adalah:

1. KPI tracking belum disiplin.
2. Setiap role belum punya satu tempat yang jelas untuk update KPI.
3. Growth Lead masih perlu melakukan reminder manual.
4. Data KPI mingguan sulit dibaca secara historis.
5. KPI yang berbentuk persentase sering hanya diinput angka final tanpa konteks pembentuknya.
6. Weekly review berisiko menjadi diskusi panjang berbasis cerita, bukan berbasis data.

Sistem ini dibangun untuk mengubah KPI tracking dari sekadar template manual menjadi **ritual mingguan yang mudah diikuti**.

---

## 3. Problem Statement

### 3.1 Main Problem

Tim B2C membutuhkan satu sistem sederhana untuk melihat dan mengisi KPI per role secara transparan setiap minggu, tanpa menambah beban administrasi yang berat.

### 3.2 Specific Problems

#### A. KPI Tracking Tidak Konsisten

Saat ini tracking KPI sudah dicoba di fase manual, tetapi masih belum disiplin. Problemnya bukan hanya tidak ada template, tetapi experience tracking belum cukup mendorong tim untuk update secara rutin.

#### B. Data KPI Kurang Transparan

Growth Lead sulit melihat status KPI semua role dalam satu tampilan. Team member juga tidak selalu bisa melihat kondisi role lain secara jelas.

#### C. KPI Persentase Tidak Memiliki Konteks

Contoh: Follow-up Rate 76% tidak cukup informatif jika sistem tidak tahu:

- total leads berapa,
- leads yang difollow-up berapa,
- skala masalahnya besar atau kecil.

Sistem harus menyimpan komponen pembentuk KPI, bukan hanya angka final.

#### D. Historical Progress Belum Terjaga

Jika setiap minggu data bisa diedit bebas tanpa status historis, maka quarter trend menjadi tidak dapat dipercaya. Sistem harus bisa membedakan antara current editable week dan historical locked week.

#### E. Weekly Review Kurang Terstruktur

Weekly review perlu dimulai dari data: KPI status, blocker, next action, dan decision log. Bukan update verbal panjang.

---

## 4. Product Goals

### 4.1 Primary Goals

1. Membuat KPI tracking per role menjadi mudah, jelas, dan transparan.
2. Mengurangi kebutuhan Growth Lead untuk menagih update manual.
3. Membuat setiap role tahu KPI yang harus diupdate setiap minggu.
4. Menyimpan historical KPI per minggu untuk melihat progress quarter.
5. Menyediakan input KPI yang sesuai konteks, bukan hanya input angka final.
6. Membantu weekly review berjalan lebih singkat dan berbasis data.

### 4.2 Secondary Goals

1. Membangun habit weekly KPI check-in.
2. Membuat blocker terlihat lebih awal.
3. Menyediakan basis untuk monthly review.
4. Mempersiapkan arsitektur produk untuk module growth lain di masa depan.
5. Membuat sistem internal terasa premium dan nyaman digunakan.

---

## 5. Non-Goals

MVP ini **tidak** akan membangun semua kebutuhan B2C sekaligus.

### 5.1 Not Included in MVP

1. Personal login per user.
2. Role-based permission yang kompleks.
3. Campaign Library yang fungsional.
4. A/B Testing Tracker yang fungsional.
5. Business Performance integration.
6. Intern Learning Journey workflow.
7. GA4 integration.
8. Meta Ads integration.
9. WhatsApp automation.
10. AI summary.
11. Full task management system.
12. Comment thread.
13. Approval workflow.
14. Daily reporting.
15. Complex analytics or forecasting.

### 5.2 Product Constraint

MVP harus tetap fokus pada:

- KPI clarity,
- weekly transparency,
- historical tracking,
- blocker visibility,
- review readiness.

---

## 6. Product Positioning

### 6.1 Product Framing

Produk ini bukan sekadar KPI dashboard.

Produk ini adalah:

> B2C Growth Operating System — an internal operating surface for growth discipline.

### 6.2 MVP Framing

MVP pertama adalah:

> KPI Tracker — a weekly accountability system for role-based KPI transparency.

### 6.3 Future Product Architecture

Walaupun MVP hanya KPI Tracker, front-end akan menampilkan shell module berikut:

1. KPI Tracker — active MVP.
2. Campaign Library — planned module.
3. Business Performance History — planned module.
4. Intern Learning Journey — planned module.

---

## 7. Users & Access Model

### 7.1 Access Model

Sistem menggunakan **shared login / shared account** untuk seluruh tim B2C.

Alasan:

1. Lebih mudah dikembangkan.
2. Cocok untuk MVP dan tim kecil.
3. Mendukung transparansi.
4. Tidak perlu user management kompleks.
5. Mengurangi development overhead.

### 7.2 Role Owners

| Role | Owner | Main Need |
|---|---|---|
| Growth Marketing | Dwi | Melihat team health, revenue, blocker, dan weekly priority |
| Activation Specialist | Wina | Update lead, response, follow-up, dan community activation |
| Learning Operation | Fariz | Update readiness, delivery, learner health, dan improvement loop |
| Graphic Designer & Editor | Annisa | Update asset delivery, readiness, production, dan revision efficiency |

### 7.3 Updated By Field

Karena menggunakan shared login, setiap update KPI harus memiliki field **Updated By**.

Options:

- Dwi
- Wina
- Fariz
- Annisa
- Other

Field ini bukan untuk permission, tetapi untuk lightweight audit clarity.

---

## 8. Product Principles

### 8.1 Transparency Without Fear

Sistem harus membuat status KPI terbuka tanpa terasa seperti alat menghukum.

Gunakan wording:

- On track
- Needs attention
- Off track
- Blocker
- Next action

Hindari wording:

- Failed
- Bad performance
- Underperforming
- Violation

### 8.2 Five-Minute Weekly Update

Setiap role harus bisa mengupdate KPI dalam waktu maksimal 5 menit per minggu.

Jika lebih lama, sistem akan terasa seperti beban administrasi.

### 8.3 Contextual KPI Input

Input KPI harus mengikuti cara KPI itu terbentuk di dunia nyata.

Contoh:

- Follow-up Rate tidak diinput sebagai 76%.
- User menginput total leads dan leads followed up.
- Sistem menghitung percentage otomatis.

### 8.4 Current Week Editable, Historical Week Locked

Current week boleh diedit sampai weekly review selesai. Setelah weekly review completed, data minggu tersebut menjadi locked historical record.

### 8.5 One Screen, One Purpose

Setiap screen harus menjawab satu pertanyaan utama.

Contoh:

- Home: Apa sistem ini dan module mana yang aktif?
- KPI Dashboard: Bagaimana kondisi tim minggu ini?
- KPI Tracking: Apa progress KPI tiap role?
- KPI History: Apakah KPI membaik dari minggu ke minggu?
- Weekly Review: Apa yang perlu diputuskan minggu ini?

### 8.6 Restraint Over Complexity

Jangan membangun fitur hanya karena bisa dibangun.

MVP harus memprioritaskan habit dan clarity, bukan kelengkapan sistem.

---

## 9. Information Architecture

### 9.1 Primary Navigation

Navbar utama harus sederhana dan tidak terlalu packed.

Top-level navigation:

1. Home
2. KPI Tracker
3. Campaign Library
4. Business Performance
5. Learning Journey

### 9.2 KPI Sub-Navigation

Sub-navigation KPI hanya muncul saat user berada di area KPI Tracker.

KPI sub-nav:

1. Dashboard
2. Tracking
3. History
4. Review
5. Monthly
6. Settings

### 9.3 Rationale

Pendekatan dua level navigation dipilih karena:

1. Navbar utama tetap clean.
2. Module masa depan tetap terlihat.
3. KPI detail tidak memenuhi primary navigation.
4. UI terasa lebih Apple-like: contextual, restrained, dan tidak over-explained.

---

## 10. Module Overview

## 10.1 Home

### Purpose

Menjelaskan bahwa sistem ini adalah B2C Growth Operating System, dengan KPI Tracker sebagai MVP aktif dan module lain sebagai planned shell.

### Components

1. Product title and description.
2. Active MVP module card.
3. Planned module cards.
4. MVP strategy note.

### Module Cards

#### KPI Tracker

Status: Active MVP

Features:

- Weekly KPI tracking
- Target vs actual history
- Blocker & next action visibility

CTA: Open KPI Dashboard

#### Campaign Library

Status: Planned Module

Future features:

- Campaign archive
- A/B test tracker
- Result and learning log

#### Business Performance History

Status: Planned Module

Future features:

- Revenue by product
- Funnel performance trend
- Quarterly business recap

#### Intern Learning Journey

Status: Planned Module

Future features:

- Learning milestones
- Assignment progress
- Readiness evaluation

---

## 11. KPI Tracker Module

KPI Tracker adalah satu-satunya module yang dibangun secara fungsional pada MVP.

Sub-pages:

1. KPI Dashboard
2. KPI Tracking
3. KPI History
4. Weekly Review
5. Monthly Review
6. Settings / KPI Setup

---

# 12. KPI Dashboard Page

## 12.1 Purpose

Memberikan overview kondisi KPI seluruh role dalam selected week.

## 12.2 Main Question

> Are we on track this week?

## 12.3 Components

### A. Week Selector

User dapat memilih minggu:

- current week,
- previous week,
- planned week.

Week memiliki status:

| Status | Meaning |
|---|---|
| Current | Editable sampai weekly review completed |
| Locked | Historical record, view-only |
| Planned | Future week, belum ada data |

### B. Week Status Banner

Menampilkan apakah week sedang editable atau locked.

Example:

- Current editable week
- Historical week locked
- Planned week

### C. KPI Health Summary

Cards:

1. KPI Updated
2. On Track
3. Needs Attention
4. Off Track
5. Pending Update

### D. Role Cards

Setiap role memiliki card dengan informasi:

- Role name
- Owner
- Green / Yellow / Red count
- Main blocker
- Next action
- CTA: View / Update KPI

### E. KPI Needing Attention

Menampilkan KPI yellow/red.

Untuk calculated rate, tampilkan:

- final percentage,
- numerator / denominator,
- blocker.

Example:

> Follow-up Completion Rate  
> 31 / 49 · 63% · Overcapacity

### F. Blocker Pattern

Menampilkan blocker yang paling sering muncul di selected week.

---

## 12.4 Acceptance Criteria

1. User bisa memahami kondisi KPI tim dalam 10 detik.
2. User bisa melihat role mana yang butuh perhatian.
3. User bisa melihat blocker utama minggu tersebut.
4. User bisa masuk ke KPI Tracking dari role card.
5. Historical week terlihat locked dan tidak misleading.

---

# 13. KPI Tracking Page

## 13.1 Purpose

Memberikan tempat untuk mengisi dan melihat KPI progress per role.

## 13.2 Main Question

> What is the actual KPI progress for this role this week?

## 13.3 Components

### A. Week Context

Menampilkan apakah selected week editable atau locked.

- Current week: editable.
- Locked week: view-only.

### B. Role Filter

Options:

- All Roles
- Growth Marketing
- Activation Specialist
- Learning Operation
- Graphic Designer & Editor

### C. KPI Table

Columns:

| Column | Description |
|---|---|
| Role | Role owner |
| KPI | KPI name and description |
| Input Structure | Direct input / calculated rate / checklist / status |
| Actual | Final value + formula/context |
| Status | On track / Needs attention / Off track / Pending |
| Blocker | Main blocker |
| Action | Edit or Locked |

### D. Edit KPI Modal

Modal menampilkan:

1. KPI name
2. KPI description
3. Target
4. Current result
5. Status preview
6. Contextual input field
7. Notes
8. Blocker
9. Updated by
10. Next action
11. Save button

---

## 13.4 Contextual KPI Input Types

### A. Direct Currency Input

Used for:

- Total B2C Revenue
- Revenue from Personal License + Assisted

Input:

- Actual revenue

Output:

- Currency value
- Status based on target

### B. Direct Number Input

Used for:

- Qualified Leads Generated
- WA / Community Activation Consistency
- Weekly Production Consistency

Input:

- Actual number

Output:

- Number + unit
- Status based on target

### C. Direct Number Input — Lower Is Better

Used for:

- Revision Efficiency

Input:

- Average revision cycle

Logic:

- Green: actual <= target
- Yellow: actual = target + 1
- Red: actual > target + 1

### D. Calculated Rate Input

Used for percentage KPI.

Input:

- Numerator
- Denominator

Output:

- Percentage
- Numerator / denominator context

Example:

Follow-up Completion Rate:

- Completed follow-up: 31
- Leads requiring follow-up: 49
- System output: 63%

### E. Status Selection

Used for operational qualitative KPI.

Options:

- On Track
- Needs Attention
- Off Track

Used for:

- Weekly Operating System Consistency
- On-time Program Readiness
- On-time Program Delivery
- Asset Readiness for P0 Campaign

### F. Checklist Progress

Used for KPI that requires sequential operational completion.

Example:

Feedback-to-Improvement Loop checklist:

- Feedback collected
- Key issue summarized
- Improvement action defined
- Owner assigned

System output:

- completed items / total items
- percentage progress

---

## 13.5 Yellow / Red Requirement

If KPI status is Yellow or Red, user must fill:

1. Blocker
2. Next Action

Reason:

Yellow/Red KPI should not become passive reporting. It must lead to action.

---

## 13.6 Acceptance Criteria

1. User can update a KPI in under 30 seconds.
2. Percentage KPI is calculated, not manually typed.
3. System displays numerator and denominator.
4. Yellow/Red KPI requires blocker and next action.
5. Locked week cannot be edited.
6. Target does not need to be retyped every week.

---

# 14. KPI History Page

## 14.1 Purpose

Menampilkan trend KPI dari minggu ke minggu untuk melihat quarter progress.

## 14.2 Main Question

> Is this KPI improving, declining, or staying flat across the quarter?

## 14.3 Components

### A. Role Filter

Options:

- All Roles
- Specific role

### B. KPI Selector

User memilih KPI yang ingin dianalisis.

### C. Trend Chart

Chart menampilkan:

- Actual value per week
- Target value

For calculated rate:

- actual percentage
- target percentage

### D. Status History

List per week:

- week label
- actual
- target
- status

### E. Historical Correction Note

Prototype note:

Historical correction should be possible in the final app, but not as free edit. It should require a correction reason.

---

## 14.4 Historical Data Rule

| Week Type | Editable? | Rule |
|---|---|---|
| Current week | Yes | Editable until weekly review completed |
| Locked week | No | View-only historical record |
| Historical correction | Limited | Requires correction reason in future version |
| Planned week | No | No data yet |

---

## 14.5 Acceptance Criteria

1. User can select a KPI and see weekly trend.
2. User can compare actual vs target.
3. User can see weekly status history.
4. Locked historical data cannot be freely edited.
5. Trend supports quarterly review.

---

# 15. Weekly Review Page

## 15.1 Purpose

Membantu Growth Lead menjalankan weekly review dari satu halaman.

## 15.2 Main Question

> What needs to be discussed, decided, and prioritized for next week?

## 15.3 Components

### A. Revenue & Funnel Section

Manual fields:

- Revenue Total
- Leads In
- Follow-up Rate
- Conversion Notes

For MVP, these are manual inputs.

### B. Week Status Card

Shows:

- Open
- Locked

### C. Discussion Points

Auto-generated from Yellow/Red KPI.

Each discussion point shows:

- KPI name
- Role
- Formula/context
- Status
- Blocker
- Next Action

### D. Decisions & Priorities

Manual fields:

1. Decisions made
2. Priorities next week

### E. Complete Review & Lock Week

Button:

> Complete Review & Lock Week

When clicked:

- selected week becomes locked,
- KPI entries become view-only,
- historical trend becomes protected.

---

## 15.4 Acceptance Criteria

1. Weekly review can be conducted from this page.
2. Yellow/Red KPI automatically becomes discussion points.
3. Decisions and priorities can be saved.
4. Completing review locks the week.
5. Locked week cannot be edited from KPI Tracking.

---

# 16. Monthly Review Page

## 16.1 Purpose

Melihat pola KPI dan blocker secara bulanan.

## 16.2 Main Question

> What worked, what did not work, and what should be improved next month?

## 16.3 Components

### A. KPI Summary by Role

Per role:

- Green count
- Yellow count
- Red count
- Pending count

### B. Repeated Blockers

Menampilkan blocker yang paling sering muncul dari historical weeks.

### C. Monthly Reflection Fields

Manual fields:

1. What worked?
2. What did not work?
3. Priorities for next month

---

## 16.4 Acceptance Criteria

1. User can see KPI status summary by role.
2. User can see repeated blockers.
3. User can write monthly reflection.
4. Page supports monthly review without complex analytics.

---

# 17. Settings / KPI Setup Page

## 17.1 Purpose

Mengatur definisi KPI, target, dan input structure.

## 17.2 Main Question

> How should each KPI be measured and input?

## 17.3 Components

KPI Setup table:

| Column | Description |
|---|---|
| Role | KPI owner role |
| KPI | KPI name and definition |
| Input Type | Direct / calculated / status / checklist |
| Required Input | Field required to calculate KPI |
| Target | Target value |
| Active | Active/inactive status |

---

## 17.4 KPI Definition Requirements

Each KPI definition must include:

1. KPI name
2. Role owner
3. Description
4. Input type
5. Required input fields
6. Target
7. Unit
8. Status rule
9. Active status

---

## 17.5 Acceptance Criteria

1. User can understand how each KPI is calculated.
2. Percentage KPI clearly shows numerator and denominator fields.
3. Settings page is not used for weekly updates.
4. KPI setup does not overwrite historical data.

---

# 18. Default KPI Configuration

## 18.1 Growth Marketing

| KPI | Input Type | Required Input | Target Example |
|---|---|---|---|
| Total B2C Revenue | Direct currency | Actual revenue | Rp25.000.000 |
| Revenue from Personal License + Assisted | Direct currency | Actual revenue | Rp10.000.000 |
| Follow-up Rate | Calculated rate | Leads followed up / Total active leads | 90% |
| Weekly Operating System Consistency | Status | On Track / Needs Attention / Off Track | On Track |

## 18.2 Activation Specialist

| KPI | Input Type | Required Input | Target Example |
|---|---|---|---|
| Qualified Leads Generated | Direct number | Number of qualified leads | 12 leads |
| First Response Time | Calculated rate | Responded within SLA / Total new inquiries | 90% |
| Follow-up Completion Rate | Calculated rate | Completed follow-up / Leads requiring follow-up | 90% |
| WA / Community Activation Consistency | Direct number | Number of activation activities | 2 activities |

## 18.3 Learning Operation

| KPI | Input Type | Required Input | Target Example |
|---|---|---|---|
| On-time Program Readiness | Status | On Track / Needs Attention / Off Track | On Track |
| On-time Program Delivery | Status | On Track / Needs Attention / Off Track | On Track |
| Learner Satisfaction / Attendance Health | Calculated rate | Attended learners / Registered learners | 80% |
| Feedback-to-Improvement Loop | Checklist | Feedback collected, issue summarized, action defined, owner assigned | 100% |

## 18.4 Graphic Designer & Editor

| KPI | Input Type | Required Input | Target Example |
|---|---|---|---|
| On-time Creative Delivery | Calculated rate | Assets delivered on time / Total assets due | 90% |
| Asset Readiness for P0 Campaign | Status | On Track / Needs Attention / Off Track | On Track |
| Weekly Production Consistency | Direct number | Completed priority assets | 8 assets |
| Revision Efficiency | Lower-is-better number | Average revision cycle | 2 cycles |

---

# 19. Status Logic

## 19.1 Direct Number / Currency

Default:

- Green: actual >= target
- Yellow: actual >= 70% of target and < target
- Red: actual < 70% of target

## 19.2 Calculated Rate

Formula:

```text
rate = numerator / denominator * 100
```

Default:

- Green: rate >= target
- Yellow: rate >= 70% of target and < target
- Red: rate < 70% of target

For some percentage KPI, fixed threshold may be used:

- Green: >= 90%
- Yellow: 70–89%
- Red: < 70%

## 19.3 Status

Mapping:

| Input | Status |
|---|---|
| On Track | Green |
| Needs Attention | Yellow |
| Off Track | Red |

## 19.4 Checklist

Default:

- Green: all checklist completed
- Yellow: 50–99% completed
- Red: less than 50% completed

## 19.5 Lower-Is-Better Number

Example: Revision Efficiency

- Green: actual <= target
- Yellow: actual = target + 1
- Red: actual > target + 1

---

# 20. Blocker System

## 20.1 Blocker Options

1. No blocker
2. Waiting for decision
3. Waiting for asset/material
4. Waiting for data
5. Waiting for another role
6. Unclear brief
7. Timeline too tight
8. Technical issue
9. External dependency
10. Overcapacity
11. Low conversion
12. Low inquiry quality
13. Other

## 20.2 Blocker Rule

- Green KPI: blocker optional.
- Yellow KPI: blocker required.
- Red KPI: blocker required.
- If blocker = Other, blocker note should be required in future version.

## 20.3 Next Action Rule

- Green KPI: next action optional.
- Yellow KPI: next action required.
- Red KPI: next action required.

---

# 21. Data Model

## 21.1 Roles Table

```md
role_id
role_name
owner_name
mandate
is_active
created_at
updated_at
```

## 21.2 KPI Definitions Table

```md
kpi_id
role_id
kpi_name
description
input_type
display_type
target_value
unit
numerator_label
denominator_label
checklist_items
status_rule
is_active
display_order
created_at
updated_at
```

## 21.3 Weekly KPI Entries Table

```md
entry_id
week_id
kpi_id
actual_value
numerator_value
denominator_value
checklist_values
computed_value
status
notes
blocker_type
blocker_notes
next_action
updated_by
updated_at
created_at
```

## 21.4 Weeks Table

```md
week_id
week_label
week_start
week_end
quarter_week
status
locked_at
locked_by
created_at
updated_at
```

Week status:

```md
current
locked
planned
```

## 21.5 Weekly Review Table

```md
review_id
week_id
revenue_total
leads_in
follow_up_rate
conversion_notes
decisions_made
priorities_next_week
review_status
completed_at
created_at
updated_at
```

## 21.6 Monthly Review Table

```md
monthly_review_id
month
what_worked
what_didnt_work
main_operational_issues
priorities_next_month
created_at
updated_at
```

---

# 22. User Flows

## 22.1 Flow — Open System

1. User opens web app.
2. User lands on Home.
3. User sees active MVP module: KPI Tracker.
4. User sees planned modules as non-functional shell.
5. User clicks Open KPI Dashboard.

## 22.2 Flow — Update KPI

1. User opens KPI Tracker.
2. User selects current week.
3. User opens KPI Tracking.
4. User filters by role.
5. User clicks Edit.
6. System opens modal.
7. User inputs contextual KPI fields.
8. System calculates actual value and status.
9. If Yellow/Red, user fills blocker and next action.
10. User selects Updated By.
11. User saves.
12. Dashboard updates automatically.

## 22.3 Flow — Review KPI History

1. User opens KPI History.
2. User selects role.
3. User selects KPI.
4. System shows target vs actual trend.
5. User checks weekly status history.

## 22.4 Flow — Complete Weekly Review

1. Growth Lead opens Weekly Review.
2. System shows discussion points from Yellow/Red KPI.
3. Growth Lead fills revenue and funnel notes.
4. Team discusses blockers.
5. Growth Lead fills decisions and priorities.
6. Growth Lead clicks Complete Review & Lock Week.
7. Week becomes locked.
8. KPI entries become historical view-only.

## 22.5 Flow — View Planned Module

1. User clicks Campaign Library / Business Performance / Learning Journey.
2. System opens placeholder page.
3. User sees module purpose and future features.
4. CTA directs user back to Active MVP.

---

# 23. Functional Requirements

## 23.1 Home

| ID | Requirement | Priority |
|---|---|---|
| FR-001 | User can see system positioning as Growth Operating System | Must |
| FR-002 | User can see KPI Tracker as active MVP | Must |
| FR-003 | User can see planned modules as shell | Must |
| FR-004 | User can navigate to KPI Dashboard | Must |

## 23.2 Navigation

| ID | Requirement | Priority |
|---|---|---|
| FR-005 | Primary nav shows only top-level modules | Must |
| FR-006 | KPI sub-nav appears only inside KPI module | Must |
| FR-007 | User can switch week from header | Must |
| FR-008 | Navbar remains visually minimal and not crowded | Must |

## 23.3 KPI Dashboard

| ID | Requirement | Priority |
|---|---|---|
| FR-009 | User can see KPI health summary | Must |
| FR-010 | User can see role cards | Must |
| FR-011 | User can see week status | Must |
| FR-012 | User can see KPI needing attention | Must |
| FR-013 | User can see blocker pattern | Should |

## 23.4 KPI Tracking

| ID | Requirement | Priority |
|---|---|---|
| FR-014 | User can filter KPI by role | Must |
| FR-015 | User can edit current week KPI | Must |
| FR-016 | User cannot edit locked week KPI | Must |
| FR-017 | System supports contextual input types | Must |
| FR-018 | System calculates percentage KPI automatically | Must |
| FR-019 | System displays numerator/denominator | Must |
| FR-020 | Yellow/Red requires blocker | Must |
| FR-021 | Yellow/Red requires next action | Must |
| FR-022 | System stores Updated By | Must |

## 23.5 KPI History

| ID | Requirement | Priority |
|---|---|---|
| FR-023 | User can select KPI for trend view | Must |
| FR-024 | System shows target vs actual trend | Must |
| FR-025 | System shows status history | Must |
| FR-026 | Historical week is view-only | Must |

## 23.6 Weekly Review

| ID | Requirement | Priority |
|---|---|---|
| FR-027 | System surfaces Yellow/Red KPI as discussion points | Must |
| FR-028 | User can input revenue and funnel notes | Must |
| FR-029 | User can input decisions made | Must |
| FR-030 | User can input priorities next week | Must |
| FR-031 | User can complete review and lock week | Must |

## 23.7 Monthly Review

| ID | Requirement | Priority |
|---|---|---|
| FR-032 | User can see KPI status summary by role | Must |
| FR-033 | User can see repeated blockers | Should |
| FR-034 | User can write monthly reflection | Should |

## 23.8 Planned Modules

| ID | Requirement | Priority |
|---|---|---|
| FR-035 | Planned modules are visible in navigation | Must |
| FR-036 | Planned modules show placeholder page | Must |
| FR-037 | Planned modules are not functional in MVP | Must |

---

# 24. Non-Functional Requirements

## 24.1 Performance

- Dashboard should load in under 2 seconds for normal data volume.
- KPI update should save quickly and feel instant.

## 24.2 Responsiveness

- Desktop-first.
- Tablet usable.
- Mobile readable, but heavy editing is not a priority for MVP.

## 24.3 Reliability

- Data persists after refresh.
- Historical weeks remain accessible.
- Locked week cannot be casually overwritten.

## 24.4 Simplicity

- Primary navigation must remain short.
- KPI sub-navigation must be contextual.
- No unnecessary charts.
- No daily reporting.

---

# 25. UI / Visual Design Direction

## 25.1 Design Keywords

- Minimal
- Calm
- Premium
- Spacious
- Precise
- Editorial
- Low-friction
- Quiet confidence

## 25.2 Visual Style

Inspired by Apple/Jony Ive:

1. Generous whitespace.
2. Soft rounded cards.
3. Neutral background.
4. Typography-led hierarchy.
5. Minimal colors.
6. No visual noise.
7. Contextual navigation.
8. Subtle transitions.

## 25.3 Color System

### Background

```md
Main background: #F5F5F7
Surface/card: #FFFFFF
Secondary surface: #FAFAFA
```

### Text

```md
Primary text: #1D1D1F
Secondary text: #6E6E73
Tertiary text: #A1A1A6
```

### Status Colors

```md
Green: #34C759
Yellow: #FFCC00
Red: #FF3B30
Gray: #D1D1D6
```

### Soft Status Background

```md
Green soft: #EAF8EF
Yellow soft: #FFF8D6
Red soft: #FDEDEC
Gray soft: #F2F2F7
```

## 25.4 Typography

Recommended font stack:

```css
Inter, SF Pro Display, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif
```

Hierarchy:

| Element | Size | Weight |
|---|---:|---:|
| Page title | 32–48px | 600 |
| Section title | 20–24px | 600 |
| Card value | 28–36px | 600 |
| Body | 14–16px | 400 |
| Label | 12–13px | 500 |
| Caption | 12px | 400 |

## 25.5 Component Style

### Cards

- White background
- Rounded 24–32px
- Subtle border
- Soft shadow
- Spacious padding

### Buttons

Primary:

- Black background
- White text
- Rounded full

Secondary:

- Light gray background
- Dark text
- Rounded full

### Tables

- Minimal borders
- Subtle dividers
- Spacious row height
- Status pill with label

### Navigation

Primary navigation:

- Top-level only
- Pill style
- Minimal option count

Secondary navigation:

- Contextual KPI sub-nav
- Appears only inside KPI Tracker

---

# 26. Success Metrics

## 26.1 Adoption Metrics

| Metric | Target |
|---|---:|
| Weekly KPI update completion | >= 90% KPI updated per week |
| Roles updated before weekly review | 4/4 roles |
| Average update time per role | <= 5 minutes |
| Weekly review completion | 1 review/week |

## 26.2 Data Quality Metrics

| Metric | Target |
|---|---:|
| Yellow/Red KPI with blocker filled | 100% |
| Yellow/Red KPI with next action filled | 100% |
| Calculated rate KPI with numerator/denominator | 100% |
| Locked historical weeks preserved | 100% |

## 26.3 Behavioral Success Criteria

MVP is successful if:

1. Growth Lead no longer needs to manually ask every role for KPI progress.
2. Weekly meeting starts from dashboard, not verbal updates.
3. Team can see progress and blockers transparently.
4. KPI history helps monthly and quarterly review.
5. System feels helpful, not bureaucratic.

---

# 27. Release Scope

## 27.1 MVP v1 — Active Build

Build:

1. Home
2. KPI Dashboard
3. KPI Tracking
4. KPI History
5. Weekly Review
6. Monthly Review
7. Settings / KPI Setup
8. Planned module shell pages
9. Shared-login or simple access

## 27.2 MVP v1.1 — Usability Improvement

Possible additions:

1. Historical correction reason.
2. Export weekly review to Markdown/PDF.
3. Reminder banner for pending KPI.
4. Better blocker trend.
5. Cleaner mobile view.

## 27.3 v2 — Campaign Learning System

Possible additions:

1. Campaign Library.
2. A/B Test Tracker.
3. Campaign Evaluation.
4. Creative Asset Log.
5. Product-level campaign archive.

## 27.4 v3 — Business & Learning Expansion

Possible additions:

1. Business Performance History.
2. Product revenue dashboard.
3. Funnel trend.
4. Intern Learning Journey.
5. Assignment and milestone tracking.

---

# 28. Risks & Mitigation

## Risk 1 — Team Still Does Not Update KPI

Mitigation:

- Keep input under 5 minutes.
- Make dashboard the source for weekly meeting.
- Show pending updates clearly.
- Keep KPI per role limited to 4.

## Risk 2 — System Becomes Admin Burden

Mitigation:

- Weekly input only.
- No daily reporting.
- No unnecessary fields.
- Yellow/Red only requires extra context.

## Risk 3 — Data Can Be Manipulated

Mitigation:

- Lock week after weekly review.
- Historical correction should require reason.
- Store updated by and timestamp.

## Risk 4 — Planned Modules Distract Development

Mitigation:

- Planned modules are shell only.
- No functional form or database for planned modules in MVP.
- KPI Tracker remains active build priority.

## Risk 5 — KPI Definitions Are Ambiguous

Mitigation:

- KPI Setup must include description and input type.
- Percentage KPI must define numerator and denominator.
- Avoid subjective KPI where possible.

---

# 29. Open Questions

Before development, confirm:

1. Is the weekly period Monday–Friday or Monday–Sunday?
2. What is the KPI update deadline? Recommended: Friday 16.00 WIB.
3. Should Weekly Review happen Friday afternoon or Monday morning?
4. Should locked historical data be editable only by Growth Lead in future version?
5. Should correction reason be included in MVP or v1.1?
6. Should revenue fields remain manual in MVP?
7. Should week lock be manual only, or automatic after weekly review deadline?

---

# 30. Final MVP Definition

The MVP is complete when the team can:

1. Open one shared Growth Operating System.
2. See KPI Tracker as the active MVP module.
3. See future modules as planned shell.
4. Select current or historical week.
5. Update current week KPI per role.
6. Input calculated KPI using contextual components.
7. Automatically see KPI status.
8. Capture blocker and next action for off-track KPI.
9. View KPI trend across weeks.
10. Run weekly review from the system.
11. Lock week after review.
12. Use monthly review to see repeated patterns.

---

# 31. Product Direction Statement

This product should not feel like a reporting tool.

It should feel like:

> A quiet weekly operating surface where the B2C team checks reality, identifies blockers, and decides what to do next.

The strongest product decision is restraint.

Build KPI discipline first. Expand only after the habit works.

