--#region: cust count yearly and monthly
with
    PAYMENTS_MONTH_TYPE as (
        select
            CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
            CARDUP_PAYMENT_PAYMENT_TYPE PAYMENT_TYPE,
            DATE_TRUNC(MONTH, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) MONTH_PAYMENT,
            SUM(CARDUP_PAYMENT_USD_AMT) TOTAL_GTV,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) TOTAL_REVENUE,
            SUM(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) TOTAL_NET_REVENUE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) TOTAL_TX_COUNT
        from
            ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
        WHERE
            CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
            AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
            and CARDUP_PAYMENT_CU_LOCALE_ID = 1
            --and DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) >= DATE('2021-01-01')
            and DATE_TRUNC(YEAR, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) = DATE('2024-01-01')
        group by
            1,
            2,
            3
    ),
    INDUSTRY_CATEGORY as (
        select
            T1.CU_COMPANY_ID COMPANY_ID,
            T3.L1_INDUSTRY CU_COMPANY_L1_INDUSTRY,
            T3.L2_INDUSTRY CU_COMPANY_L2_INDUSTRY,
            T3.L3_INDUSTRY CU_COMPANY_L3_INDUSTRY
        from
            CDM.COUNTERPARTY.CARDUP_COMPANY_T T1
            JOIN DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on T1.CU_COMPANY_UEN = T2.UEN --sbox table to be replaced
            JOIN DEV.SBOX_SHILTON.CU_B2B_INDUSTRY_MATCHING T3 on T3.L3_INDUSTRY = T2.PRIMARY_SSIC_DESCRIPTION --temp table uploaded with csv
        where
            T1.COMPANY_CU_LOCALE_ID = 1
    ),
    PAYMENTS_MONTH_TYPE_INDUSTRY as (
        select
            CU_COMPANY_L1_INDUSTRY,
            CU_COMPANY_L2_INDUSTRY,
            CU_COMPANY_L3_INDUSTRY,
            MONTH_PAYMENT,
            --PAYMENT_TYPE,
            T1.COMPANY_ID,
            SUM(TOTAL_GTV) TOTAL_GTV,
            SUM(TOTAL_REVENUE) TOTAL_REVENUE,
            SUM(TOTAL_NET_REVENUE) TOTAL_NET_REVENUE,
            SUM(TOTAL_TX_COUNT) TOTAL_TX_COUNT,
            COUNT(distinct T1.COMPANY_ID) TOTAL_COMPANY_COUNT
        from
            PAYMENTS_MONTH_TYPE T1
            join INDUSTRY_CATEGORY T2 on T1.COMPANY_ID = T2.COMPANY_ID
        group by
            1,
            2,
            3,
            4,
            5
            --,6
    )
select
    CU_COMPANY_L1_INDUSTRY,
    -- CU_COMPANY_L2_INDUSTRY,
    -- CU_COMPANY_L3_INDUSTRY,
    MONTH_PAYMENT,
    COUNT(distinct COMPANY_ID) TOTAL_COMPANY_COUNT,
from
    PAYMENTS_MONTH_TYPE_INDUSTRY
group by
    1,
    ROLLUP (2);

--#endregion
--#region: tx count monthly
with
    PAYMENTS_MONTH_TYPE as (
        select
            CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
            CARDUP_PAYMENT_PAYMENT_TYPE PAYMENT_TYPE,
            DATE_TRUNC(MONTH, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) MONTH_PAYMENT,
            SUM(CARDUP_PAYMENT_USD_AMT) TOTAL_GTV,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) TOTAL_REVENUE,
            SUM(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) TOTAL_NET_REVENUE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) TOTAL_TX_COUNT
        from
            ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
        WHERE
            CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
            AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
            and CARDUP_PAYMENT_CU_LOCALE_ID = 1
            --and DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) >= DATE('2021-01-01')
            and DATE_TRUNC(YEAR, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) = DATE('2024-01-01')
        group by
            1,
            2,
            3
    ),
    INDUSTRY_CATEGORY as (
        select
            T1.CU_COMPANY_ID COMPANY_ID,
            T3.L1_INDUSTRY CU_COMPANY_L1_INDUSTRY,
            T3.L2_INDUSTRY CU_COMPANY_L2_INDUSTRY,
            T3.L3_INDUSTRY CU_COMPANY_L3_INDUSTRY
        from
            CDM.COUNTERPARTY.CARDUP_COMPANY_T T1
            JOIN DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on T1.CU_COMPANY_UEN = T2.UEN --sbox table to be replaced
            JOIN DEV.SBOX_SHILTON.CU_B2B_INDUSTRY_MATCHING T3 on T3.L3_INDUSTRY = T2.PRIMARY_SSIC_DESCRIPTION --temp table uploaded with csv
        where
            T1.COMPANY_CU_LOCALE_ID = 1
    ),
    PAYMENTS_MONTH_TYPE_INDUSTRY as (
        select
            CU_COMPANY_L1_INDUSTRY,
            CU_COMPANY_L2_INDUSTRY,
            CU_COMPANY_L3_INDUSTRY,
            MONTH_PAYMENT,
            --PAYMENT_TYPE,
            T1.COMPANY_ID,
            SUM(TOTAL_GTV) TOTAL_GTV,
            SUM(TOTAL_REVENUE) TOTAL_REVENUE,
            SUM(TOTAL_NET_REVENUE) TOTAL_NET_REVENUE,
            SUM(TOTAL_TX_COUNT) TOTAL_TX_COUNT,
            COUNT(distinct T1.COMPANY_ID) TOTAL_COMPANY_COUNT
        from
            PAYMENTS_MONTH_TYPE T1
            join INDUSTRY_CATEGORY T2 on T1.COMPANY_ID = T2.COMPANY_ID
        group by
            1,
            2,
            3,
            4,
            5
            --,6
    )
select
    CU_COMPANY_L1_INDUSTRY,
    -- CU_COMPANY_L2_INDUSTRY,
    -- CU_COMPANY_L3_INDUSTRY,
    MONTH_PAYMENT,
    APPROX_PERCENTILE(TOTAL_TX_COUNT, 0.5) MEDIAN_TX_COUNT,
from
    PAYMENTS_MONTH_TYPE_INDUSTRY
group by
    1,
    ROLLUP (2);

--#endregion
--#region: tx count yearly
with
    PAYMENTS_MONTH_TYPE as (
        select
            CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
            CARDUP_PAYMENT_PAYMENT_TYPE PAYMENT_TYPE,
            DATE_TRUNC(YEAR, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) YEAR_PAYMENT,
            SUM(CARDUP_PAYMENT_USD_AMT) TOTAL_GTV,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) TOTAL_REVENUE,
            SUM(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) TOTAL_NET_REVENUE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) TOTAL_TX_COUNT
        from
            ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
        WHERE
            CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
            AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
            and CARDUP_PAYMENT_CU_LOCALE_ID = 1
            --and DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) >= DATE('2021-01-01')
            and DATE_TRUNC(YEAR, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) = DATE('2024-01-01')
        group by
            1,
            2,
            3
    ),
    INDUSTRY_CATEGORY as (
        select
            T1.CU_COMPANY_ID COMPANY_ID,
            T3.L1_INDUSTRY CU_COMPANY_L1_INDUSTRY,
            T3.L2_INDUSTRY CU_COMPANY_L2_INDUSTRY,
            T3.L3_INDUSTRY CU_COMPANY_L3_INDUSTRY
        from
            CDM.COUNTERPARTY.CARDUP_COMPANY_T T1
            JOIN DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on T1.CU_COMPANY_UEN = T2.UEN --sbox table to be replaced
            JOIN DEV.SBOX_SHILTON.CU_B2B_INDUSTRY_MATCHING T3 on T3.L3_INDUSTRY = T2.PRIMARY_SSIC_DESCRIPTION --temp table uploaded with csv
        where
            T1.COMPANY_CU_LOCALE_ID = 1
    ),
    PAYMENTS_MONTH_TYPE_INDUSTRY as (
        select
            CU_COMPANY_L1_INDUSTRY,
            CU_COMPANY_L2_INDUSTRY,
            CU_COMPANY_L3_INDUSTRY,
            YEAR_PAYMENT,
            --PAYMENT_TYPE,
            T1.COMPANY_ID,
            SUM(TOTAL_GTV) TOTAL_GTV,
            SUM(TOTAL_REVENUE) TOTAL_REVENUE,
            SUM(TOTAL_NET_REVENUE) TOTAL_NET_REVENUE,
            SUM(TOTAL_TX_COUNT) TOTAL_TX_COUNT,
            COUNT(distinct T1.COMPANY_ID) TOTAL_COMPANY_COUNT
        from
            PAYMENTS_MONTH_TYPE T1
            join INDUSTRY_CATEGORY T2 on T1.COMPANY_ID = T2.COMPANY_ID
        group by
            1,
            2,
            3,
            4,
            5
            --,6
    )
select
    CU_COMPANY_L1_INDUSTRY,
    -- CU_COMPANY_L2_INDUSTRY,
    -- CU_COMPANY_L3_INDUSTRY,
    YEAR_PAYMENT,
    APPROX_PERCENTILE(TOTAL_TX_COUNT, 0.5) MEDIAN_TX_COUNT,
from
    PAYMENTS_MONTH_TYPE_INDUSTRY
group by
    1,
    2;

--#endregion

--#region: GTV
with
    PAYMENTS_MONTH_TYPE as (
        select
            CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
            CARDUP_PAYMENT_PAYMENT_TYPE PAYMENT_TYPE,
            DATE_TRUNC(MONTH, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) MONTH_PAYMENT,
            SUM(CARDUP_PAYMENT_USD_AMT) TOTAL_GTV,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) TOTAL_REVENUE,
            SUM(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) TOTAL_NET_REVENUE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) TOTAL_TX_COUNT
        from
            ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
        WHERE
            CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
            AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
            and CARDUP_PAYMENT_CU_LOCALE_ID = 1
            --and DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) >= DATE('2021-01-01')
            and DATE_TRUNC(YEAR, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) = DATE('2024-01-01')
        group by
            1,
            2,
            3
    ),
    INDUSTRY_CATEGORY as (
        select
            T1.CU_COMPANY_ID COMPANY_ID,
            T3.L1_INDUSTRY CU_COMPANY_L1_INDUSTRY,
            T3.L2_INDUSTRY CU_COMPANY_L2_INDUSTRY,
            T3.L3_INDUSTRY CU_COMPANY_L3_INDUSTRY
        from
            CDM.COUNTERPARTY.CARDUP_COMPANY_T T1
            JOIN DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on T1.CU_COMPANY_UEN = T2.UEN --sbox table to be replaced
            JOIN DEV.SBOX_SHILTON.CU_B2B_INDUSTRY_MATCHING T3 on T3.L3_INDUSTRY = T2.PRIMARY_SSIC_DESCRIPTION --temp table uploaded with csv
        where
            T1.COMPANY_CU_LOCALE_ID = 1
    ),
    PAYMENTS_MONTH_TYPE_INDUSTRY as (
        select
            CU_COMPANY_L1_INDUSTRY,
            CU_COMPANY_L2_INDUSTRY,
            CU_COMPANY_L3_INDUSTRY,
            --MONTH_PAYMENT,
            --PAYMENT_TYPE,
            T1.COMPANY_ID,
            SUM(TOTAL_GTV) TOTAL_GTV,
            SUM(TOTAL_REVENUE) TOTAL_REVENUE,
            SUM(TOTAL_NET_REVENUE) TOTAL_NET_REVENUE,
            SUM(TOTAL_TX_COUNT) TOTAL_TX_COUNT,
            COUNT(distinct T1.COMPANY_ID) TOTAL_COMPANY_COUNT
        from
            PAYMENTS_MONTH_TYPE T1
            join INDUSTRY_CATEGORY T2 on T1.COMPANY_ID = T2.COMPANY_ID
        group by
            1,
            2,
            3,
            4
            --,5
            --,6
    )
select
    CU_COMPANY_L1_INDUSTRY,
    -- CU_COMPANY_L2_INDUSTRY,
    -- CU_COMPANY_L3_INDUSTRY,
    SUM(TOTAL_GTV) TOTAL_GTV,
    APPROX_PERCENTILE(TOTAL_GTV, 0.5) MEDIAN_GTV,
from
    PAYMENTS_MONTH_TYPE_INDUSTRY
group by
    1
    --,2
    --,3
;

--#endregion
--#region: Rev
with
    PAYMENTS_MONTH_TYPE as (
        select
            CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
            CARDUP_PAYMENT_PAYMENT_TYPE PAYMENT_TYPE,
            DATE_TRUNC(MONTH, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) MONTH_PAYMENT,
            SUM(CARDUP_PAYMENT_USD_AMT) TOTAL_GTV,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) TOTAL_REVENUE,
            SUM(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) TOTAL_NET_REVENUE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) TOTAL_TX_COUNT
        from
            ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
        WHERE
            CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
            AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
            and CARDUP_PAYMENT_CU_LOCALE_ID = 1
            --and DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) >= DATE('2021-01-01')
            and DATE_TRUNC(YEAR, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) = DATE('2024-01-01')
        group by
            1,
            2,
            3
    ),
    INDUSTRY_CATEGORY as (
        select
            T1.CU_COMPANY_ID COMPANY_ID,
            T3.L1_INDUSTRY CU_COMPANY_L1_INDUSTRY,
            T3.L2_INDUSTRY CU_COMPANY_L2_INDUSTRY,
            T3.L3_INDUSTRY CU_COMPANY_L3_INDUSTRY
        from
            CDM.COUNTERPARTY.CARDUP_COMPANY_T T1
            JOIN DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on T1.CU_COMPANY_UEN = T2.UEN --sbox table to be replaced
            JOIN DEV.SBOX_SHILTON.CU_B2B_INDUSTRY_MATCHING T3 on T3.L3_INDUSTRY = T2.PRIMARY_SSIC_DESCRIPTION --temp table uploaded with csv
        where
            T1.COMPANY_CU_LOCALE_ID = 1
    ),
    PAYMENTS_MONTH_TYPE_INDUSTRY as (
        select
            CU_COMPANY_L1_INDUSTRY,
            CU_COMPANY_L2_INDUSTRY,
            CU_COMPANY_L3_INDUSTRY,
            --MONTH_PAYMENT,
            --PAYMENT_TYPE,
            T1.COMPANY_ID,
            SUM(TOTAL_GTV) TOTAL_GTV,
            SUM(TOTAL_REVENUE) TOTAL_REVENUE,
            SUM(TOTAL_NET_REVENUE) TOTAL_NET_REVENUE,
            SUM(TOTAL_TX_COUNT) TOTAL_TX_COUNT,
            COUNT(distinct T1.COMPANY_ID) TOTAL_COMPANY_COUNT
        from
            PAYMENTS_MONTH_TYPE T1
            join INDUSTRY_CATEGORY T2 on T1.COMPANY_ID = T2.COMPANY_ID
        group by
            1,
            2,
            3,
            4
            --,5
            --,6
    )
select
    CU_COMPANY_L1_INDUSTRY,
    -- CU_COMPANY_L2_INDUSTRY,
    -- CU_COMPANY_L3_INDUSTRY,
    SUM(TOTAL_REVENUE) TOTAL_REVENUE,
    APPROX_PERCENTILE(TOTAL_REVENUE, 0.5) MEDIAN_REVENUE,
from
    PAYMENTS_MONTH_TYPE_INDUSTRY
group by
    1
    --,2
    --,3
;

--#endregion
--#region: NetRev
with
    PAYMENTS_MONTH_TYPE as (
        select
            CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
            CARDUP_PAYMENT_PAYMENT_TYPE PAYMENT_TYPE,
            DATE_TRUNC(MONTH, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) MONTH_PAYMENT,
            SUM(CARDUP_PAYMENT_USD_AMT) TOTAL_GTV,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) TOTAL_REVENUE,
            SUM(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) TOTAL_NET_REVENUE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) TOTAL_TX_COUNT
        from
            ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
        WHERE
            CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
            AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
            and CARDUP_PAYMENT_CU_LOCALE_ID = 1
            --and DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) >= DATE('2021-01-01')
            and DATE_TRUNC(YEAR, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) = DATE('2024-01-01')
        group by
            1,
            2,
            3
    ),
    INDUSTRY_CATEGORY as (
        select
            T1.CU_COMPANY_ID COMPANY_ID,
            T3.L1_INDUSTRY CU_COMPANY_L1_INDUSTRY,
            T3.L2_INDUSTRY CU_COMPANY_L2_INDUSTRY,
            T3.L3_INDUSTRY CU_COMPANY_L3_INDUSTRY
        from
            CDM.COUNTERPARTY.CARDUP_COMPANY_T T1
            JOIN DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on T1.CU_COMPANY_UEN = T2.UEN --sbox table to be replaced
            JOIN DEV.SBOX_SHILTON.CU_B2B_INDUSTRY_MATCHING T3 on T3.L3_INDUSTRY = T2.PRIMARY_SSIC_DESCRIPTION --temp table uploaded with csv
        where
            T1.COMPANY_CU_LOCALE_ID = 1
    ),
    PAYMENTS_MONTH_TYPE_INDUSTRY as (
        select
            CU_COMPANY_L1_INDUSTRY,
            CU_COMPANY_L2_INDUSTRY,
            CU_COMPANY_L3_INDUSTRY,
            --MONTH_PAYMENT,
            --PAYMENT_TYPE,
            T1.COMPANY_ID,
            SUM(TOTAL_GTV) TOTAL_GTV,
            SUM(TOTAL_REVENUE) TOTAL_REVENUE,
            SUM(TOTAL_NET_REVENUE) TOTAL_NET_REVENUE,
            SUM(TOTAL_TX_COUNT) TOTAL_TX_COUNT,
            COUNT(distinct T1.COMPANY_ID) TOTAL_COMPANY_COUNT
        from
            PAYMENTS_MONTH_TYPE T1
            join INDUSTRY_CATEGORY T2 on T1.COMPANY_ID = T2.COMPANY_ID
        group by
            1,
            2,
            3,
            4
            --,5
            --,6
    )
select
    CU_COMPANY_L1_INDUSTRY,
    -- CU_COMPANY_L2_INDUSTRY,
    -- CU_COMPANY_L3_INDUSTRY,
    SUM(TOTAL_NET_REVENUE) TOTAL_NET_REVENUE,
    APPROX_PERCENTILE(TOTAL_NET_REVENUE, 0.5) MEDIAN_NET_REVENUE,
from
    PAYMENTS_MONTH_TYPE_INDUSTRY
group by
    1
    --,2
    --,3
;

--#endregion
--#region: paytype count yearly only
with
    PAYMENTS_MONTH_TYPE as (
        select
            CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
            CARDUP_PAYMENT_PAYMENT_TYPE PAYMENT_TYPE,
            DATE_TRUNC(MONTH, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) MONTH_PAYMENT,
            SUM(CARDUP_PAYMENT_USD_AMT) TOTAL_GTV,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) TOTAL_REVENUE,
            SUM(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) TOTAL_NET_REVENUE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) TOTAL_TX_COUNT
        from
            ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
        WHERE
            CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
            AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
            and CARDUP_PAYMENT_CU_LOCALE_ID = 1
            --and DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) >= DATE('2021-01-01')
            and DATE_TRUNC(YEAR, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) = DATE('2024-01-01')
        group by
            1,
            2,
            3
    ),
    INDUSTRY_CATEGORY as (
        select
            T1.CU_COMPANY_ID COMPANY_ID,
            T3.L1_INDUSTRY CU_COMPANY_L1_INDUSTRY,
            T3.L2_INDUSTRY CU_COMPANY_L2_INDUSTRY,
            T3.L3_INDUSTRY CU_COMPANY_L3_INDUSTRY
        from
            CDM.COUNTERPARTY.CARDUP_COMPANY_T T1
            JOIN DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on T1.CU_COMPANY_UEN = T2.UEN --sbox table to be replaced
            JOIN DEV.SBOX_SHILTON.CU_B2B_INDUSTRY_MATCHING T3 on T3.L3_INDUSTRY = T2.PRIMARY_SSIC_DESCRIPTION --temp table uploaded with csv
        where
            T1.COMPANY_CU_LOCALE_ID = 1
    ),
    PAYMENTS_MONTH_TYPE_INDUSTRY as (
        select
            CU_COMPANY_L1_INDUSTRY,
            CU_COMPANY_L2_INDUSTRY,
            CU_COMPANY_L3_INDUSTRY,
            MONTH_PAYMENT,
            PAYMENT_TYPE,
            T1.COMPANY_ID,
            SUM(TOTAL_GTV) TOTAL_GTV,
            SUM(TOTAL_REVENUE) TOTAL_REVENUE,
            SUM(TOTAL_NET_REVENUE) TOTAL_NET_REVENUE,
            SUM(TOTAL_TX_COUNT) TOTAL_TX_COUNT,
            COUNT(distinct T1.COMPANY_ID) TOTAL_COMPANY_COUNT
        from
            PAYMENTS_MONTH_TYPE T1
            join INDUSTRY_CATEGORY T2 on T1.COMPANY_ID = T2.COMPANY_ID
        group by
            1,
            2,
            3,
            4,
            5,
            6
    ),
    PAYMENTS_MONTH_TYPE_INDUSTRY_AGG as (
        select
            CU_COMPANY_L1_INDUSTRY,
            COMPANY_ID,
            -- CU_COMPANY_L2_INDUSTRY,
            -- CU_COMPANY_L3_INDUSTRY,
            -- MONTH_PAYMENT,
            COUNT(distinct PAYMENT_TYPE) TOTAL_PAYTYPE_COUNT,
        from
            PAYMENTS_MONTH_TYPE_INDUSTRY
        group by
            1,
            2
            --,3
    )
select
    CU_COMPANY_L1_INDUSTRY,
    APPROX_PERCENTILE(TOTAL_PAYTYPE_COUNT, 0.5) MEDIAN_PAYTYPE_COUNT,
    AVG(TOTAL_PAYTYPE_COUNT) AVG_PAYTYPE_COUNT
from
    PAYMENTS_MONTH_TYPE_INDUSTRY_AGG
group by
    1;

--#endregion
--#region: Growth
with
    PAYMENTS_MONTH_TYPE as (
        select
            CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
            CARDUP_PAYMENT_PAYMENT_TYPE PAYMENT_TYPE,
            DATE_TRUNC(YEAR, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) YEAR_PAYMENT,
            SUM(CARDUP_PAYMENT_USD_AMT) TOTAL_GTV,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) TOTAL_REVENUE,
            SUM(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) TOTAL_NET_REVENUE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) TOTAL_TX_COUNT
        from
            ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
        WHERE
            CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
            AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
            and CARDUP_PAYMENT_CU_LOCALE_ID = 1
            --and DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) >= DATE('2021-01-01')
            and DATE_TRUNC(YEAR, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) in (DATE('2023-01-01'), DATE('2024-01-01'))
        group by
            1,
            2,
            3
    ),
    INDUSTRY_CATEGORY as (
        select
            T1.CU_COMPANY_ID COMPANY_ID,
            T3.L1_INDUSTRY CU_COMPANY_L1_INDUSTRY,
            T3.L2_INDUSTRY CU_COMPANY_L2_INDUSTRY,
            T3.L3_INDUSTRY CU_COMPANY_L3_INDUSTRY
        from
            CDM.COUNTERPARTY.CARDUP_COMPANY_T T1
            JOIN DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on T1.CU_COMPANY_UEN = T2.UEN --sbox table to be replaced
            JOIN DEV.SBOX_SHILTON.CU_B2B_INDUSTRY_MATCHING T3 on T3.L3_INDUSTRY = T2.PRIMARY_SSIC_DESCRIPTION --temp table uploaded with csv
        where
            T1.COMPANY_CU_LOCALE_ID = 1
    ),
    PAYMENTS_MONTH_TYPE_INDUSTRY as (
        select
            CU_COMPANY_L1_INDUSTRY,
            CU_COMPANY_L2_INDUSTRY,
            CU_COMPANY_L3_INDUSTRY,
            YEAR_PAYMENT,
            --PAYMENT_TYPE,
            T1.COMPANY_ID,
            SUM(TOTAL_GTV) TOTAL_GTV,
            SUM(TOTAL_REVENUE) TOTAL_REVENUE,
            SUM(TOTAL_NET_REVENUE) TOTAL_NET_REVENUE,
            SUM(TOTAL_TX_COUNT) TOTAL_TX_COUNT,
            COUNT(distinct T1.COMPANY_ID) TOTAL_COMPANY_COUNT
        from
            PAYMENTS_MONTH_TYPE T1
            join INDUSTRY_CATEGORY T2 on T1.COMPANY_ID = T2.COMPANY_ID
        group by
            1,
            2,
            3,
            4,
            5
    )
select
    CU_COMPANY_L1_INDUSTRY,
    YEAR_PAYMENT,
    -- CU_COMPANY_L2_INDUSTRY,
    -- CU_COMPANY_L3_INDUSTRY,
    -- MONTH_PAYMENT,
    SUM(TOTAL_GTV) TOTAL_GTV,
    SUM(TOTAL_REVENUE) TOTAL_REVENUE,
    SUM(TOTAL_NET_REVENUE) TOTAL_NET_REVENUE,
    SUM(TOTAL_TX_COUNT) TOTAL_TX_COUNT,
    SUM(TOTAL_COMPANY_COUNT) TOTAL_COMPANY_COUNT,
    APPROX_PERCENTILE(TOTAL_GTV, 0.5) MEDIAN_GTV,
    APPROX_PERCENTILE(TOTAL_REVENUE, 0.5) MEDIAN_REVENUE,
    APPROX_PERCENTILE(TOTAL_NET_REVENUE, 0.5) MEDIAN_NET_REVENUE,
    APPROX_PERCENTILE(TOTAL_TX_COUNT, 0.5) MEDIAN_TX_COUNT,
    APPROX_PERCENTILE(TOTAL_COMPANY_COUNT, 0.5) MEDIAN_COMPANY_COUNT,
from
    PAYMENTS_MONTH_TYPE_INDUSTRY
group by
    1,
    2
    --,3
;

--#endregion

--#region: Growth Monthly
with
    PAYMENTS_MONTH_TYPE as (
        select
            CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
            CARDUP_PAYMENT_PAYMENT_TYPE PAYMENT_TYPE,
            DATE_TRUNC(YEAR, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) YEAR_PAYMENT,
            MONTH(DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) MONTH_PAYMENT,
            SUM(CARDUP_PAYMENT_USD_AMT) TOTAL_GTV,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) TOTAL_REVENUE,
            SUM(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) TOTAL_NET_REVENUE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) TOTAL_TX_COUNT
        from
            ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
        WHERE
            CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
            AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
            and CARDUP_PAYMENT_CU_LOCALE_ID = 1
            --and DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) >= DATE('2021-01-01')
            and DATE_TRUNC(YEAR, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) in (DATE('2023-01-01'), DATE('2024-01-01'))
        group by
            1,
            2,
            3,
            4
    ),
    INDUSTRY_CATEGORY as (
        select
            T1.CU_COMPANY_ID COMPANY_ID,
            T3.L1_INDUSTRY CU_COMPANY_L1_INDUSTRY,
            T3.L2_INDUSTRY CU_COMPANY_L2_INDUSTRY,
            T3.L3_INDUSTRY CU_COMPANY_L3_INDUSTRY
        from
            CDM.COUNTERPARTY.CARDUP_COMPANY_T T1
            JOIN DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on T1.CU_COMPANY_UEN = T2.UEN --sbox table to be replaced
            JOIN DEV.SBOX_SHILTON.CU_B2B_INDUSTRY_MATCHING T3 on T3.L3_INDUSTRY = T2.PRIMARY_SSIC_DESCRIPTION --temp table uploaded with csv
        where
            T1.COMPANY_CU_LOCALE_ID = 1
    ),
    PAYMENTS_MONTH_TYPE_INDUSTRY as (
        select
            CU_COMPANY_L1_INDUSTRY,
            CU_COMPANY_L2_INDUSTRY,
            CU_COMPANY_L3_INDUSTRY,
            YEAR_PAYMENT,
            MONTH_PAYMENT,
            --PAYMENT_TYPE,
            T1.COMPANY_ID,
            SUM(TOTAL_GTV) TOTAL_GTV,
            SUM(TOTAL_REVENUE) TOTAL_REVENUE,
            SUM(TOTAL_NET_REVENUE) TOTAL_NET_REVENUE,
            SUM(TOTAL_TX_COUNT) TOTAL_TX_COUNT,
            COUNT(distinct T1.COMPANY_ID) TOTAL_COMPANY_COUNT
        from
            PAYMENTS_MONTH_TYPE T1
            join INDUSTRY_CATEGORY T2 on T1.COMPANY_ID = T2.COMPANY_ID
        group by
            1,
            2,
            3,
            4,
            5,
            6
    )
select
    CU_COMPANY_L1_INDUSTRY,
    YEAR_PAYMENT,
    -- CU_COMPANY_L2_INDUSTRY,
    -- CU_COMPANY_L3_INDUSTRY,
    MONTH_PAYMENT,
    SUM(TOTAL_GTV) TOTAL_GTV,
    SUM(TOTAL_REVENUE) TOTAL_REVENUE,
    SUM(TOTAL_NET_REVENUE) TOTAL_NET_REVENUE,
    SUM(TOTAL_TX_COUNT) TOTAL_TX_COUNT,
    SUM(TOTAL_COMPANY_COUNT) TOTAL_COMPANY_COUNT,
    APPROX_PERCENTILE(TOTAL_GTV, 0.5) MEDIAN_GTV,
    APPROX_PERCENTILE(TOTAL_REVENUE, 0.5) MEDIAN_REVENUE,
    APPROX_PERCENTILE(TOTAL_NET_REVENUE, 0.5) MEDIAN_NET_REVENUE,
    APPROX_PERCENTILE(TOTAL_TX_COUNT, 0.5) MEDIAN_TX_COUNT,
    APPROX_PERCENTILE(TOTAL_COMPANY_COUNT, 0.5) MEDIAN_COMPANY_COUNT,
from
    PAYMENTS_MONTH_TYPE_INDUSTRY
group by
    1,
    2
    ,3
;

--#endregion



--#region: GTV seasonality
with
    PAYMENTS_MONTH_TYPE as (
        select
            CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
            CARDUP_PAYMENT_PAYMENT_TYPE PAYMENT_TYPE,
            --DATE_TRUNC(MONTH, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) MONTH_PAYMENT,
            MONTH(DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) MONTH_PAYMENT,
            SUM(CARDUP_PAYMENT_USD_AMT) TOTAL_GTV,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) TOTAL_REVENUE,
            SUM(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) TOTAL_NET_REVENUE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) TOTAL_TX_COUNT
        from
            ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
        WHERE
            CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
            AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
            and CARDUP_PAYMENT_CU_LOCALE_ID = 1
            and DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) >= DATE('2021-01-01')
            --and DATE_TRUNC(YEAR, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) = DATE('2021-01-01')
        group by
            1,
            2,
            3
    ),
    INDUSTRY_CATEGORY as (
        select
            T1.CU_COMPANY_ID COMPANY_ID,
            T3.L1_INDUSTRY CU_COMPANY_L1_INDUSTRY,
            T3.L2_INDUSTRY CU_COMPANY_L2_INDUSTRY,
            T3.L3_INDUSTRY CU_COMPANY_L3_INDUSTRY
        from
            CDM.COUNTERPARTY.CARDUP_COMPANY_T T1
            JOIN DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on T1.CU_COMPANY_UEN = T2.UEN --sbox table to be replaced
            JOIN DEV.SBOX_SHILTON.CU_B2B_INDUSTRY_MATCHING T3 on T3.L3_INDUSTRY = T2.PRIMARY_SSIC_DESCRIPTION --temp table uploaded with csv
        where
            T1.COMPANY_CU_LOCALE_ID = 1
    ),
    PAYMENTS_MONTH_TYPE_INDUSTRY as (
        select
            CU_COMPANY_L1_INDUSTRY,
            CU_COMPANY_L2_INDUSTRY,
            CU_COMPANY_L3_INDUSTRY,
            MONTH_PAYMENT,
            --PAYMENT_TYPE,
            T1.COMPANY_ID,
            SUM(TOTAL_GTV) TOTAL_GTV,
            SUM(TOTAL_REVENUE) TOTAL_REVENUE,
            SUM(TOTAL_NET_REVENUE) TOTAL_NET_REVENUE,
            SUM(TOTAL_TX_COUNT) TOTAL_TX_COUNT,
            COUNT(distinct T1.COMPANY_ID) TOTAL_COMPANY_COUNT
        from
            PAYMENTS_MONTH_TYPE T1
            join INDUSTRY_CATEGORY T2 on T1.COMPANY_ID = T2.COMPANY_ID
        group by
            1,
            2,
            3,
            4
            ,5
            --,6
    )
select CU_COMPANY_L1_INDUSTRY, avg(TOTAL_GTV), stddev(TOTAL_GTV) from 
(
select
    CU_COMPANY_L1_INDUSTRY,
    -- CU_COMPANY_L2_INDUSTRY,
    -- CU_COMPANY_L3_INDUSTRY,
    MONTH_PAYMENT,
    SUM(TOTAL_GTV) TOTAL_GTV,
    APPROX_PERCENTILE(TOTAL_GTV, 0.5) MEDIAN_GTV,
from
    PAYMENTS_MONTH_TYPE_INDUSTRY
group by
    1
    ,2
    --,3
)
group by 1;

--#endregion

--#region: GTV concentration
with
    PAYMENTS_MONTH_TYPE as (
        select
            CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
            CARDUP_PAYMENT_PAYMENT_TYPE PAYMENT_TYPE,
            --DATE_TRUNC(MONTH, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) MONTH_PAYMENT,
            MONTH(DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) MONTH_PAYMENT,
            SUM(CARDUP_PAYMENT_USD_AMT) TOTAL_GTV,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) TOTAL_REVENUE,
            SUM(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) TOTAL_NET_REVENUE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) TOTAL_TX_COUNT
        from
            ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
        WHERE
            CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
            AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
            and CARDUP_PAYMENT_CU_LOCALE_ID = 1
            --and DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) >= DATE('2021-01-01')
            and DATE_TRUNC(YEAR, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) = DATE('2024-01-01')
        group by
            1,
            2,
            3
    ),
    INDUSTRY_CATEGORY as (
        select
            T1.CU_COMPANY_ID COMPANY_ID,
            T3.L1_INDUSTRY CU_COMPANY_L1_INDUSTRY,
            T3.L2_INDUSTRY CU_COMPANY_L2_INDUSTRY,
            T3.L3_INDUSTRY CU_COMPANY_L3_INDUSTRY
        from
            CDM.COUNTERPARTY.CARDUP_COMPANY_T T1
            JOIN DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on T1.CU_COMPANY_UEN = T2.UEN --sbox table to be replaced
            JOIN CBM.GSHEET.CU_B2B_INDUSTRY_MATCHING T3 on T3.L3_INDUSTRY = T2.PRIMARY_SSIC_DESCRIPTION --temp table uploaded with csv
        where
            T1.COMPANY_CU_LOCALE_ID = 1
    ),
    PAYMENTS_MONTH_TYPE_INDUSTRY as (
        select
            CU_COMPANY_L1_INDUSTRY,
            CU_COMPANY_L2_INDUSTRY,
            CU_COMPANY_L3_INDUSTRY,
            --MONTH_PAYMENT,
            --PAYMENT_TYPE,
            T1.COMPANY_ID,
            SUM(TOTAL_GTV) TOTAL_GTV,
            SUM(TOTAL_REVENUE) TOTAL_REVENUE,
            SUM(TOTAL_NET_REVENUE) TOTAL_NET_REVENUE,
            SUM(TOTAL_TX_COUNT) TOTAL_TX_COUNT,
            COUNT(distinct T1.COMPANY_ID) TOTAL_COMPANY_COUNT
        from
            PAYMENTS_MONTH_TYPE T1
            join INDUSTRY_CATEGORY T2 on T1.COMPANY_ID = T2.COMPANY_ID
        group by
            1,
            2,
            3,
            4
            --,5
            --,6
    ),
    TOP_X_COMPANIES as (
        select 
            CU_COMPANY_L1_INDUSTRY,
            COMPANY_ID,
            TOTAL_GTV,
            row_number() over (partition by CU_COMPANY_L1_INDUSTRY order by TOTAL_GTV desc) as rank
        from 
            PAYMENTS_MONTH_TYPE_INDUSTRY
    ),
    TOP_X_GTV as (
        select 
            CU_COMPANY_L1_INDUSTRY, 
            sum(case when rank <= 3 then TOTAL_GTV else 0 end) as top_x_gtv, 
            sum(TOTAL_GTV) as total_gtv 
        from 
            TOP_X_COMPANIES
        group by 
            CU_COMPANY_L1_INDUSTRY
    )
select 
    CU_COMPANY_L1_INDUSTRY, 
    top_x_gtv, 
    total_gtv, 
    (top_x_gtv / total_gtv) * 100 as top_x_gtv_percentage 
from 
    TOP_X_GTV;

--#endregion