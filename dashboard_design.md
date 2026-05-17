# Hotel de l'Etoile -- Power BI Dashboard Design

Four-page dashboard for RevPAR optimization analysis.
Data source: star schema in `data_model_and_kpis.sql`. Measures: `dax_measures.md`.

---

## Global Elements (All Pages)

### Theme and Branding
- Color palette: navy (#1B2A4A), gold (#C5A45A), slate grey (#6B7B8D), white (#FFFFFF)
- Accent colors: green (#2E8B57) for positive variance, red (#C0392B) for negative
- Font: Segoe UI, 10pt body, 14pt headings
- Header bar: hotel logo left, page title center, last-refresh timestamp right

### Common Slicers (Persistent Across Pages)
- **Year slicer** -- dropdown, default = current year (values: 2011-2015)
- **Date range slicer** -- date picker for custom period drill-down
- **Season slicer** -- buttons: All | High | Shoulder | Low (from dim_date.season)
- **Day type slicer** -- buttons: All | Weekday | Weekend (from dim_date.is_weekend)

### Common Filters
- Sync slicers across all pages for consistent filtering
- Bookmark bar for saved views: "YTD", "Last 12 Months", "High Season Only", "Weekday Only"

---

## Page 1: Executive Summary

**Purpose:** At-a-glance hotel performance for GM and ownership review.

### Row 1 -- KPI Cards (Top Banner)

Six card visuals spanning the full width:

| Card | Measure | Format | Conditional Color |
|------|---------|--------|-------------------|
| Occupancy % | `[Occupancy %]` | 0.0% | Green >=75%, amber 65-75%, red <65% |
| ADR | `[ADR]` | EUR #,##0 | Green if YoY positive |
| RevPAR | `[RevPAR]` | EUR #,##0.0 | Green if YoY positive |
| Net RevPAR | `[Net RevPAR]` | EUR #,##0.0 | Green if YoY positive |
| GOPPAR | `[GOPPAR]` | EUR #,##0.0 | Green if YoY positive |
| TRevPAR | `[TRevPAR]` | EUR #,##0.0 | Green if YoY positive |

Each card shows the current value, YoY % change as a subtitle, and a small sparkline.

### Row 2 -- Trend Charts (Middle Section)

**Left half -- RevPAR Trend (Line Chart)**
- X-axis: dim_date[full_date] by month
- Lines: `[RevPAR]` (solid navy), `[RevPAR PY]` (dashed grey)
- Reference line: CompSet RevPAR (gold dotted)
- Tooltip: Occupancy %, ADR, RevPAR, RGI

**Right half -- Revenue Decomposition (Stacked Area)**
- X-axis: Month
- Areas: Room Revenue, F&B Revenue, Other Revenue (from fact_pnl_monthly)
- Shows total revenue composition over time

### Row 3 -- Bottom Section

**Left -- Occupancy Calendar (Matrix Heat Map)**
- Rows: Day of week (Mon-Sun)
- Columns: Week of year
- Values: `[Occupancy %]`
- Color scale: white (0%) through gold (75%) to navy (100%)
- Highlights trade show dates and holidays with border markers
- Tooltip: rooms sold, ADR, revenue for that date

**Center -- Monthly KPI Table**
- Columns: Month, Occupancy %, ADR, RevPAR, Net RevPAR, Revenue, YoY %
- Conditional formatting: data bars on Revenue, arrows on YoY columns
- Totals row at bottom

**Right -- Key Alerts (Card List)**
- Dynamic text cards showing:
  - "OTA share reached X%" (red if > 28%)
  - "Direct share at X%" (red if < 48%)
  - "Commission load: EUR X" (with YoY change)
  - "Room GOI margin: X%" (red if declining)

---

## Page 2: Channel Performance

**Purpose:** Distribution cost analysis and channel mix optimization.

### Row 1 -- Channel KPI Cards

Four cards:

| Card | Measure | Note |
|------|---------|------|
| Direct Share % | `[Direct Share %]` | Target: > 50% |
| OTA Share % | `[OTA Share %]` | Warning threshold: 25% |
| Commission Load % | `[Commission Load %]` | Total commission as % of room revenue |
| Channel Net Revenue | `[Channel Net Revenue]` | Revenue minus all channel costs |

### Row 2 -- Main Visuals

**Left -- Channel Mix Donut Chart**
- Values: `[Channel Room Revenue]` by dim_channel[channel_name]
- Inner ring: current year
- Color coding by channel_category: Direct (navy), OTA (red), GDS (grey), Wholesale (amber)
- Center label: total room revenue
- Legend with revenue amounts

**Center -- Commission Waterfall Chart**
- Categories: each channel_name
- Values: `[Total Commission Cost]` by channel
- Running total bar at right
- Shows how each channel contributes to total commission burden
- Subtotals by channel_category (Direct, OTA, GDS, Wholesale)

**Right -- Channel Trend (Multi-Line)**
- X-axis: Year (2011-2015)
- Lines: Direct Share %, OTA Share %, GDS Share %
- Highlights the crossover trend (direct declining, OTA rising)
- Annotations at key inflection points

### Row 3 -- Detail Section

**Left -- Direct vs OTA Comparison Table**
- Side-by-side columns: Direct channels vs OTA channels
- Rows: Rooms Sold, Revenue, ADR, Commission %, Net Revenue, Net ADR
- Conditional formatting: green for the better-performing side per metric
- Variance column showing the gap

**Right -- Channel Economics Scatter Plot**
- X-axis: `[Channel Cost Ratio]` (acquisition cost %)
- Y-axis: ADR by channel
- Bubble size: rooms sold
- Each bubble = one channel
- Quadrant lines at average cost ratio and average ADR
- Goal: identify high-ADR, low-cost channels (upper-left quadrant)

### Page-Specific Slicers
- Channel category filter: Direct | OTA | GDS | Wholesale
- Individual channel dropdown

---

## Page 3: Market Segmentation

**Purpose:** Segment-level revenue and rate plan analysis to identify pricing opportunities.

### Row 1 -- Segment KPI Cards

Five cards, one per segment (Business, Leisure, Loyalty Club, Group, MICE):
- Shows: Rooms Sold, ADR, Revenue Share %
- Loyalty Club card highlighted in amber with displacement cost callout

### Row 2 -- Main Visuals

**Left -- Segment Revenue Bar Chart (Clustered)**
- X-axis: Segment name
- Bars: Room Revenue (current year, navy) and Room Revenue PY (grey)
- Data labels showing YoY % change
- Sorted by revenue descending

**Center -- Segment ADR Comparison (Bar + Reference Line)**
- X-axis: Segment name
- Bar: Segment average rate (incl. VAT)
- Reference line: blended hotel ADR (EUR 168)
- Conditional color: red for segments below blended ADR
- Highlights Loyalty Club at EUR 95 (44% below market)

**Right -- Rate Plan Analysis (Treemap)**
- Hierarchy: rate_plan_type > rate_plan_name
- Size: rooms sold
- Color: ADR (gradient from red/low to green/high)
- Tooltip: revenue, rooms, average rate, refundable status

### Row 3 -- Detail Section

**Left -- Loyalty Displacement Analysis (Combo Chart)**
- X-axis: Month or Year
- Bars: Loyalty rooms sold
- Line: `[Loyalty Displacement Cost]`
- Secondary axis for displacement cost in EUR
- Annotation: "Revenue forgone from no-blackout-date policy"

**Center -- Segment x Channel Cross-Tab (Matrix)**
- Rows: Segment name
- Columns: Channel category (Direct, OTA, GDS, Wholesale)
- Values: Room Revenue with data bars
- Shows which segments flow through which channels
- Identifies optimization opportunities (e.g., shifting OTA leisure to direct)

**Right -- Segment Mix Trend (100% Stacked Bar)**
- X-axis: Year (2011-2015)
- Stacked bars: segment share of revenue
- Shows structural shifts in guest mix over time

### Page-Specific Slicers
- Segment type filter: Transient | Group | Redemption
- Rate plan type: Public | Negotiated | Redemption | Package
- Negotiated rate toggle: Yes | No

---

## Page 4: Competitive Analysis

**Purpose:** STR benchmark positioning and competitive index tracking.

### Row 1 -- Index KPI Cards

Three large gauge visuals:

| Gauge | Measure | Target | Meaning |
|-------|---------|--------|---------|
| MPI | `[MPI]` | 100 | Market share of demand |
| ARI | `[ARI]` | 100 | Rate positioning vs compset |
| RGI | `[RGI]` | 100 | Overall revenue generation vs compset |

- Gauge range: 80-120
- Green zone: > 100, red zone: < 100
- Needle shows current value, subtitle shows YoY change

### Row 2 -- Main Visuals

**Left -- Index Performance Trend (Line Chart)**
- X-axis: dim_date[full_date] by month
- Lines: MPI (blue), ARI (gold), RGI (navy)
- Reference line at 100 (parity)
- Shaded bands: green above 100, light red below 100
- Tooltip: hotel value, compset value, index

**Right -- Hotel vs CompSet Comparison (Grouped Bar)**
- X-axis: Metric (Occupancy, ADR, RevPAR)
- Paired bars: Hotel (navy) vs CompSet Average (grey)
- Data labels with values
- Variance indicators (arrows or delta labels)

### Row 3 -- Detail Section

**Left -- RevPAR Gap Analysis (Waterfall)**
- Starts with CompSet RevPAR
- Components: Occupancy effect, Rate effect
- Ends with Hotel RevPAR
- Decomposes the RevPAR gap into occupancy-driven and rate-driven components

**Center -- Seasonal Index Table**
- Rows: Season (High, Shoulder, Low)
- Columns: Hotel Occ, CompSet Occ, MPI, Hotel ADR, CompSet ADR, ARI, Hotel RevPAR, CompSet RevPAR, RGI
- Conditional formatting: bold cells where index < 100
- Identifies seasonal weakness (e.g., losing share in high season vs. holding in low)

**Right -- Monthly CompSet Detail (Small Multiples)**
- 12 small line charts (one per month)
- Each shows Hotel RevPAR vs CompSet RevPAR
- Highlights months where hotel underperforms
- Quick visual scan for seasonal competitive patterns

### Page-Specific Slicers
- Individual compset hotel selector (for direct comparison)
- Season filter: High | Shoulder | Low
- Metric toggle: Occupancy | ADR | RevPAR (changes chart focus)

---

## Interactions and Drill-Through

### Cross-Filtering
- All visuals on each page cross-filter by default
- Clicking a channel in the donut (Page 2) filters all other visuals to that channel
- Clicking a segment bar (Page 3) filters to that segment across the page

### Drill-Through Pages
- **Date Drill-Through:** Right-click any date to see daily detail (occupancy, rate, channel mix for that day)
- **Channel Drill-Through:** Right-click any channel to see its full performance history, ADR trend, and cost structure
- **Segment Drill-Through:** Right-click any segment to see rate plan breakdown, channel distribution, and YoY trend

### Tooltips
- Custom tooltip pages for:
  - Date hover: mini calendar + daily KPIs
  - Channel hover: commission rate, net revenue, rooms sold
  - Segment hover: ADR vs market, displacement cost (if loyalty)

---

## Data Refresh and Performance

- Data refresh schedule: daily at 06:00 CET
- Incremental refresh on fact_daily_rooms and fact_daily_inventory (last 30 days full, historical append-only)
- Row-level security: GM sees all data; department heads see own segment/channel only
- Performance optimization: pre-aggregated monthly tables for P&L and trend visuals; detail tables for daily drill-down
