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
    case when t1.industry is null then 'No Industry' else 'With Industry' end,
    COUNT(distinct T1.COMPANY_ID),
    sum(TOTAL_GTV),
    sum(TOTAL_REVENUE),
    sum(TOTAL_NET_REVENUE),
    sum(TOTAL_TX_COUNT)
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
    join (select distinct company_id from CBM.CARDUP_DB_REPORTING.USER_DATA where status='Active' and CU_LOCALE_ID = 1) T3 on T1.COMPANY_ID = T3.COMPANY_ID
where
    t1.CU_LOCALE_ID = 1
group by
    1,2;


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
    case when t1.industry is null then 'No Industry' else 'With Industry' end,
    COUNT(distinct T1.COMPANY_ID),
    sum(TOTAL_GTV),
    sum(TOTAL_REVENUE),
    sum(TOTAL_NET_REVENUE),
    sum(TOTAL_TX_COUNT)
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
    join (select distinct company_id from CBM.CARDUP_DB_REPORTING.USER_DATA where status='Active' and CU_LOCALE_ID = 1) T3 on T1.COMPANY_ID = T3.COMPANY_ID
where
    t1.CU_LOCALE_ID = 1
group by
    1,2;


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
   T1.industry,
   T1.PRIMARY_SSIC_DESCRIPTION,
    sum(TOTAL_GTV),
    sum(TOTAL_REVENUE),
    sum(TOTAL_NET_REVENUE),
    sum(TOTAL_TX_COUNT)
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
    join (select distinct company_id from CBM.CARDUP_DB_REPORTING.USER_DATA where status='Active' and CU_LOCALE_ID = 1) T3 on T1.COMPANY_ID = T3.COMPANY_ID
where
    t1.CU_LOCALE_ID = 1
group by
    1,2,3;


--list of industries, SSIC
select distinct primary_ssic_description from DEV.SBOX_ADITHYA.SG_GOV_ADDITIONAL_DATA;

--list of industries, CU
select distinct industry from CBM.CARDUP_DB_REPORTING.COMPANY_DATA;