# 🏨 Paris Hotel RevPAR Optimization

Revenue management case study for **Hotel de l'Etoile**, a 300-room, 4-star hotel in Paris operated under the Stillwood International chain. Full star schema data model, KPI framework, and analytical queries for optimizing RevPAR performance.

---

## Overview

This project analyzes five years (2011–2015) of operational data to identify revenue leakage and recommend strategic improvements. The hotel faces declining profitability despite stable occupancy — driven by rising OTA dependency, brand fee erosion, and an unfavorable loyalty redemption policy.

**Key findings & recommendations:**
- **Direct channel share declined from 55% to 47%**, while OTA share grew from 20% to 29% — the hotel is losing control of its distribution
- **Commission costs increased 46%** (EUR 263K to EUR 385K) over 5 years, directly eroding Net RevPAR
- **Loyalty Club displacement cost** is significant: redemptions at EUR 95/night vs. market ADR of EUR 168 — the no-blackout-date policy costs the hotel the rate difference on every loyalty room-night
- **EBITDAR margin declined from 32.7% to 29.8%** despite revenue growth, driven by rising Stillwood brand fees and OTA commissions
- **Room GOI margin dropped from 65% to 63.7%**, signaling rising room department costs
- **F&B capture rate grew from 12% to 16%**, representing an untapped ancillary revenue opportunity
- **Recommendation:** Shift 5-8pp of OTA business back to direct channels through website investment, rate parity enforcement, and loyalty program restructuring — estimated annual savings of EUR 60-100K in commissions

---

## Project Structure

```
├── data_model_and_kpis.sql      # Star schema: 6 dimensions + 5 fact tables
├── kpi_queries.sql              # 12 pre-built analytical queries across 5 sections
├── dax_measures.md              # 50+ DAX measure definitions for BI dashboards
└── dashboard_design.md          # 4-page dashboard layout specification
```

---

## Data Model

Star schema designed for hospitality revenue management:

```
                    ┌─────────────────┐
                    │    dim_date     │
                    └────────┬────────┘
                             │
    ┌──────────────┐    ┌────┴────────────────┐    ┌──────────────┐
    │ dim_channel  │────│  fact_daily_rooms    │────│ dim_segment  │
    └──────────────┘    └─────────────────────┘    └──────────────┘
                             │
    ┌──────────────┐    ┌────┴────────────────┐    ┌──────────────┐
    │dim_room_type │────│ fact_daily_inventory│    │dim_rate_plan │
    └──────────────┘    └─────────────────────┘    └──────────────┘
                             │
                    ┌────────┴────────┐
                    │ fact_pnl_monthly │
                    └─────────────────┘
```

**Dimensions:** Date, Channel (8 distribution channels), Segment (5 market segments), Room Type (4 categories), Rate Plan, Competitive Set

**Fact Tables:** Daily Rooms, Daily Inventory, Channel Mix, STR Benchmark, P&L Monthly

---

## KPI Framework

### Core Metrics
| Metric | Formula | Benchmark (2015) |
|--------|---------|-------------------|
| Occupancy % | Rooms Sold / Rooms Available | 78.2% |
| ADR | Room Revenue / Rooms Sold | EUR 168.1 |
| RevPAR | Room Revenue / Rooms Available | EUR 131.5 |
| Net RevPAR | (Revenue - Acquisition Costs) / Available | Key optimization target |

### Competitive Indices (STR)
| Index | Formula | Interpretation |
|-------|---------|----------------|
| MPI | Hotel Occ / CompSet Occ × 100 | Market share of demand |
| ARI | Hotel ADR / CompSet ADR × 100 | Rate positioning |
| RGI | Hotel RevPAR / CompSet RevPAR × 100 | Overall performance |

### Distribution Metrics
| Metric | Purpose |
|--------|---------|
| Direct Share % | Track channel independence (target > 50%) |
| Commission Load % | Total commissions as % of room revenue |
| Channel Cost Ratio | Acquisition cost per channel |
| Net ADR | ADR after all distribution costs |

---

## Dashboard Specification

The repository includes a complete dashboard design spec (`dashboard_design.md`) and DAX measure reference (`dax_measures.md`) as documentation for building the BI layer on top of this data model:

1. **Executive Summary** — KPI cards, RevPAR trend, occupancy calendar, key alerts
2. **Channel Performance** — Channel mix breakdown, commission waterfall, direct vs. OTA trends
3. **Market Segmentation** — Segment revenue, ADR comparison, loyalty displacement analysis
4. **Competitive Analysis** — STR indices (MPI/ARI/RGI), hotel vs. compset benchmarking

---

## Tools & Technologies

![SQL](https://img.shields.io/badge/SQL-4479A1?style=for-the-badge&logo=postgresql&logoColor=white)
![Data Modeling](https://img.shields.io/badge/Data_Modeling-1a1b27?style=for-the-badge&logo=databricks&logoColor=white)
![Revenue Management](https://img.shields.io/badge/Revenue_Management-0f4c75?style=for-the-badge)

- **SQL (PostgreSQL)** — Star schema design, KPI calculations, analytical queries with window functions
- **Data Modeling** — Dimensional modeling (star schema) with 6 dimension tables and 5 fact tables
- **Revenue Management** — STR benchmarking, channel optimization, displacement analysis, Net RevPAR framework

---

## Case Context

Hotel de l'Etoile is part of the Stillwood International chain, which provides brand, distribution, and loyalty infrastructure in exchange for management fees, marketing contributions, and CRS fees. The analysis evaluates whether the brand relationship delivers net positive value given the rising cost structure.

Key strategic questions addressed:
- Is the shift from direct to OTA channels eroding net revenue?
- What is the true cost of the no-blackout-date loyalty redemption policy?
- How does the hotel perform against its STR competitive set?
- Where are the highest-impact opportunities to improve Net RevPAR?
