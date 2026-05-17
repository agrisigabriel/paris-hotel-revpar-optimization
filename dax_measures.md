# Hotel de l'Etoile -- DAX Measures Reference

All DAX measures for the Power BI RevPAR Optimization dashboard.
Data model: star schema defined in `data_model_and_kpis.sql`.

---

## 1. Occupancy Metrics

### Rooms Sold

```dax
Rooms Sold =
    SUM( fact_daily_inventory[rooms_sold] )
```

Total room-nights sold across the selected period.

### Rooms Available

```dax
Rooms Available =
    SUM( fact_daily_inventory[rooms_available_to_sell] )
```

Total sellable room-nights (300 minus out-of-order rooms per day).

### Occupancy %

```dax
Occupancy % =
    DIVIDE(
        [Rooms Sold],
        [Rooms Available],
        0
    )
```

Core utilization metric. Hotel benchmark: 78.2% (2015).

### Rooms Unsold

```dax
Rooms Unsold =
    SUM( fact_daily_inventory[rooms_unsold] )
```

### No-Show Count

```dax
No-Shows =
    SUM( fact_daily_inventory[no_shows] )
```

### Cancellation Count

```dax
Cancellations =
    SUM( fact_daily_inventory[cancellations] )
```

---

## 2. Revenue Metrics

### Room Revenue (Incl. VAT)

```dax
Room Revenue Incl VAT =
    SUM( fact_daily_rooms[room_revenue_incl_vat] )
```

### Room Revenue (Excl. VAT)

```dax
Room Revenue Excl VAT =
    SUM( fact_daily_rooms[room_revenue_excl_vat] )
```

### ADR (Average Daily Rate)

```dax
ADR =
    DIVIDE(
        [Room Revenue Incl VAT],
        SUM( fact_daily_rooms[rooms_sold] ),
        0
    )
```

Gross average rate including VAT. Hotel benchmark: EUR 168.1 (2015).

### Net ADR

```dax
Net ADR =
    DIVIDE(
        [Room Revenue Excl VAT] - [Total Acquisition Costs],
        SUM( fact_daily_rooms[rooms_sold] ),
        0
    )
```

ADR after subtracting commissions, loyalty earn cost, CRS fees, and transaction fees. The true margin-per-room metric.

### Total Acquisition Costs

```dax
Total Acquisition Costs =
    SUM( fact_daily_rooms[commission_amount] )
    + SUM( fact_daily_rooms[loyalty_earn_cost] )
    + SUM( fact_daily_rooms[crs_fee_amount] )
    + SUM( fact_daily_rooms[transaction_fee] )
```

### RevPAR

```dax
RevPAR =
    DIVIDE(
        [Room Revenue Excl VAT],
        [Rooms Available],
        0
    )
```

Revenue per available room. Can also be computed as ADR x Occupancy %. Hotel benchmark: EUR 109.6 excl. VAT (2015).

### RevPAR Incl VAT

```dax
RevPAR Incl VAT =
    DIVIDE(
        [Room Revenue Incl VAT],
        [Rooms Available],
        0
    )
```

Gross RevPAR. Hotel benchmark: EUR 131.5 (2015).

### Net RevPAR

```dax
Net RevPAR =
    DIVIDE(
        [Room Revenue Excl VAT] - [Total Acquisition Costs],
        [Rooms Available],
        0
    )
```

The critical optimization metric for this case. Captures both rate and distribution cost efficiency.

### Total Revenue

```dax
Total Revenue =
    SUM( fact_pnl_monthly[total_revenue] )
```

Room + F&B + Other revenue from the P&L.

### TRevPAR (Total Revenue Per Available Room)

```dax
TRevPAR =
    DIVIDE(
        [Total Revenue],
        300 * COUNTROWS( VALUES( dim_date[full_date] ) ),
        0
    )
```

Captures ancillary revenue contribution. F&B capture rate grew from 12% to 16%.

### GOPPAR

```dax
GOPPAR =
    DIVIDE(
        SUM( fact_pnl_monthly[goi] ),
        300 * COUNTROWS( VALUES( dim_date[full_date] ) ),
        0
    )
```

Gross Operating Profit per available room. Key owner-return metric for the Sayer family.

### EBITDAR per Available Room

```dax
EBITDAR PAR =
    DIVIDE(
        SUM( fact_pnl_monthly[ebitdar] ),
        300 * COUNTROWS( VALUES( dim_date[full_date] ) ),
        0
    )
```

---

## 3. Channel Metrics

### Channel Room Revenue

```dax
Channel Room Revenue =
    SUM( fact_channel_mix[room_revenue] )
```

### Channel Mix %

```dax
Channel Mix % =
    DIVIDE(
        [Channel Room Revenue],
        CALCULATE(
            [Channel Room Revenue],
            ALL( dim_channel )
        ),
        0
    )
```

Share of room revenue by channel. Used in the channel performance donut chart.

### Direct Share %

```dax
Direct Share % =
    DIVIDE(
        CALCULATE(
            SUM( fact_channel_mix[room_revenue] ),
            dim_channel[channel_category] = "Direct"
        ),
        CALCULATE(
            SUM( fact_channel_mix[room_revenue] ),
            ALL( dim_channel )
        ),
        0
    )
```

Declined from 55% to 47% (2011-2015). A key warning indicator.

### OTA Share %

```dax
OTA Share % =
    DIVIDE(
        CALCULATE(
            SUM( fact_channel_mix[room_revenue] ),
            dim_channel[channel_category] = "OTA"
        ),
        CALCULATE(
            SUM( fact_channel_mix[room_revenue] ),
            ALL( dim_channel )
        ),
        0
    )
```

Grew from 20% to 29% (2011-2015).

### OTA Commission Cost

```dax
OTA Commission Cost =
    CALCULATE(
        SUM( fact_daily_rooms[commission_amount] ),
        dim_channel[channel_category] = "OTA"
    )
```

Total commissions paid to OTA partners.

### Total Commission Cost

```dax
Total Commission Cost =
    SUM( fact_daily_rooms[commission_amount] )
```

### Commission Load %

```dax
Commission Load % =
    DIVIDE(
        SUM( fact_pnl_monthly[commissions] ),
        SUM( fact_pnl_monthly[room_revenue] ),
        0
    )
```

Total commissions as a percentage of room revenue. Commissions grew from EUR 263K to EUR 385K (2011-2015).

### Channel Net Revenue

```dax
Channel Net Revenue =
    SUM( fact_channel_mix[net_revenue] )
```

Room revenue minus commission paid, per channel.

### Channel Cost Ratio

```dax
Channel Cost Ratio =
    DIVIDE(
        SUM( fact_daily_rooms[commission_amount] )
        + SUM( fact_daily_rooms[crs_fee_amount] )
        + SUM( fact_daily_rooms[loyalty_earn_cost] ),
        [Room Revenue Excl VAT],
        0
    )
```

Total acquisition cost as a share of room revenue, sliceable by channel.

---

## 4. Performance Indices (STR Competitive Set)

### Hotel ADR (STR)

```dax
Hotel ADR STR =
    CALCULATE(
        AVERAGE( fact_str_benchmark[adr] ),
        dim_compset[is_own_hotel] = TRUE
    )
```

### CompSet ADR (STR)

```dax
CompSet ADR STR =
    CALCULATE(
        AVERAGE( fact_str_benchmark[adr] ),
        dim_compset[is_own_hotel] = FALSE
    )
```

### ARI (ADR Index)

```dax
ARI =
    DIVIDE(
        [Hotel ADR STR],
        [CompSet ADR STR],
        0
    ) * 100
```

ADR Index. Value above 100 means the hotel prices above the competitive set.

### Hotel Occupancy (STR)

```dax
Hotel Occupancy STR =
    CALCULATE(
        AVERAGE( fact_str_benchmark[occupancy_pct] ),
        dim_compset[is_own_hotel] = TRUE
    )
```

### CompSet Occupancy (STR)

```dax
CompSet Occupancy STR =
    CALCULATE(
        AVERAGE( fact_str_benchmark[occupancy_pct] ),
        dim_compset[is_own_hotel] = FALSE
    )
```

### MPI (Market Penetration Index)

```dax
MPI =
    DIVIDE(
        [Hotel Occupancy STR],
        [CompSet Occupancy STR],
        0
    ) * 100
```

Occupancy index vs. competitive set. Above 100 = capturing more than fair share of demand.

### Hotel RevPAR (STR)

```dax
Hotel RevPAR STR =
    CALCULATE(
        AVERAGE( fact_str_benchmark[revpar] ),
        dim_compset[is_own_hotel] = TRUE
    )
```

### CompSet RevPAR (STR)

```dax
CompSet RevPAR STR =
    CALCULATE(
        AVERAGE( fact_str_benchmark[revpar] ),
        dim_compset[is_own_hotel] = FALSE
    )
```

### RGI (RevPAR Generation Index)

```dax
RGI =
    DIVIDE(
        [Hotel RevPAR STR],
        [CompSet RevPAR STR],
        0
    ) * 100
```

The composite performance index. RGI = ARI x MPI / 100. Above 100 = outperforming the market.

### RevPAR Gap to CompSet

```dax
RevPAR Gap =
    [Hotel RevPAR STR] - [CompSet RevPAR STR]
```

Absolute EUR gap between hotel and competitive set RevPAR.

---

## 5. Year-over-Year Comparisons

### Room Revenue PY (Prior Year)

```dax
Room Revenue PY =
    CALCULATE(
        [Room Revenue Excl VAT],
        SAMEPERIODLASTYEAR( dim_date[full_date] )
    )
```

### RevPAR PY

```dax
RevPAR PY =
    CALCULATE(
        [RevPAR],
        SAMEPERIODLASTYEAR( dim_date[full_date] )
    )
```

### ADR PY

```dax
ADR PY =
    CALCULATE(
        [ADR],
        SAMEPERIODLASTYEAR( dim_date[full_date] )
    )
```

### Occupancy PY

```dax
Occupancy PY =
    CALCULATE(
        [Occupancy %],
        SAMEPERIODLASTYEAR( dim_date[full_date] )
    )
```

### RevPAR YoY %

```dax
RevPAR YoY % =
    DIVIDE(
        [RevPAR] - [RevPAR PY],
        [RevPAR PY],
        0
    )
```

### ADR YoY %

```dax
ADR YoY % =
    DIVIDE(
        [ADR] - [ADR PY],
        [ADR PY],
        0
    )
```

### Occupancy YoY Change (pp)

```dax
Occupancy YoY pp =
    [Occupancy %] - [Occupancy PY]
```

Percentage-point change in occupancy year over year.

### Revenue YoY %

```dax
Revenue YoY % =
    DIVIDE(
        [Room Revenue Excl VAT] - [Room Revenue PY],
        [Room Revenue PY],
        0
    )
```

### Direct Share YoY Change (pp)

```dax
Direct Share YoY pp =
    [Direct Share %]
    - CALCULATE(
        [Direct Share %],
        SAMEPERIODLASTYEAR( dim_date[full_date] )
    )
```

Tracks the annual shift in direct channel share. Negative values signal growing OTA dependency.

### OTA Share YoY Change (pp)

```dax
OTA Share YoY pp =
    [OTA Share %]
    - CALCULATE(
        [OTA Share %],
        SAMEPERIODLASTYEAR( dim_date[full_date] )
    )
```

### RGI YoY Change

```dax
RGI YoY =
    [RGI]
    - CALCULATE(
        [RGI],
        SAMEPERIODLASTYEAR( dim_date[full_date] )
    )
```

---

## 6. Case-Specific Metrics

### Loyalty Displacement Cost

```dax
Loyalty Displacement Cost =
    VAR LoyaltyRooms =
        CALCULATE(
            SUM( fact_daily_rooms[rooms_sold] ),
            dim_segment[is_redemption] = TRUE
        )
    VAR MarketADR = [ADR]
    VAR Reimbursement =
        CALCULATE(
            SUM( fact_daily_rooms[reimbursement_received] ),
            dim_segment[is_redemption] = TRUE
        )
    RETURN
        ( LoyaltyRooms * MarketADR ) - Reimbursement
```

Revenue forgone due to the no-blackout-date loyalty redemption policy. Loyalty Club ADR is EUR 95 vs. market ADR of EUR 168.

### Total Stillwood Fee Load

```dax
Total Stillwood Fees =
    SUM( fact_pnl_monthly[marketing_contribution] )
    + SUM( fact_pnl_monthly[distribution_fee] )
    + SUM( fact_pnl_monthly[crs_fee] )
    + SUM( fact_pnl_monthly[loyalty_club_fee_earn] )
    + SUM( fact_pnl_monthly[trademark_royalty] )
    + SUM( fact_pnl_monthly[base_management_fee] )
    + SUM( fact_pnl_monthly[incentive_fee] )
```

### Stillwood Fee % of Room Revenue

```dax
Stillwood Fee % Room Rev =
    DIVIDE(
        [Total Stillwood Fees],
        SUM( fact_pnl_monthly[room_revenue] ),
        0
    )
```

### Room GOI Margin

```dax
Room GOI Margin =
    DIVIDE(
        SUM( fact_pnl_monthly[room_goi] ),
        SUM( fact_pnl_monthly[room_revenue] ),
        0
    )
```

Declining from 65% to 63.7% (2011-2015). Signals rising room department costs.

### Owner Return Ratio

```dax
Owner Return Ratio =
    DIVIDE(
        SUM( fact_pnl_monthly[ebitdar] ),
        [Total Revenue],
        0
    )
```

EBITDAR / Total Revenue. Declining from 32.7% to 29.8% (2011-2015).

### Cost Per Occupied Room (CPOR)

```dax
CPOR =
    DIVIDE(
        SUM( fact_pnl_monthly[room_payroll] )
        + SUM( fact_pnl_monthly[room_expenses] ),
        [Rooms Sold],
        0
    )
```

### F&B Capture Rate

```dax
F&B Capture Rate =
    DIVIDE(
        SUM( fact_pnl_monthly[fb_revenue] ),
        SUM( fact_pnl_monthly[room_revenue] ),
        0
    )
```

Growing from 12% to 16%. Indicates ancillary revenue opportunity.

### Break-Even Occupancy

```dax
Break-Even Occupancy =
    VAR FixedCosts =
        SUM( fact_pnl_monthly[unallocated_payroll] )
        + SUM( fact_pnl_monthly[admin_expenses] )
        + SUM( fact_pnl_monthly[maintenance_expenses] )
        + SUM( fact_pnl_monthly[energy_expenses] )
    VAR ContributionPerRoom = [Net ADR] - [CPOR]
    RETURN
        DIVIDE( FixedCosts, ContributionPerRoom * 300 * 365, 0 )
```

Minimum occupancy needed to cover fixed costs at current rate and cost structure.
