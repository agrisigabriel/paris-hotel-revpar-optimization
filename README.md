# 🏨 Paris Hotel RevPAR Optimization

Revenue management case study for **Hotel de l'Etoile**, a 300-room, 4-star hotel in Paris operated under the Stillwood International chain. Full data model, KPI framework, DAX measures, and Power BI dashboard design for optimizing RevPAR performance.

---

## Overview

This project analyzes five years (2011–2015) of operational data to identify revenue leakage and recommend strategic improvements. The hotel faces declining profitability despite stable occupancy — driven by rising OTA dependency, brand fee erosion, and an unfavorable loyalty redemption policy.

**Key findings:**
- Direct channel share declined from 55% to 47%, while OTA share grew from 20% to 29%
- Commission costs increased from EUR 263K to EUR 385K over the period
- Loyalty Club redemptions at EUR 95/night vs. market ADR of EUR 168 create significant displacement cost
- EBITDAR margin declined from 32.7% to 29.8% despite revenue growth

---

## Project Structure

```
├── data_model_and_kpis.sql      # Star schema: dimensions + fact tables
├── kpi_queries.sql              # Pre-built analysis queries for all KPIs
├── dax_measures.md              # Complete DAX measure reference for Power BI
├── dashboard_design.md          # 4-page dashboard layout specification
├── Deliverables/
│   └── Hotel_de_letoile_Stillwood_Analysis.pdf
└── Module 1 Files/
    ├── STR Trend Reports (*.xls, *.pdf)
    ├── Income Statements (*.pdf)
    ├── Distribution Reports (*.pdf)
    └── Interview Transcripts (*.txt)
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

## Power BI Dashboard

Four-page dashboard designed for executive and operational use:

1. **Executive Summary** — KPI cards, RevPAR trend, occupancy calendar, key alerts
2. **Channel Performance** — Channel mix donut, commission waterfall, direct vs. OTA trends
3. **Market Segmentation** — Segment revenue, ADR comparison, loyalty displacement analysis
4. **Competitive Analysis** — STR indices (MPI/ARI/RGI), hotel vs. compset benchmarking

See `dashboard_design.md` for full layout specifications and `dax_measures.md` for all 50+ DAX measures.

---

## Tools & Technologies

![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![SQL](https://img.shields.io/badge/SQL-4479A1?style=for-the-badge&logo=postgresql&logoColor=white)
![Revenue Management](https://img.shields.io/badge/Revenue_Management-0f4c75?style=for-the-badge)

- **SQL (PostgreSQL)** — Star schema design, KPI calculations, analytical queries
- **Power BI (DAX)** — Dashboard measures, time intelligence, competitive indexing
- **Revenue Management** — STR benchmarking, channel optimization, displacement analysis

---

## Case Context

Hotel de l'Etoile is part of the Stillwood International chain, which provides brand, distribution, and loyalty infrastructure in exchange for management fees, marketing contributions, and CRS fees. The analysis evaluates whether the brand relationship delivers net positive value given the rising cost structure.

Key strategic questions addressed:
- Is the shift from direct to OTA channels eroding net revenue?
- What is the true cost of the no-blackout-date loyalty redemption policy?
- How does the hotel perform against its STR competitive set?
- Where are the highest-impact opportunities to improve Net RevPAR?
