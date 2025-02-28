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
            and CARDUP_PAYMENT_PRODUCT_NAME LIKE '%B2B MAKE%'
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
            and CARDUP_PAYMENT_PRODUCT_NAME LIKE '%B2B MAKE%'
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
            and CARDUP_PAYMENT_PRODUCT_NAME LIKE '%B2B MAKE%'
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
            and CARDUP_PAYMENT_PRODUCT_NAME LIKE '%B2B MAKE%'
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
            and CARDUP_PAYMENT_PRODUCT_NAME LIKE '%B2B MAKE%'
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
            and CARDUP_PAYMENT_PRODUCT_NAME LIKE '%B2B MAKE%'
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
            and CARDUP_PAYMENT_PRODUCT_NAME LIKE '%B2B MAKE%'
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
            and CARDUP_PAYMENT_PRODUCT_NAME LIKE '%B2B MAKE%'
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
            and CARDUP_PAYMENT_PRODUCT_NAME LIKE '%B2B MAKE%'
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
    2,
    3;

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
            and CARDUP_PAYMENT_PRODUCT_NAME LIKE '%B2B MAKE%'
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
            4,
            5
            --,6
    )
select
    CU_COMPANY_L1_INDUSTRY,
    AVG(TOTAL_GTV),
    STDDEV(TOTAL_GTV)
from
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
            1,
            2
            --,3
    )
group by
    1;

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
            and CARDUP_PAYMENT_PRODUCT_NAME LIKE '%B2B MAKE%'
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
            ROW_NUMBER() OVER (
                partition by
                    CU_COMPANY_L1_INDUSTRY
                order by
                    TOTAL_GTV DESC
            ) as RANK
        from
            PAYMENTS_MONTH_TYPE_INDUSTRY
    ),
    TOP_X_GTV as (
        select
            CU_COMPANY_L1_INDUSTRY,
            SUM(
                case
                    when RANK <= 3 then TOTAL_GTV
                    else 0
                end
            ) as TOP_X_GTV,
            SUM(TOTAL_GTV) as TOTAL_GTV
        from
            TOP_X_COMPANIES
        group by
            CU_COMPANY_L1_INDUSTRY
    )
select
    CU_COMPANY_L1_INDUSTRY,
    TOP_X_GTV,
    TOTAL_GTV,
    (TOP_X_GTV / TOTAL_GTV) * 100 as TOP_X_GTV_PERCENTAGE
from
    TOP_X_GTV;

--#endregion
--#region: GTV concentration - get top 3 companies
with
    PAYMENTS_MONTH_TYPE as (
        select
            CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
            CARDUP_PAYMENT_PAYMENT_TYPE PAYMENT_TYPE,
            --DATE_TRUNC(MONTH, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) MONTH_PAYMENT,
            DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) MONTH_PAYMENT,
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
            and CARDUP_PAYMENT_PRODUCT_NAME LIKE '%B2B MAKE%'
            --and DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) >= DATE('2021-01-01')
            and DATE_TRUNC(YEAR, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) >= DATE('2024-01-01')
        group by
            1,
            2,
            3
    ),
    INDUSTRY_CATEGORY as (
        select
            T1.CU_COMPANY_ID COMPANY_ID,
            T2.UEN,
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
    TOP_PAYTYPE as (
        select
            COMPANY_ID,
            PAYMENT_TYPE,
            SUM(TOTAL_TX_COUNT) as PAYTYPE_TX_COUNT
        from
            PAYMENTS_MONTH_TYPE
        group by
            1,
            2
    ),
    TOP_PAYTYPE_RANK as (
        select
            *,
            RANK() OVER (
                partition by
                    COMPANY_ID
                order by
                    PAYTYPE_TX_COUNT DESC
            ) RANKING
        from
            TOP_PAYTYPE
    ),
    TOP_PAYTYPE_RANK_ONE_ONLY as (
        select
            COMPANY_ID,
            MAX(
                case
                    when RANKING = 1 then PAYMENT_TYPE
                    else null
                end
            ) as PAYMENT_TYPE_RANK_1,
            MAX(
                case
                    when RANKING = 2 then PAYMENT_TYPE
                    else null
                end
            ) as PAYMENT_TYPE_RANK_2,
            MAX(
                case
                    when RANKING = 3 then PAYMENT_TYPE
                    else null
                end
            ) as PAYMENT_TYPE_RANK_3
        from
            TOP_PAYTYPE_RANK
        where
            RANKING < 4
        group by
            1
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
            COUNT(distinct T1.COMPANY_ID) TOTAL_COMPANY_COUNT,
            MAX(MONTH_PAYMENT) LAST_MONTH_PAYMENT
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
            ROW_NUMBER() OVER (
                partition by
                    CU_COMPANY_L1_INDUSTRY
                order by
                    TOTAL_GTV DESC
            ) as RANK,
            SUM(TOTAL_GTV) OVER (
                partition by
                    CU_COMPANY_L1_INDUSTRY
            ) as TOTAL_GTV_INDUSTRY
        from
            PAYMENTS_MONTH_TYPE_INDUSTRY
    )
select
    T1.RANK,
    T1.CU_COMPANY_L1_INDUSTRY,
    T1.TOTAL_GTV_INDUSTRY,
    T3.ENTITY_NAME,
    T5.PAYMENT_TYPE_RANK_1,
    T5.PAYMENT_TYPE_RANK_2,
    T5.PAYMENT_TYPE_RANK_3,
    T2.*
from
    TOP_X_COMPANIES T1
    join PAYMENTS_MONTH_TYPE_INDUSTRY T2 on T1.COMPANY_ID = T2.COMPANY_ID
    join INDUSTRY_CATEGORY T4 on T1.COMPANY_ID = T4.COMPANY_ID
    join DEV.SBOX_ADITHYA.SG_GOV_ACRA T3 on T3.UEN = T4.UEN
    join TOP_PAYTYPE_RANK_ONE_ONLY T5 on T5.COMPANY_ID = T1.COMPANY_ID
where
    RANK < 4;

--#endregion