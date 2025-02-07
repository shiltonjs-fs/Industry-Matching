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