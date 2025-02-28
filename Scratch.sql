--check unmatched UEN
select
    *
from
    (
        select
            T2.PRIMARY_SSIC_DESCRIPTION,
            T1.*
        from
            CBM.CARDUP_DB_REPORTING.COMPANY_DATA T1
            left outer join DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on LOWER(T1.UEN) = LOWER(T2.UEN)
    )
where
    PRIMARY_SSIC_DESCRIPTION is null
    and CU_LOCALE_ID = 1;

--matching
select
    PRIMARY_SSIC_DESCRIPTION,
    INDUSTRY,
    COUNT(distinct UEN)
from
    (
        select
            T2.PRIMARY_SSIC_DESCRIPTION,
            T1.*
        from
            CBM.CARDUP_DB_REPORTING.COMPANY_DATA T1
            left outer join DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on LOWER(T1.UEN) = LOWER(T2.UEN)
    )
where
    PRIMARY_SSIC_DESCRIPTION is not null
    and CU_LOCALE_ID = 1
group by
    1,
    2;

--count valid vs invalid uen
select
    case
        when PRIMARY_SSIC_DESCRIPTION is null then 'Invalid'
        else 'Valid'
    end,
    COUNT(distinct UEN)
from
    (
        select
            T2.PRIMARY_SSIC_DESCRIPTION,
            T1.*
        from
            CBM.CARDUP_DB_REPORTING.COMPANY_DATA T1
            left outer join DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on LOWER(T1.UEN) = LOWER(T2.UEN)
    )
where
    CU_LOCALE_ID = 1
group by
    1;

--payments table
select
    CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
    SUM(CARDUP_PAYMENT_USD_AMT) TOTAL_GTV,
    SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) TOTAL_REVENUE,
    SUM(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) TOTAL_NET_REVENUE,
    COUNT(distinct DWH_CARDUP_PAYMENT_ID) TOTAL_TX_COUNT,
    MAX(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) LATEST_TX_DATE
from
    ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
WHERE
    CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
    AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
    and CARDUP_PAYMENT_CU_LOCALE_ID = 1
    and DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) >= DATE('2021-01-01')
group by
    1;

--valid vs invalid uen, metrics
with
    PAYMENTS as (
        select
            CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
            SUM(CARDUP_PAYMENT_USD_AMT) TOTAL_GTV,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) TOTAL_REVENUE,
            SUM(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) TOTAL_NET_REVENUE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) TOTAL_TX_COUNT,
            MAX(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) LATEST_TX_DATE
        from
            ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
        WHERE
            CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
            AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
            and CARDUP_PAYMENT_CU_LOCALE_ID = 1
            and DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) >= DATE('2021-01-01')
        group by
            1
    )
select
    case
        when PRIMARY_SSIC_DESCRIPTION is null then 'Invalid'
        else 'Valid'
    end,
    case
        when T1.INDUSTRY is null then 'No Industry'
        else 'With Industry'
    end,
    COUNT(distinct T1.COMPANY_ID),
    SUM(TOTAL_GTV),
    SUM(TOTAL_REVENUE),
    SUM(TOTAL_NET_REVENUE),
    SUM(TOTAL_TX_COUNT)
from
    (
        select
            T2.PRIMARY_SSIC_DESCRIPTION,
            T1.*
        from
            CBM.CARDUP_DB_REPORTING.COMPANY_DATA T1
            left outer join DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on LOWER(T1.UEN) = LOWER(T2.UEN)
    ) T1
    join PAYMENTS T2 on T1.COMPANY_ID = T2.COMPANY_ID
    join (
        select distinct
            COMPANY_ID
        from
            CBM.CARDUP_DB_REPORTING.USER_DATA
        where
            STATUS = 'Active'
            and CU_LOCALE_ID = 1
    ) T3 on T1.COMPANY_ID = T3.COMPANY_ID
where
    T1.CU_LOCALE_ID = 1
group by
    1,
    2;

--valid vs invalid uen, metrics, 2024 onwards only
with
    PAYMENTS as (
        select
            CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
            SUM(CARDUP_PAYMENT_USD_AMT) TOTAL_GTV,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) TOTAL_REVENUE,
            SUM(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) TOTAL_NET_REVENUE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) TOTAL_TX_COUNT,
            MAX(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) LATEST_TX_DATE
        from
            ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
        WHERE
            CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
            AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
            and CARDUP_PAYMENT_CU_LOCALE_ID = 1
            and DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) >= DATE('2024-01-01')
        group by
            1
    )
select
    case
        when PRIMARY_SSIC_DESCRIPTION is null then 'Invalid'
        else 'Valid'
    end,
    case
        when T1.INDUSTRY is null then 'No Industry'
        else 'With Industry'
    end,
    COUNT(distinct T1.COMPANY_ID),
    SUM(TOTAL_GTV),
    SUM(TOTAL_REVENUE),
    SUM(TOTAL_NET_REVENUE),
    SUM(TOTAL_TX_COUNT)
from
    (
        select
            T2.PRIMARY_SSIC_DESCRIPTION,
            T1.*
        from
            CBM.CARDUP_DB_REPORTING.COMPANY_DATA T1
            left outer join DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on LOWER(T1.UEN) = LOWER(T2.UEN)
    ) T1
    join PAYMENTS T2 on T1.COMPANY_ID = T2.COMPANY_ID
    join (
        select distinct
            COMPANY_ID
        from
            CBM.CARDUP_DB_REPORTING.USER_DATA
        where
            STATUS = 'Active'
            and CU_LOCALE_ID = 1
    ) T3 on T1.COMPANY_ID = T3.COMPANY_ID
where
    T1.CU_LOCALE_ID = 1
group by
    1,
    2;

--all companies
with
    PAYMENTS as (
        select
            CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
            SUM(CARDUP_PAYMENT_USD_AMT) TOTAL_GTV,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) TOTAL_REVENUE,
            SUM(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) TOTAL_NET_REVENUE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) TOTAL_TX_COUNT,
            MAX(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) LATEST_TX_DATE
        from
            ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
        WHERE
            CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
            AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
            and CARDUP_PAYMENT_CU_LOCALE_ID = 1
            and DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) >= DATE('2021-01-01')
        group by
            1
    )
select
    T1.COMPANY_ID,
    T1.INDUSTRY,
    T1.PRIMARY_SSIC_DESCRIPTION,
    SUM(TOTAL_GTV),
    SUM(TOTAL_REVENUE),
    SUM(TOTAL_NET_REVENUE),
    SUM(TOTAL_TX_COUNT)
from
    (
        select
            T2.PRIMARY_SSIC_DESCRIPTION,
            T1.*
        from
            CBM.CARDUP_DB_REPORTING.COMPANY_DATA T1
            left outer join DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on LOWER(T1.UEN) = LOWER(T2.UEN)
    ) T1
    join PAYMENTS T2 on T1.COMPANY_ID = T2.COMPANY_ID
    join (
        select distinct
            COMPANY_ID
        from
            CBM.CARDUP_DB_REPORTING.USER_DATA
        where
            STATUS = 'Active'
            and CU_LOCALE_ID = 1
    ) T3 on T1.COMPANY_ID = T3.COMPANY_ID
where
    T1.CU_LOCALE_ID = 1
group by
    1,
    2,
    3;

--list of industries, SSIC
select distinct
    PRIMARY_SSIC_DESCRIPTION
from
    DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA;

--list of industries, CU
select distinct
    INDUSTRY
from
    CBM.CARDUP_DB_REPORTING.COMPANY_DATA;

--matching query for ARD
select
    T2.PRIMARY_SSIC_DESCRIPTION,
    T1.*
from
    CBM.CARDUP_DB_REPORTING.COMPANY_DATA T1
    left outer join DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on LOWER(T1.UEN) = LOWER(T2.UEN);

select
    *
from
    CDM.COUNTERPARTY.CARDUP_COMPANY_T
limit
    10;

select
    T1.*,
    T3.L1_INDUSTRY CU_COMPANY_L1_INDUSTRY,
    T3.L2_INDUSTRY CU_COMPANY_L2_INDUSTRY,
    T3.L3_INDUSTRY CU_COMPANY_L3_INDUSTRY
from
    CDM.COUNTERPARTY.CARDUP_COMPANY_T T1
    JOIN DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on T1.CU_COMPANY_UEN = T2.UEN --sbox table to be replaced
    JOIN DEV.SBOX_SHILTON.CU_B2B_INDUSTRY_MATCHING T3 on T3.L3_INDUSTRY = T2.PRIMARY_SSIC_DESCRIPTION --temp table uploaded with csv
where
    T1.COMPANY_CU_LOCALE_ID = 1;

select
    T3.L1_INDUSTRY CU_COMPANY_L1_INDUSTRY,
    COUNT(distinct T1.CU_COMPANY_ID) COUNT_COMPANY
from
    CDM.COUNTERPARTY.CARDUP_COMPANY_T T1
    JOIN DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on T1.CU_COMPANY_UEN = T2.UEN --sbox table to be replaced
    JOIN DEV.SBOX_SHILTON.CU_B2B_INDUSTRY_MATCHING T3 on T3.L3_INDUSTRY = T2.PRIMARY_SSIC_DESCRIPTION --temp table uploaded with csv
where
    T1.COMPANY_CU_LOCALE_ID = 1
group by
    1;

--correl check
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
    COMPANY_ID,
    -- CU_COMPANY_L2_INDUSTRY,
    -- CU_COMPANY_L3_INDUSTRY,
    APPROX_PERCENTILE(TOTAL_GTV, 0.5) MEDIAN_GTV,
    APPROX_PERCENTILE(TOTAL_NET_REVENUE, 0.5) MEDIAN_NET_REVENUE,
from
    PAYMENTS_MONTH_TYPE_INDUSTRY
group by
    1
    --,2
    --,3
;

select
    *
from
    ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
where
    CARDUP_PAYMENT_PRODUCT_NAME LIKE '%COLLECT%'
limit
    10;

select
    CU_COMPANY_INDUSTRY_NAME,
    CU_COMPANY_L1_INDUSTRY,
    CU_COMPANY_L2_INDUSTRY,
    COUNT(distinct CU_COMPANY_ID)
from
    CDM.COUNTERPARTY.CARDUP_COMPANY_T
where
    COMPANY_CU_LOCALE_ID = 1
group by
    1,
    2,
    3;

select
    *
from
    DEV.SBOX_ADITHYA.SG_GOV_ACRA
limit
    10;

select distinct
    CU_COMPANY_ID COMPANY_ID,
    T3.L1_INDUSTRY CU_COMPANY_L1_INDUSTRY,
    T3.L2_INDUSTRY CU_COMPANY_L2_INDUSTRY,
    T3.L3_INDUSTRY CU_COMPANY_L3_INDUSTRY,
    *
from
    CDM.COUNTERPARTY.CARDUP_COMPANY_T T1
    left outer join DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on T1.CU_COMPANY_UEN = T2.UEN
    left outer join CBM.GSHEET.CU_B2B_INDUSTRY_MATCHING T3 on T2.PRIMARY_SSIC_DESCRIPTION = T3.L3_INDUSTRY
where
    COMPANY_CU_LOCALE_ID = 1;

select
    *
from
    DEV.SBOX_ADITHYA.SG_GOV_ACRA
limit
    10;

with
    MAIN as (
        select
            COMPANY_ID,
            CU_COMPANY_L1_INDUSTRY,
            CU_COMPANY_L2_INDUSTRY,
            AVG_USD_AMT_ALL_MAKE,
            AVG_NET_REVENUE_USD_AMT_ALL_MAKE,
            FREQ_ACTIVE_MAKE,
            PAYTYPE_COUNT_ALL_MAKE,
            SUPPLIER_PAYMENT_PERCENT_MAKE,
            RENT_PAYMENT_PERCENT_MAKE,
            PAYROLL_PAYMENT_PERCENT_MAKE,
            MONTHS_SINCE_FIRST_PAYMENT_ALL_MAKE,
            MONTHS_SINCE_LAST_PAYMENT_ALL_MAKE,
            RSD_PERCENTAGE_MAKE,
            USE_COLLECT,
            ENTITY_NAME
        from
            DEV.SBOX_SHILTON.CU_B2B_INDUSTRY_SEGMENTATION_MAIN_TABLE
        where
            CU_COMPANY_L1_INDUSTRY is not null
    )
select
    CU_COMPANY_L1_INDUSTRY,
    AVG(USE_COLLECT),
    SUM(USE_COLLECT * AVG_USD_AMT_ALL_MAKE) / SUM(AVG_USD_AMT_ALL_MAKE)
from
    MAIN
group by
    ROLLUP (1);

with
    COMPANY_TABLE as (
        select distinct
            T1.CU_COMPANY_ID COMPANY_ID,
            T3.L1_INDUSTRY CU_COMPANY_L1_INDUSTRY,
            T3.L2_INDUSTRY CU_COMPANY_L2_INDUSTRY,
            T3.L3_INDUSTRY CU_COMPANY_L3_INDUSTRY,
            T4.ENTITY_NAME
        from
            CDM.COUNTERPARTY.CARDUP_COMPANY_T T1
            left outer join DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA T2 on T1.CU_COMPANY_UEN = T2.UEN
            left outer join CBM.GSHEET.CU_B2B_INDUSTRY_MATCHING T3 on T2.PRIMARY_SSIC_DESCRIPTION = T3.L3_INDUSTRY
            left outer join DEV.SBOX_ADITHYA.SG_GOV_ACRA T4 on T1.CU_COMPANY_UEN = T4.UEN
        where
            COMPANY_CU_LOCALE_ID = 1
    ),
    TX_TABLE as (
        select
            CARDUP_PAYMENT_CUSTOMER_COMPANY_ID COMPANY_ID,
            DWH_CARDUP_PAYMENT_ID,
            case
                when CARDUP_PAYMENT_PRODUCT_NAME LIKE '%MAKE%' then 'Make'
                else 'Collect'
            end as MAKE_OR_COLLECT,
            CARDUP_PAYMENT_PAYMENT_TYPE PAYMENT_TYPE,
            DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS) PAYMENT_DATE,
            CARDUP_PAYMENT_USD_AMT,
            CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT,
            CARDUP_PAYMENT_NET_REVENUE_USD_AMT,
            CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT / CARDUP_PAYMENT_USD_AMT CU_RATE
        from
            ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
        where
            CARDUP_PAYMENT_CU_LOCALE_ID = 1
            and CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
            AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
            and DATE_TRUNC(YEAR, DATE(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) = DATE('2024-01-01')
    )
select
    CU_COMPANY_L1_INDUSTRY,
    MAKE_OR_COLLECT,
    PAYMENT_TYPE,
    MEDIAN(CARDUP_PAYMENT_USD_AMT) TOTAL_GTV,
    MEDIAN(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) TOTAL_REVENUE,
    MEDIAN(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) TOTAL_NET_REVENUE
from
    COMPANY_TABLE T1
    join TX_TABLE T2 on T1.COMPANY_ID = T2.COMPANY_ID
group by
    1,
    2,
    3;

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
            and CARDUP_PAYMENT_PRODUCT_NAME LIKE '%COLLECT%'
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
            5
            --,6
    )
select
    CU_COMPANY_L1_INDUSTRY,
    PAYMENT_TYPE,
    SUM(TOTAL_GTV) TOTAL_GTV,
    SUM(TOTAL_REVENUE) TOTAL_REVENUE,
    SUM(TOTAL_NET_REVENUE) TOTAL_NET_REVENUE,
    MEDIAN(TOTAL_GTV) MEDIAN_GTV,
    MEDIAN(TOTAL_REVENUE) MEDIAN_REVENUE,
    MEDIAN(TOTAL_NET_REVENUE) MEDIAN_NET_REVENUE,
    AVG(TOTAL_GTV) AVG_GTV,
    AVG(TOTAL_REVENUE) AVG_REVENUE,
    AVG(TOTAL_NET_REVENUE) AVG_NET_REVENUE
from
    PAYMENTS_MONTH_TYPE_INDUSTRY
group by
    1,
    2;

select
    CARDUP_PAYMENT_CUSTOMER_COMPANY_ID, avg(case when cardup_payment_schedule_type = 'recurring' then 1 else 0 end)
from
    ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
where
    CARDUP_PAYMENT_CU_LOCALE_ID = 1
    and CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
    AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
group by 1;

WITH RankedMonths AS (
    SELECT
        CARDUP_PAYMENT_CUSTOMER_COMPANY_ID, 
        date_part(month, date(CARDUP_PAYMENT_SUCCESS_AT_UTC_TS)) AS month,
        count(distinct DWH_CARDUP_PAYMENT_ID) AS tx_count,
        RANK() OVER (
            PARTITION BY CARDUP_PAYMENT_CUSTOMER_COMPANY_ID 
            ORDER BY count(distinct DWH_CARDUP_PAYMENT_ID) DESC
        ) AS rank
    FROM ADM.TRANSACTION.CARDUP_PAYMENT_DENORM_T
    WHERE
        CARDUP_PAYMENT_CU_LOCALE_ID = 1
        AND CARDUP_PAYMENT_STATUS NOT IN ('Payment Failed', 'Cancelled', 'Refunded', 'Refunding')
        AND CARDUP_PAYMENT_USER_TYPE IN ('business', 'guest')
    GROUP BY 1, 2
)
SELECT 
    CARDUP_PAYMENT_CUSTOMER_COMPANY_ID,
    MAX(CASE WHEN rank = 1 THEN month END) AS top_month,
    MAX(CASE WHEN rank = 1 THEN tx_count END) AS top_tx_count,
    MAX(CASE WHEN rank = 2 THEN month END) AS second_top_month,
    MAX(CASE WHEN rank = 2 THEN tx_count END) AS second_top_tx_count
FROM RankedMonths
WHERE rank <= 2
GROUP BY CARDUP_PAYMENT_CUSTOMER_COMPANY_ID;

