-- ============================================================================
-- HOTEL DE L'ETOILE — POWER BI KPI QUERIES
-- Queries feeding the Power BI data model
-- Schema reference: data_model_and_kpis.sql
--
-- Sections:
--   1. Daily KPI Snapshot
--   2. Channel Performance Aggregation
--   3. Segment Analysis
--   4. Competitive Set Comparison
--   5. Monthly Trend Data
-- ============================================================================


-- ============================================================================
-- 1. DAILY KPI SNAPSHOT
-- Purpose: Primary dataset for Page 1 (Executive Summary) and date-level
--          drill-through. One row per day with all core performance metrics.
-- ============================================================================

SELECT
    d.date_key,
    d.full_date,
    d.year,
    d.quarter,
    d.month,
    d.month_name,
    d.week_of_year,
    d.day_of_week,
    d.day_name,
    d.is_weekend,
    d.is_paris_holiday,
    d.is_trade_show,
    d.season,

    -- Inventory metrics
    i.total_rooms_available,
    i.rooms_available_to_sell,
    i.rooms_sold,
    i.rooms_unsold,
    i.no_shows,
    i.cancellations,
    i.walk_ins,
    i.overbooking_count,

    -- Occupancy
    CAST(i.rooms_sold AS DECIMAL(10,4))
        / NULLIF(i.rooms_available_to_sell, 0)          AS occupancy_pct,

    -- Revenue aggregates for the day
    r.room_revenue_incl_vat,
    r.room_revenue_excl_vat,

    -- ADR
    r.room_revenue_incl_vat
        / NULLIF(i.rooms_sold, 0)                       AS adr_incl_vat,
    r.room_revenue_excl_vat
        / NULLIF(i.rooms_sold, 0)                       AS adr_excl_vat,

    -- RevPAR
    r.room_revenue_excl_vat
        / NULLIF(i.rooms_available_to_sell, 0)          AS revpar_excl_vat,
    r.room_revenue_incl_vat
        / NULLIF(i.rooms_available_to_sell, 0)          AS revpar_incl_vat,

    -- Acquisition costs
    r.total_commission,
    r.total_loyalty_earn,
    r.total_crs_fee,
    r.total_transaction_fee,
    r.total_acquisition_cost,

    -- Net metrics
    (r.room_revenue_excl_vat - r.total_acquisition_cost)
        / NULLIF(i.rooms_sold, 0)                       AS net_adr,
    (r.room_revenue_excl_vat - r.total_acquisition_cost)
        / NULLIF(i.rooms_available_to_sell, 0)          AS net_revpar

FROM dim_date d

JOIN fact_daily_inventory i
    ON d.date_key = i.date_key

LEFT JOIN (
    SELECT
        date_key,
        SUM(rooms_sold)                 AS rooms_sold_detail,
        SUM(room_revenue_incl_vat)      AS room_revenue_incl_vat,
        SUM(room_revenue_excl_vat)      AS room_revenue_excl_vat,
        SUM(commission_amount)          AS total_commission,
        SUM(loyalty_earn_cost)          AS total_loyalty_earn,
        SUM(crs_fee_amount)             AS total_crs_fee,
        SUM(transaction_fee)            AS total_transaction_fee,
        SUM(commission_amount)
            + SUM(loyalty_earn_cost)
            + SUM(crs_fee_amount)
            + SUM(transaction_fee)      AS total_acquisition_cost
    FROM fact_daily_rooms
    GROUP BY date_key
) r ON d.date_key = r.date_key

ORDER BY d.full_date;


-- ============================================================================
-- 2. CHANNEL PERFORMANCE AGGREGATION
-- Purpose: Dataset for Page 2 (Channel Performance). Aggregates revenue,
--          cost, and room-night data by channel and period.
-- ============================================================================

-- 2A. Channel summary by year (trend analysis)
SELECT
    d.year,
    c.channel_key,
    c.channel_name,
    c.channel_category,
    c.commission_rate_pct,
    c.is_brand_controlled,

    SUM(r.rooms_sold)                           AS rooms_sold,
    SUM(r.room_revenue_incl_vat)                AS room_revenue_incl_vat,
    SUM(r.room_revenue_excl_vat)                AS room_revenue_excl_vat,

    -- ADR by channel
    SUM(r.room_revenue_incl_vat)
        / NULLIF(SUM(r.rooms_sold), 0)          AS channel_adr,

    -- Costs
    SUM(r.commission_amount)                    AS commission_paid,
    SUM(r.crs_fee_amount)                       AS crs_fees,
    SUM(r.loyalty_earn_cost)                    AS loyalty_cost,
    SUM(r.transaction_fee)                      AS transaction_fees,
    SUM(r.commission_amount)
        + SUM(r.crs_fee_amount)
        + SUM(r.loyalty_earn_cost)
        + SUM(r.transaction_fee)                AS total_acquisition_cost,

    -- Net revenue
    SUM(r.room_revenue_excl_vat)
        - SUM(r.commission_amount)
        - SUM(r.crs_fee_amount)
        - SUM(r.loyalty_earn_cost)
        - SUM(r.transaction_fee)                AS net_revenue,

    -- Channel cost ratio
    (SUM(r.commission_amount) + SUM(r.crs_fee_amount) + SUM(r.loyalty_earn_cost))
        / NULLIF(SUM(r.room_revenue_excl_vat), 0) AS channel_cost_ratio,

    -- Channel share of total revenue (window function)
    SUM(r.room_revenue_excl_vat)
        / NULLIF(SUM(SUM(r.room_revenue_excl_vat)) OVER (PARTITION BY d.year), 0)
                                                AS channel_revenue_share

FROM fact_daily_rooms r
JOIN dim_date d       ON r.date_key    = d.date_key
JOIN dim_channel c    ON r.channel_key = c.channel_key

GROUP BY
    d.year,
    c.channel_key,
    c.channel_name,
    c.channel_category,
    c.commission_rate_pct,
    c.is_brand_controlled

ORDER BY d.year, SUM(r.room_revenue_excl_vat) DESC;


-- 2B. Channel category roll-up (Direct vs OTA vs GDS vs Wholesale)
SELECT
    d.year,
    c.channel_category,

    SUM(r.rooms_sold)                           AS rooms_sold,
    SUM(r.room_revenue_excl_vat)                AS room_revenue,
    SUM(r.commission_amount)                    AS commission_paid,
    SUM(r.room_revenue_excl_vat)
        - SUM(r.commission_amount)              AS net_revenue,

    SUM(r.room_revenue_excl_vat)
        / NULLIF(SUM(SUM(r.room_revenue_excl_vat)) OVER (PARTITION BY d.year), 0)
                                                AS category_share

FROM fact_daily_rooms r
JOIN dim_date d       ON r.date_key    = d.date_key
JOIN dim_channel c    ON r.channel_key = c.channel_key

GROUP BY d.year, c.channel_category
ORDER BY d.year, SUM(r.room_revenue_excl_vat) DESC;


-- ============================================================================
-- 3. SEGMENT ANALYSIS
-- Purpose: Dataset for Page 3 (Market Segmentation). Revenue, rate, and
--          displacement analysis by guest segment and rate plan.
-- ============================================================================

-- 3A. Segment performance by year
SELECT
    d.year,
    s.segment_key,
    s.segment_name,
    s.segment_type,
    s.is_negotiated,
    s.is_redemption,
    s.reimbursement_rate,

    SUM(r.rooms_sold)                           AS rooms_sold,
    SUM(r.guests)                               AS total_guests,
    SUM(r.room_revenue_incl_vat)                AS room_revenue_incl_vat,
    SUM(r.room_revenue_excl_vat)                AS room_revenue_excl_vat,

    -- Segment ADR
    SUM(r.room_revenue_incl_vat)
        / NULLIF(SUM(r.rooms_sold), 0)          AS segment_adr_incl_vat,
    SUM(r.room_revenue_excl_vat)
        / NULLIF(SUM(r.rooms_sold), 0)          AS segment_adr_excl_vat,

    -- Segment share
    SUM(r.room_revenue_excl_vat)
        / NULLIF(SUM(SUM(r.room_revenue_excl_vat)) OVER (PARTITION BY d.year), 0)
                                                AS segment_revenue_share,

    -- Acquisition costs by segment
    SUM(r.commission_amount)                    AS commission_paid,
    SUM(r.loyalty_earn_cost)                    AS loyalty_cost,
    SUM(r.reimbursement_received)               AS reimbursement_received,

    -- Segment net revenue
    SUM(r.room_revenue_excl_vat)
        - SUM(r.commission_amount)
        - SUM(r.loyalty_earn_cost)              AS segment_net_revenue

FROM fact_daily_rooms r
JOIN dim_date d       ON r.date_key    = d.date_key
JOIN dim_segment s    ON r.segment_key = s.segment_key

GROUP BY
    d.year,
    s.segment_key,
    s.segment_name,
    s.segment_type,
    s.is_negotiated,
    s.is_redemption,
    s.reimbursement_rate

ORDER BY d.year, SUM(r.room_revenue_excl_vat) DESC;


-- 3B. Loyalty displacement cost calculation
SELECT
    d.year,
    loyalty.loyalty_rooms,
    loyalty.reimbursement_received,
    market.blended_adr,
    loyalty.loyalty_rooms * market.blended_adr   AS potential_revenue_at_market_rate,
    (loyalty.loyalty_rooms * market.blended_adr)
        - loyalty.reimbursement_received         AS displacement_cost

FROM (
    SELECT DISTINCT year FROM dim_date
) d

JOIN (
    SELECT
        dd.year,
        SUM(r.rooms_sold)                       AS loyalty_rooms,
        SUM(r.reimbursement_received)           AS reimbursement_received
    FROM fact_daily_rooms r
    JOIN dim_date dd     ON r.date_key    = dd.date_key
    JOIN dim_segment s   ON r.segment_key = s.segment_key
    WHERE s.is_redemption = TRUE
    GROUP BY dd.year
) loyalty ON d.year = loyalty.year

JOIN (
    SELECT
        dd.year,
        SUM(r.room_revenue_incl_vat)
            / NULLIF(SUM(r.rooms_sold), 0)      AS blended_adr
    FROM fact_daily_rooms r
    JOIN dim_date dd ON r.date_key = dd.date_key
    GROUP BY dd.year
) market ON d.year = market.year

ORDER BY d.year;


-- 3C. Segment x Channel cross-tabulation
SELECT
    d.year,
    s.segment_name,
    c.channel_category,
    c.channel_name,
    SUM(r.rooms_sold)                           AS rooms_sold,
    SUM(r.room_revenue_excl_vat)                AS room_revenue,
    SUM(r.room_revenue_incl_vat)
        / NULLIF(SUM(r.rooms_sold), 0)          AS avg_rate,
    SUM(r.commission_amount)                    AS commission_paid

FROM fact_daily_rooms r
JOIN dim_date d       ON r.date_key    = d.date_key
JOIN dim_segment s    ON r.segment_key = s.segment_key
JOIN dim_channel c    ON r.channel_key = c.channel_key

GROUP BY d.year, s.segment_name, c.channel_category, c.channel_name
ORDER BY d.year, s.segment_name, SUM(r.room_revenue_excl_vat) DESC;


-- 3D. Rate plan analysis
SELECT
    d.year,
    rp.rate_plan_key,
    rp.rate_plan_name,
    rp.rate_plan_type,
    rp.is_public,
    rp.is_refundable,

    SUM(r.rooms_sold)                           AS rooms_sold,
    SUM(r.room_revenue_incl_vat)                AS room_revenue_incl_vat,
    SUM(r.room_revenue_incl_vat)
        / NULLIF(SUM(r.rooms_sold), 0)          AS avg_rate,

    SUM(r.room_revenue_excl_vat)
        / NULLIF(SUM(SUM(r.room_revenue_excl_vat)) OVER (PARTITION BY d.year), 0)
                                                AS rate_plan_share

FROM fact_daily_rooms r
JOIN dim_date d          ON r.date_key      = d.date_key
JOIN dim_rate_plan rp    ON r.rate_plan_key  = rp.rate_plan_key

GROUP BY
    d.year,
    rp.rate_plan_key,
    rp.rate_plan_name,
    rp.rate_plan_type,
    rp.is_public,
    rp.is_refundable

ORDER BY d.year, SUM(r.rooms_sold) DESC;


-- ============================================================================
-- 4. COMPETITIVE SET COMPARISON
-- Purpose: Dataset for Page 4 (Competitive Analysis). STR benchmark data
--          with index calculations.
-- ============================================================================

-- 4A. Monthly index comparison (Hotel vs CompSet average)
SELECT
    d.year,
    d.month,
    d.month_name,
    d.season,

    -- Hotel metrics
    hotel.hotel_occupancy,
    hotel.hotel_adr,
    hotel.hotel_revpar,

    -- CompSet average metrics
    compset.compset_occupancy,
    compset.compset_adr,
    compset.compset_revpar,

    -- Performance indices
    hotel.hotel_occupancy
        / NULLIF(compset.compset_occupancy, 0) * 100    AS mpi,
    hotel.hotel_adr
        / NULLIF(compset.compset_adr, 0) * 100          AS ari,
    hotel.hotel_revpar
        / NULLIF(compset.compset_revpar, 0) * 100       AS rgi,

    -- Absolute gaps
    hotel.hotel_revpar - compset.compset_revpar          AS revpar_gap,
    hotel.hotel_adr    - compset.compset_adr             AS adr_gap,
    hotel.hotel_occupancy - compset.compset_occupancy    AS occupancy_gap_pp

FROM (
    SELECT DISTINCT year, month, month_name, season FROM dim_date
) d

LEFT JOIN (
    SELECT
        dd.year,
        dd.month,
        AVG(b.occupancy_pct)    AS hotel_occupancy,
        AVG(b.adr)              AS hotel_adr,
        AVG(b.revpar)           AS hotel_revpar
    FROM fact_str_benchmark b
    JOIN dim_compset h   ON b.hotel_key = h.hotel_key AND h.is_own_hotel = TRUE
    JOIN dim_date dd     ON b.date_key  = dd.date_key
    GROUP BY dd.year, dd.month
) hotel ON d.year = hotel.year AND d.month = hotel.month

LEFT JOIN (
    SELECT
        dd.year,
        dd.month,
        AVG(b.occupancy_pct)    AS compset_occupancy,
        AVG(b.adr)              AS compset_adr,
        AVG(b.revpar)           AS compset_revpar
    FROM fact_str_benchmark b
    JOIN dim_compset c   ON b.hotel_key = c.hotel_key AND c.is_own_hotel = FALSE
    JOIN dim_date dd     ON b.date_key  = dd.date_key
    GROUP BY dd.year, dd.month
) compset ON d.year = compset.year AND d.month = compset.month

ORDER BY d.year, d.month;


-- 4B. Seasonal index summary
SELECT
    d.year,
    d.season,

    AVG(hotel.occupancy_pct)                                    AS hotel_occ,
    AVG(compset.occupancy_pct)                                  AS compset_occ,
    AVG(hotel.occupancy_pct)
        / NULLIF(AVG(compset.occupancy_pct), 0) * 100          AS mpi,

    AVG(hotel.adr)                                              AS hotel_adr,
    AVG(compset.adr)                                            AS compset_adr,
    AVG(hotel.adr)
        / NULLIF(AVG(compset.adr), 0) * 100                    AS ari,

    AVG(hotel.revpar)                                           AS hotel_revpar,
    AVG(compset.revpar)                                         AS compset_revpar,
    AVG(hotel.revpar)
        / NULLIF(AVG(compset.revpar), 0) * 100                 AS rgi

FROM dim_date d

LEFT JOIN (
    SELECT b.date_key, b.occupancy_pct, b.adr, b.revpar
    FROM fact_str_benchmark b
    JOIN dim_compset h ON b.hotel_key = h.hotel_key AND h.is_own_hotel = TRUE
) hotel ON d.date_key = hotel.date_key

LEFT JOIN (
    SELECT b.date_key, b.occupancy_pct, b.adr, b.revpar
    FROM fact_str_benchmark b
    JOIN dim_compset c ON b.hotel_key = c.hotel_key AND c.is_own_hotel = FALSE
) compset ON d.date_key = compset.date_key

GROUP BY d.year, d.season
ORDER BY d.year, d.season;


-- 4C. Individual compset hotel detail (for drill-through)
SELECT
    d.full_date,
    d.year,
    d.month,
    d.season,
    h.hotel_name,
    h.star_rating,
    h.room_count,
    h.is_own_hotel,
    b.occupancy_pct,
    b.adr,
    b.revpar

FROM fact_str_benchmark b
JOIN dim_date d       ON b.date_key  = d.date_key
JOIN dim_compset h    ON b.hotel_key = h.hotel_key

ORDER BY d.full_date, h.hotel_name;


-- ============================================================================
-- 5. MONTHLY TREND DATA
-- Purpose: P&L-based trend dataset for revenue decomposition, profitability
--          tracking, and Stillwood fee analysis across all dashboard pages.
-- ============================================================================

-- 5A. Monthly P&L with derived KPIs
SELECT
    p.year,
    d.month,
    d.month_name,

    -- Revenue lines
    p.room_revenue,
    p.fb_revenue,
    p.other_revenue,
    p.total_revenue,

    -- Revenue per available room (300 rooms x days in month)
    p.room_revenue
        / NULLIF(300.0 * inv.days_in_month, 0)                  AS revpar_monthly,
    p.total_revenue
        / NULLIF(300.0 * inv.days_in_month, 0)                  AS trevpar_monthly,

    -- Departmental profit
    p.room_goi,
    p.fb_goi,
    p.misc_goi,
    p.goi_before_unallocated,

    -- Margins
    p.room_goi / NULLIF(p.room_revenue, 0)                      AS room_goi_margin,
    p.fb_goi   / NULLIF(p.fb_revenue, 0)                        AS fb_goi_margin,
    p.goi      / NULLIF(p.total_revenue, 0)                     AS goi_margin,

    -- Distribution costs
    p.commissions,
    p.commissions / NULLIF(p.room_revenue, 0)                   AS commission_load_pct,

    -- F&B capture
    p.fb_revenue / NULLIF(p.room_revenue, 0)                    AS fb_capture_rate,

    -- GOP and operating profit
    p.goi,
    p.gop_before_fees,
    p.gop_after_fees,

    -- Stillwood fees itemized
    p.marketing_contribution,
    p.distribution_fee,
    p.crs_fee,
    p.loyalty_club_fee_earn,
    p.trademark_royalty,
    p.base_management_fee,
    p.incentive_fee,
    p.total_billable_services,

    -- Total Stillwood fee load
    (p.marketing_contribution + p.distribution_fee + p.crs_fee
     + p.loyalty_club_fee_earn + p.trademark_royalty
     + p.base_management_fee + p.incentive_fee)                 AS total_stillwood_fees,

    (p.marketing_contribution + p.distribution_fee + p.crs_fee
     + p.loyalty_club_fee_earn + p.trademark_royalty
     + p.base_management_fee + p.incentive_fee)
        / NULLIF(p.room_revenue, 0)                             AS stillwood_fee_pct_room_rev,

    -- Bottom line
    p.ebitdar,
    p.ebitdar / NULLIF(p.total_revenue, 0)                      AS ebitdar_margin,
    p.ebitdar / NULLIF(300.0 * inv.days_in_month, 0)            AS ebitdar_par,
    p.ebit,
    p.net_income,

    -- GOPPAR
    p.goi / NULLIF(300.0 * inv.days_in_month, 0)               AS goppar_monthly,

    -- Cost per occupied room
    (p.room_payroll + p.room_expenses)
        / NULLIF(inv.monthly_rooms_sold, 0)                     AS cpor

FROM fact_pnl_monthly p

JOIN (
    SELECT
        dd.year,
        dd.month,
        dd.month_name,
        COUNT(DISTINCT dd.full_date)    AS days_in_month,
        SUM(i.rooms_sold)               AS monthly_rooms_sold
    FROM dim_date dd
    JOIN fact_daily_inventory i ON dd.date_key = i.date_key
    GROUP BY dd.year, dd.month, dd.month_name
) d ON p.year = d.year
       AND p.date_key = p.year * 10000 + d.month * 100 + 1

LEFT JOIN (
    SELECT
        dd.year,
        dd.month,
        COUNT(DISTINCT dd.full_date)    AS days_in_month,
        SUM(i.rooms_sold)               AS monthly_rooms_sold
    FROM fact_daily_inventory i
    JOIN dim_date dd ON i.date_key = dd.date_key
    GROUP BY dd.year, dd.month
) inv ON p.year = inv.year AND d.month = inv.month

ORDER BY p.year, d.month;


-- 5B. Annual summary for YoY comparison
SELECT
    p.year,

    SUM(p.room_revenue)                         AS room_revenue,
    SUM(p.fb_revenue)                           AS fb_revenue,
    SUM(p.total_revenue)                        AS total_revenue,

    SUM(p.room_revenue) / (300.0 * 365)         AS revpar_annual,
    SUM(p.total_revenue) / (300.0 * 365)        AS trevpar_annual,

    SUM(p.room_goi)
        / NULLIF(SUM(p.room_revenue), 0)        AS room_goi_margin,

    SUM(p.commissions)                          AS total_commissions,
    SUM(p.commissions)
        / NULLIF(SUM(p.room_revenue), 0)        AS commission_load_pct,

    SUM(p.goi)                                  AS goi,
    SUM(p.goi) / (300.0 * 365)                  AS goppar_annual,

    SUM(p.ebitdar)                              AS ebitdar,
    SUM(p.ebitdar) / NULLIF(SUM(p.total_revenue), 0) AS owner_return_ratio,
    SUM(p.ebitdar) / (300.0 * 365)              AS ebitdar_par_annual,

    SUM(p.fb_revenue)
        / NULLIF(SUM(p.room_revenue), 0)        AS fb_capture_rate,

    SUM(p.marketing_contribution + p.distribution_fee + p.crs_fee
        + p.loyalty_club_fee_earn + p.trademark_royalty
        + p.base_management_fee + p.incentive_fee)  AS total_stillwood_fees,

    SUM(p.net_income)                           AS net_income

FROM fact_pnl_monthly p
GROUP BY p.year
ORDER BY p.year;


-- 5C. YoY variance calculation
SELECT
    curr.year,
    curr.room_revenue,
    prev.room_revenue                                           AS room_revenue_py,
    curr.room_revenue - prev.room_revenue                       AS revenue_variance,
    (curr.room_revenue - prev.room_revenue)
        / NULLIF(prev.room_revenue, 0)                          AS revenue_yoy_pct,

    curr.total_commissions,
    prev.total_commissions                                      AS commissions_py,
    curr.total_commissions - prev.total_commissions             AS commission_variance,

    curr.goppar_annual,
    prev.goppar_annual                                          AS goppar_py,
    curr.goppar_annual - prev.goppar_annual                     AS goppar_variance,

    curr.owner_return_ratio,
    prev.owner_return_ratio                                     AS owner_return_py,
    curr.owner_return_ratio - prev.owner_return_ratio           AS owner_return_variance_pp

FROM (
    SELECT
        year,
        SUM(room_revenue)                           AS room_revenue,
        SUM(commissions)                            AS total_commissions,
        SUM(goi) / (300.0 * 365)                    AS goppar_annual,
        SUM(ebitdar) / NULLIF(SUM(total_revenue), 0) AS owner_return_ratio
    FROM fact_pnl_monthly
    GROUP BY year
) curr

LEFT JOIN (
    SELECT
        year,
        SUM(room_revenue)                           AS room_revenue,
        SUM(commissions)                            AS total_commissions,
        SUM(goi) / (300.0 * 365)                    AS goppar_annual,
        SUM(ebitdar) / NULLIF(SUM(total_revenue), 0) AS owner_return_ratio
    FROM fact_pnl_monthly
    GROUP BY year
) prev ON curr.year = prev.year + 1

ORDER BY curr.year;
