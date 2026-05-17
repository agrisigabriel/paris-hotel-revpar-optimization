-- ============================================================================
-- HOTEL DE L'ETOILE — DATA MODEL & KPI FRAMEWORK
-- 300-room, 4-star Paris hotel | Revenue management case study
-- ============================================================================

-- ============================================================================
-- 1. DIMENSION TABLES
-- ============================================================================

-- ---------------------------------------------------------------------------
-- dim_date: Calendar spine — one row per day
-- ---------------------------------------------------------------------------
CREATE TABLE dim_date (
    date_key        INT PRIMARY KEY,          -- YYYYMMDD
    full_date       DATE NOT NULL,
    year            INT,
    quarter         INT,
    month           INT,
    month_name      VARCHAR(20),
    week_of_year    INT,
    day_of_week     INT,                      -- 1=Mon … 7=Sun
    day_name        VARCHAR(10),
    is_weekend      BOOLEAN,
    is_paris_holiday BOOLEAN,                 -- French public holidays
    is_trade_show   BOOLEAN,                  -- major Paris events/fairs
    season          VARCHAR(20)               -- High / Shoulder / Low
);

-- ---------------------------------------------------------------------------
-- dim_channel: Distribution channels
-- ---------------------------------------------------------------------------
CREATE TABLE dim_channel (
    channel_key         INT PRIMARY KEY,
    channel_name        VARCHAR(50) NOT NULL,  -- Direct, GDS, Central Voice,
                                               -- Web Direct, Expedia, Booking,
                                               -- Other OTAs, Bedbanks
    channel_category    VARCHAR(20),           -- Direct | OTA | GDS | Wholesale
    flows_through_crs   BOOLEAN,              -- TRUE for Direct, GDS, Central Voice, Web Direct
    commission_rate_pct DECIMAL(5,2),          -- channel-specific commission %
    is_brand_controlled BOOLEAN               -- TRUE = Stillwood-controlled channel
);

-- ---------------------------------------------------------------------------
-- dim_segment: Market segments
-- ---------------------------------------------------------------------------
CREATE TABLE dim_segment (
    segment_key     INT PRIMARY KEY,
    segment_name    VARCHAR(30) NOT NULL,      -- Business, Leisure, Loyalty Club,
                                               -- Group, MICE
    segment_type    VARCHAR(20),               -- Transient | Group | Redemption
    is_negotiated   BOOLEAN,                   -- TRUE for corporate / group rates
    is_redemption   BOOLEAN,                   -- TRUE only for Loyalty Club
    reimbursement_rate DECIMAL(5,2)            -- 0.50 for Loyalty Club, 1.0 otherwise
);

-- ---------------------------------------------------------------------------
-- dim_room_type: Room inventory classes
-- ---------------------------------------------------------------------------
CREATE TABLE dim_room_type (
    room_type_key   INT PRIMARY KEY,
    room_type_name  VARCHAR(30),               -- Standard, Superior, Deluxe, Suite
    rack_rate_incl_vat DECIMAL(10,2),          -- Published rate incl. VAT
    rack_rate_excl_vat DECIMAL(10,2),
    room_count      INT                        -- rooms of this type in inventory
    -- SUM(room_count) = 300
);

-- ---------------------------------------------------------------------------
-- dim_rate_plan: Rate structures
-- ---------------------------------------------------------------------------
CREATE TABLE dim_rate_plan (
    rate_plan_key   INT PRIMARY KEY,
    rate_plan_name  VARCHAR(50),               -- BAR, Corporate Negotiated,
                                               -- Loyalty Redemption, Group Block,
                                               -- MICE Package, Promotional
    rate_plan_type  VARCHAR(20),               -- Public | Negotiated | Redemption | Package
    is_public       BOOLEAN,
    is_refundable   BOOLEAN
);

-- ---------------------------------------------------------------------------
-- dim_compset: Competitive set hotels (for STR index benchmarking)
-- ---------------------------------------------------------------------------
CREATE TABLE dim_compset (
    hotel_key       INT PRIMARY KEY,
    hotel_name      VARCHAR(100),
    star_rating     INT,
    room_count      INT,
    is_own_hotel    BOOLEAN                    -- TRUE for Hotel de l'Etoile
);


-- ============================================================================
-- 2. FACT TABLES
-- ============================================================================

-- ---------------------------------------------------------------------------
-- fact_daily_rooms: Core room-night grain — one row per date × segment × channel
-- This is the primary fact table for all room revenue analysis
-- ---------------------------------------------------------------------------
CREATE TABLE fact_daily_rooms (
    date_key            INT REFERENCES dim_date(date_key),
    channel_key         INT REFERENCES dim_channel(channel_key),
    segment_key         INT REFERENCES dim_segment(segment_key),
    room_type_key       INT REFERENCES dim_room_type(room_type_key),
    rate_plan_key       INT REFERENCES dim_rate_plan(rate_plan_key),

    rooms_sold          INT,
    guests              INT,

    -- Revenue (all in EUR '000 convention from source, but store as actuals)
    room_revenue_incl_vat   DECIMAL(12,2),
    room_revenue_excl_vat   DECIMAL(12,2),

    -- Cost of acquisition
    commission_amount       DECIMAL(12,2),     -- OTA / GDS commissions
    loyalty_earn_cost       DECIMAL(12,2),     -- 6% of Le Club revenue
    crs_fee_amount          DECIMAL(12,2),     -- 0.5% of room rev for CRS bookings
    transaction_fee         DECIMAL(12,2),     -- credit card / payment processing

    -- Loyalty redemption economics
    reimbursement_received  DECIMAL(12,2),     -- what chain actually pays back (50% rack)

    PRIMARY KEY (date_key, channel_key, segment_key, room_type_key, rate_plan_key)
);

-- ---------------------------------------------------------------------------
-- fact_daily_inventory: Hotel-level capacity — one row per date
-- ---------------------------------------------------------------------------
CREATE TABLE fact_daily_inventory (
    date_key                INT PRIMARY KEY REFERENCES dim_date(date_key),
    total_rooms_available   INT DEFAULT 300,
    rooms_out_of_order      INT DEFAULT 0,
    rooms_available_to_sell INT,               -- = total - OOO
    rooms_sold              INT,
    rooms_unsold            INT,
    no_shows                INT,
    cancellations           INT,
    walk_ins                INT,
    overbooking_count       INT
);

-- ---------------------------------------------------------------------------
-- fact_pnl_monthly: P&L by month — mirrors the Income Statement structure
-- ---------------------------------------------------------------------------
CREATE TABLE fact_pnl_monthly (
    date_key                INT,               -- first day of month (YYYYMM01)
    year                    INT,

    -- Revenue
    room_revenue            DECIMAL(14,2),
    fb_revenue              DECIMAL(14,2),
    other_revenue           DECIMAL(14,2),
    total_revenue           DECIMAL(14,2),     -- sum of above

    -- Departmental costs
    room_payroll            DECIMAL(14,2),
    room_expenses           DECIMAL(14,2),
    fb_cost_of_sales        DECIMAL(14,2),
    fb_payroll              DECIMAL(14,2),
    fb_expenses             DECIMAL(14,2),
    misc_cost_of_sales      DECIMAL(14,2),
    misc_payroll            DECIMAL(14,2),

    -- Departmental profits
    room_goi                DECIMAL(14,2),
    fb_goi                  DECIMAL(14,2),
    misc_goi                DECIMAL(14,2),
    goi_before_unallocated  DECIMAL(14,2),

    -- Undistributed expenses
    unallocated_payroll     DECIMAL(14,2),
    admin_expenses          DECIMAL(14,2),
    marketing_expenses      DECIMAL(14,2),
    commissions             DECIMAL(14,2),     -- OTA + GDS commissions
    maintenance_expenses    DECIMAL(14,2),
    energy_expenses         DECIMAL(14,2),
    other_expenses          DECIMAL(14,2),
    goi                     DECIMAL(14,2),     -- Gross Operating Income

    -- Stillwood brand fees
    marketing_contribution  DECIMAL(14,2),     -- 2% of room rev
    distribution_fee        DECIMAL(14,2),     -- 2% of room rev
    crs_fee                 DECIMAL(14,2),     -- 0.5% of room rev
    loyalty_club_fee_earn   DECIMAL(14,2),     -- 6% of Le Club revenue
    total_billable_services DECIMAL(14,2),

    -- Management fees
    gop_before_fees         DECIMAL(14,2),     -- GOP2
    trademark_royalty       DECIMAL(14,2),     -- 2% of room rev
    base_management_fee     DECIMAL(14,2),     -- 5% of total rev
    gop_after_fees          DECIMAL(14,2),     -- GOP3
    incentive_fee           DECIMAL(14,2),     -- 3% of GOP3

    -- Bottom line
    ebitdar                 DECIMAL(14,2),
    depreciation            DECIMAL(14,2),
    ebit                    DECIMAL(14,2),
    interest_expense        DECIMAL(14,2),
    ebt                     DECIMAL(14,2),
    taxes                   DECIMAL(14,2),
    net_income              DECIMAL(14,2),

    PRIMARY KEY (date_key, year)
);

-- ---------------------------------------------------------------------------
-- fact_channel_mix: Channel distribution — one row per year × channel
-- (Directly models the Distribution Channel Analysis Report)
-- ---------------------------------------------------------------------------
CREATE TABLE fact_channel_mix (
    year                INT,
    channel_key         INT REFERENCES dim_channel(channel_key),
    pct_room_revenue    DECIMAL(5,2),          -- % of total room revenue
    room_revenue        DECIMAL(14,2),         -- derived: pct × total room rev
    rooms_sold          INT,
    avg_rate_incl_vat   DECIMAL(10,2),
    commission_paid     DECIMAL(14,2),
    net_revenue         DECIMAL(14,2),         -- revenue minus commission
    PRIMARY KEY (year, channel_key)
);

-- ---------------------------------------------------------------------------
-- fact_segment_mix: Segment performance — one row per year × segment
-- (Directly models the Market Segmentation Report)
-- ---------------------------------------------------------------------------
CREATE TABLE fact_segment_mix (
    year                INT,
    segment_key         INT REFERENCES dim_segment(segment_key),
    pct_room_revenue    DECIMAL(5,2),          -- % of total room revenue
    room_revenue        DECIMAL(14,2),
    rooms_sold          INT,
    avg_rate_incl_vat   DECIMAL(10,2),         -- from segmentation report
    avg_rate_excl_vat   DECIMAL(10,2),
    reimbursement_received DECIMAL(14,2),      -- non-zero only for Loyalty Club
    PRIMARY KEY (year, segment_key)
);

-- ---------------------------------------------------------------------------
-- fact_str_benchmark: STR competitive set data — one row per date × hotel
-- (Models the STR Trend Report)
-- ---------------------------------------------------------------------------
CREATE TABLE fact_str_benchmark (
    date_key        INT REFERENCES dim_date(date_key),
    hotel_key       INT REFERENCES dim_compset(hotel_key),
    occupancy_pct   DECIMAL(5,2),
    adr             DECIMAL(10,2),
    revpar          DECIMAL(10,2),
    PRIMARY KEY (date_key, hotel_key)
);


-- ============================================================================
-- 3. RELATIONSHIPS (ERD Summary)
-- ============================================================================
/*
    dim_date ──────────┐
    dim_channel ───────┤
    dim_segment ───────┼──── fact_daily_rooms (grain: date × channel × segment × room_type × rate_plan)
    dim_room_type ─────┤
    dim_rate_plan ─────┘

    dim_date ──────────────── fact_daily_inventory (grain: date)

    dim_date ──────────────── fact_pnl_monthly (grain: month × year)

    dim_date ───────┐
    dim_channel ────┴─────── fact_channel_mix (grain: year × channel)

    dim_date ───────┐
    dim_segment ────┴─────── fact_segment_mix (grain: year × segment)

    dim_date ───────┐
    dim_compset ────┴─────── fact_str_benchmark (grain: date × hotel)
*/


-- ============================================================================
-- 4. CORE KPIs — SQL definitions
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 4A. OCCUPANCY & RATE KPIs
-- ---------------------------------------------------------------------------

-- Occupancy Rate
-- = Rooms Sold / Rooms Available
-- Hotel: 78.2% (2015)
SELECT
    rooms_sold * 1.0 / rooms_available_to_sell AS occupancy_rate
FROM fact_daily_inventory;

-- ADR (Average Daily Rate) — gross, incl. VAT
-- = Room Revenue / Rooms Sold
-- Hotel: EUR 168.1 (2015)
SELECT
    SUM(room_revenue_incl_vat) / NULLIF(SUM(rooms_sold), 0) AS adr_gross
FROM fact_daily_rooms;

-- Net ADR — after removing acquisition costs
-- = (Room Revenue - Commissions - Loyalty Earn Cost - CRS Fees) / Rooms Sold
SELECT
    (SUM(room_revenue_excl_vat) - SUM(commission_amount) - SUM(loyalty_earn_cost) - SUM(crs_fee_amount))
    / NULLIF(SUM(rooms_sold), 0) AS net_adr
FROM fact_daily_rooms;

-- RevPAR (Revenue Per Available Room)
-- = Room Revenue / Available Rooms  OR  ADR × Occupancy
-- Hotel: EUR 109.6 excl VAT, EUR 131.5 incl VAT (2015)
SELECT
    SUM(room_revenue_excl_vat) / NULLIF(SUM(i.rooms_available_to_sell), 0) AS revpar
FROM fact_daily_rooms r
JOIN fact_daily_inventory i ON r.date_key = i.date_key;

-- Net RevPAR — the critical metric for this case
-- = (Room Revenue - Total Acquisition Costs) / Available Rooms
SELECT
    (SUM(room_revenue_excl_vat) - SUM(commission_amount) - SUM(loyalty_earn_cost)
     - SUM(crs_fee_amount) - SUM(transaction_fee))
    / NULLIF(SUM(i.rooms_available_to_sell), 0) AS net_revpar
FROM fact_daily_rooms r
JOIN fact_daily_inventory i ON r.date_key = i.date_key;


-- ---------------------------------------------------------------------------
-- 4B. PROFITABILITY KPIs
-- ---------------------------------------------------------------------------

-- GOPPAR (Gross Operating Profit Per Available Room)
-- = GOP / Total Available Room-Nights
-- Critical for owner (Sayer family) — captures cost efficiency
SELECT
    SUM(goi) / (300 * 365.0) AS goppar
FROM fact_pnl_monthly;

-- EBITDAR per Available Room
SELECT
    SUM(ebitdar) / (300 * 365.0) AS ebitdar_par
FROM fact_pnl_monthly;

-- TRevPAR (Total Revenue Per Available Room)
-- = Total Revenue / Available Room-Nights
-- Captures F&B + Other revenue contribution
SELECT
    SUM(total_revenue) / (300 * 365.0) AS trevpar
FROM fact_pnl_monthly;

-- Room Department GOI Margin
-- Hotel: declining from 65% → 63.7% (2011–2015)
SELECT
    SUM(room_goi) / NULLIF(SUM(room_revenue), 0) AS room_goi_margin
FROM fact_pnl_monthly;

-- Flow-Through Rate (incremental revenue → GOP conversion)
-- = Change in GOP / Change in Total Revenue (YoY)
-- Tells you how much of each extra euro reaches the bottom line


-- ---------------------------------------------------------------------------
-- 4C. CHANNEL ECONOMICS KPIs
-- ---------------------------------------------------------------------------

-- Channel Cost Ratio (per channel)
-- = Total Acquisition Cost / Room Revenue for that channel
SELECT
    c.channel_name,
    SUM(r.commission_amount + r.crs_fee_amount + r.loyalty_earn_cost)
        / NULLIF(SUM(r.room_revenue_excl_vat), 0) AS channel_cost_ratio
FROM fact_daily_rooms r
JOIN dim_channel c ON r.channel_key = c.channel_key
GROUP BY c.channel_name;

-- OTA Share of Revenue — key warning metric
-- Hotel: grew from 20% → 29% (2011–2015)
SELECT
    year,
    SUM(CASE WHEN c.channel_category = 'OTA' THEN pct_room_revenue ELSE 0 END) AS ota_share
FROM fact_channel_mix cm
JOIN dim_channel c ON cm.channel_key = c.channel_key
GROUP BY year;

-- Direct Share of Revenue
-- Hotel: declined from 55% → 47% (2011–2015)
SELECT
    year,
    SUM(CASE WHEN c.channel_category = 'Direct' THEN pct_room_revenue ELSE 0 END) AS direct_share
FROM fact_channel_mix cm
JOIN dim_channel c ON cm.channel_key = c.channel_key
GROUP BY year;

-- Commission Load — total commissions as % of room revenue
-- Hotel: commissions grew from EUR 263K → EUR 385K (2011–2015)
SELECT
    year,
    SUM(commissions) / NULLIF(SUM(room_revenue), 0) AS commission_load_pct
FROM fact_pnl_monthly
GROUP BY year;

-- Net Revenue per Channel
-- = Room Revenue from Channel - Commission Paid to Channel
SELECT
    c.channel_name,
    SUM(cm.room_revenue) - SUM(cm.commission_paid) AS net_channel_revenue
FROM fact_channel_mix cm
JOIN dim_channel c ON cm.channel_key = c.channel_key
GROUP BY c.channel_name;


-- ---------------------------------------------------------------------------
-- 4D. SEGMENT ECONOMICS KPIs
-- ---------------------------------------------------------------------------

-- Segment ADR vs. Blended ADR
-- Reveals underpricing: Loyalty Club at EUR 95 vs. avg EUR 168 (2015)
SELECT
    s.segment_name,
    sm.avg_rate_incl_vat,
    sm.avg_rate_incl_vat / NULLIF(AVG(sm.avg_rate_incl_vat) OVER (), 0) AS rate_index
FROM fact_segment_mix sm
JOIN dim_segment s ON sm.segment_key = s.segment_key
WHERE sm.year = 2015;

-- Loyalty Redemption Displacement Cost
-- = (Rooms Redeemed × Market ADR) - Reimbursement Received
-- Measures the revenue "left on the table" from no-blackout policy
SELECT
    sm.year,
    sm.rooms_sold AS loyalty_rooms,
    sm.rooms_sold * overall.avg_adr AS potential_revenue_at_market_rate,
    sm.reimbursement_received,
    (sm.rooms_sold * overall.avg_adr) - sm.reimbursement_received AS displacement_cost
FROM fact_segment_mix sm
JOIN dim_segment s ON sm.segment_key = s.segment_key
CROSS JOIN (
    SELECT year, SUM(room_revenue_incl_vat) / NULLIF(SUM(rooms_sold), 0) AS avg_adr
    FROM fact_segment_mix GROUP BY year
) overall ON sm.year = overall.year
WHERE s.is_redemption = TRUE;

-- Segment Contribution Margin
-- = (Segment Revenue - Segment Acquisition Costs) / Segment Revenue
-- Compare Business (high margin, low commission) vs OTA Leisure (high commission)

-- Revenue Concentration Risk
-- = Revenue from Top 2 Channels / Total Revenue
-- Tracks dependency on Booking + Expedia


-- ---------------------------------------------------------------------------
-- 4E. COMPETITIVE POSITION KPIs (from STR data)
-- ---------------------------------------------------------------------------

-- ADR Index (ARI) = Hotel ADR / CompSet ADR × 100
-- Hotel appears to price above compset
SELECT
    d.full_date,
    hotel.adr / NULLIF(compset.adr, 0) * 100 AS ari
FROM fact_str_benchmark hotel
JOIN fact_str_benchmark compset ON hotel.date_key = compset.date_key
JOIN dim_compset h ON hotel.hotel_key = h.hotel_key AND h.is_own_hotel = TRUE
JOIN dim_compset c ON compset.hotel_key = c.hotel_key AND c.is_own_hotel = FALSE
JOIN dim_date d ON hotel.date_key = d.date_key;

-- MPI (Market Penetration Index) = Hotel Occ / CompSet Occ × 100
-- RevPAR Index (RGI) = Hotel RevPAR / CompSet RevPAR × 100
-- RGI = ARI × MPI / 100


-- ---------------------------------------------------------------------------
-- 4F. BRAND FEE BURDEN KPIs (specific to this case)
-- ---------------------------------------------------------------------------

-- Total Stillwood Fee Load as % of Room Revenue
-- Includes: Marketing (2%) + Distribution (2%) + CRS (0.5%) + Loyalty Earn (6% of club rev)
--         + Trademark (2%) + Base Mgmt (5% total rev) + Incentive (3% GOP3)
SELECT
    year,
    SUM(marketing_contribution + distribution_fee + crs_fee + loyalty_club_fee_earn
        + trademark_royalty + base_management_fee + incentive_fee)
        / NULLIF(SUM(room_revenue), 0) AS total_brand_fee_pct_room_rev,
    SUM(marketing_contribution + distribution_fee + crs_fee + loyalty_club_fee_earn
        + trademark_royalty + base_management_fee + incentive_fee)
        / NULLIF(SUM(total_revenue), 0) AS total_brand_fee_pct_total_rev
FROM fact_pnl_monthly
GROUP BY year;

-- Fee-Adjusted GOPPAR
-- = (GOP - All Stillwood Fees) / Available Room-Nights
-- The "true" owner return metric


-- ============================================================================
-- 5. DERIVED / COMPOSITE METRICS FOR REVENUE MANAGEMENT
-- ============================================================================

/*
METRIC                          FORMULA                                             PURPOSE
-------------------------------+---------------------------------------------------+------------------------------------------------
Net ADR by Segment×Channel      (SegChan Rev - SegChan Costs) / SegChan Rooms       Identify most profitable booking combinations
Loyalty Displacement Cost       Loyalty Rooms × (Market ADR - Reimbursement Rate)   Quantify no-blackout-date revenue leak
Channel Shift Velocity          YoY change in channel share (pp)                    Track speed of OTA share growth
Commission Elasticity           Δ Commission Load / Δ OTA Share                     Commission sensitivity to channel mix shift
Break-Even Occupancy            Fixed Costs / (ADR - Variable Cost per Room)         Min occupancy to cover costs
Marginal Room Revenue           Net ADR of next room sold (by channel)              Optimize last-room-available decisions
RevPAR Gap to CompSet           Hotel RevPAR - CompSet RevPAR                       Absolute performance gap
Rate Parity Variance            Direct Rate - OTA Rate (same date/room)             Detect rate parity violations
F&B Capture Rate                F&B Revenue / Room Revenue                          Ancillary revenue opportunity (growing: 12→16%)
Total Guest Value               Room Rev + F&B Rev + Other Rev per guest-night      Holistic guest profitability
Owner Return Ratio              EBITDAR / Total Revenue                             Owner's actual yield (declining: 32.7→29.8%)
Debt Service Coverage           EBITDAR / Interest Expense                          Financial health (interest ~EUR 3.3M vs EBITDAR ~EUR 4.3M)
Cost Per Occupied Room (CPOR)   (Room Payroll + Room Expenses) / Rooms Sold         Operational efficiency check
*/


-- ============================================================================
-- 6. REFERENCE DATA — Pre-populated from case materials
-- ============================================================================

-- Channel dimension seed data
INSERT INTO dim_channel (channel_key, channel_name, channel_category, flows_through_crs, commission_rate_pct, is_brand_controlled) VALUES
(1, 'Direct',        'Direct',    TRUE,  0.00,  TRUE),
(2, 'GDS',           'GDS',       TRUE,  10.00, FALSE),   -- typical GDS commission
(3, 'Central Voice', 'Direct',    TRUE,  0.00,  TRUE),
(4, 'Web Direct',    'Direct',    TRUE,  0.00,  TRUE),
(5, 'Expedia',       'OTA',       FALSE, 15.00, FALSE),   -- ~15% after Stillwood discount
(6, 'Booking',       'OTA',       FALSE, 15.00, FALSE),   -- ~15% after Stillwood discount
(7, 'Other OTAs',    'OTA',       FALSE, 18.00, FALSE),   -- smaller OTAs, less discount
(8, 'Bedbanks',      'Wholesale', FALSE, 25.00, FALSE);   -- typical wholesale margin

-- Segment dimension seed data
INSERT INTO dim_segment (segment_key, segment_name, segment_type, is_negotiated, is_redemption, reimbursement_rate) VALUES
(1, 'Business',      'Transient',  TRUE,  FALSE, 1.00),
(2, 'Leisure',       'Transient',  FALSE, FALSE, 1.00),
(3, 'Loyalty Club',  'Redemption', FALSE, TRUE,  0.50),   -- 50% of rack rate
(4, 'Group',         'Group',      TRUE,  FALSE, 1.00),
(5, 'MICE',          'Group',      TRUE,  FALSE, 1.00);

-- Hotel constants
-- Total rooms:        300
-- Days per year:      365
-- Available room-nights: 109,500
-- VAT rate:           ~20% (FR standard for hotels)
