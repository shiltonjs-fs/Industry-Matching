drop view if exists DEV.SBOX_SHILTON.CU_B2B_INDUSTRY_SEGMENTATION_MAIN_TABLE;
create view DEV.SBOX_SHILTON.CU_B2B_INDUSTRY_SEGMENTATION_MAIN_TABLE as
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
    ),
    USE_COLLECT as (
        select
            COMPANY_ID,
            MAX(
                case
                    when MAKE_OR_COLLECT = 'Collect' then 1
                    else 0
                end
            ) as USE_COLLECT
        from
            TX_TABLE
        group by
            1
    ),
    AGG_TX_TABLE_ALL_MAKE as (
        SELECT
            COMPANY_ID,
            AVG(CARDUP_PAYMENT_USD_AMT) AS AVG_USD_AMT_ALL_MAKE,
            AVG(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) AS AVG_REVENUE_USD_AMT_ALL_MAKE,
            AVG(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) AS AVG_NET_REVENUE_USD_AMT_ALL_MAKE,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) / SUM(CARDUP_PAYMENT_USD_AMT) AS AVG_CU_RATE_ALL_MAKE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) AS TX_COUNT_ALL_MAKE,
            COUNT(distinct PAYMENT_TYPE) AS PAYTYPE_COUNT_ALL_MAKE,
            MIN(PAYMENT_DATE) AS FIRST_PAYMENT_DATE_ALL_MAKE,
            MAX(PAYMENT_DATE) AS LAST_PAYMENT_DATE_ALL_MAKE,
            DATEDIFF('month', MIN(PAYMENT_DATE), MAX(PAYMENT_DATE)) AS MONTHS_ACTIVE_MAKE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID)/(1+DATEDIFF('month', MIN(PAYMENT_DATE), MAX(PAYMENT_DATE))) AS FREQ_ACTIVE_MAKE,
            DATEDIFF('month', MIN(PAYMENT_DATE), CURRENT_DATE()) AS MONTHS_SINCE_FIRST_PAYMENT_ALL_MAKE,
            DATEDIFF('month', MAX(PAYMENT_DATE), CURRENT_DATE()) AS MONTHS_SINCE_LAST_PAYMENT_ALL_MAKE,
            -- Payment type breakdown counts
            COUNT(
                CASE
                    WHEN PAYMENT_TYPE = 'Supplier' THEN 1
                END
            ) AS SUPPLIER_PAYMENT_COUNT,
            COUNT(
                CASE
                    WHEN PAYMENT_TYPE = 'Payroll' THEN 1
                END
            ) AS PAYROLL_PAYMENT_COUNT,
            COUNT(
                CASE
                    WHEN PAYMENT_TYPE = 'Rent' THEN 1
                END
            ) AS RENT_PAYMENT_COUNT,
            -- Payment type percentage breakdown
            CASE
                WHEN COUNT(distinct PAYMENT_TYPE) > 0 THEN (
                    COUNT(
                        CASE
                            WHEN PAYMENT_TYPE = 'Supplier' THEN 1
                        END
                    ) / COUNT(distinct DWH_CARDUP_PAYMENT_ID)
                )
                ELSE 0
            END AS SUPPLIER_PAYMENT_PERCENT_MAKE,
            CASE
                WHEN COUNT(distinct PAYMENT_TYPE) > 0 THEN (
                    COUNT(
                        CASE
                            WHEN PAYMENT_TYPE = 'Payroll' THEN 1
                        END
                    ) / COUNT(distinct DWH_CARDUP_PAYMENT_ID)
                )
                ELSE 0
            END AS PAYROLL_PAYMENT_PERCENT_MAKE,
            CASE
                WHEN COUNT(distinct PAYMENT_TYPE) > 0 THEN (
                    COUNT(
                        CASE
                            WHEN PAYMENT_TYPE = 'Rent' THEN 1
                        END
                    ) / COUNT(distinct DWH_CARDUP_PAYMENT_ID)
                )
                ELSE 0
            END AS RENT_PAYMENT_PERCENT_MAKE
        FROM
            TX_TABLE
        WHERE
        TRUE 
            and PAYMENT_DATE >= '2020-01-01'
            and MAKE_OR_COLLECT = 'Make'
        GROUP BY
            COMPANY_ID
    ),
    AGG_TX_TABLE_ALL_COLLECT as (
        SELECT
            COMPANY_ID,
            AVG(CARDUP_PAYMENT_USD_AMT) AS AVG_USD_AMT_ALL_COLLECT,
            AVG(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) AS AVG_REVENUE_USD_AMT_ALL_COLLECT,
            AVG(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) AS AVG_NET_REVENUE_USD_AMT_ALL_COLLECT,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) / SUM(CARDUP_PAYMENT_USD_AMT) AS AVG_CU_RATE_ALL_COLLECT,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) AS TX_COUNT_ALL_COLLECT,
            COUNT(distinct PAYMENT_TYPE) AS PAYTYPE_COUNT_ALL_COLLECT,
            MIN(PAYMENT_DATE) AS FIRST_PAYMENT_DATE_ALL_COLLECT,
            MAX(PAYMENT_DATE) AS LAST_PAYMENT_DATE_ALL_COLLECT,
            DATEDIFF('month', MIN(PAYMENT_DATE), MAX(PAYMENT_DATE)) AS MONTHS_ACTIVE_COLLECT,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID)/(1+DATEDIFF('month', MIN(PAYMENT_DATE), MAX(PAYMENT_DATE))) AS FREQ_ACTIVE_COLLECT,
            DATEDIFF('month', MIN(PAYMENT_DATE), CURRENT_DATE()) AS MONTHS_SINCE_FIRST_PAYMENT_ALL_COLLECT,
            DATEDIFF('month', MAX(PAYMENT_DATE), CURRENT_DATE()) AS MONTHS_SINCE_LAST_PAYMENT_ALL_COLLECT,
            -- Payment type breakdown counts
            COUNT(
                CASE
                    WHEN PAYMENT_TYPE = 'Supplier' THEN 1
                END
            ) AS SUPPLIER_PAYMENT_COUNT,
            COUNT(
                CASE
                    WHEN PAYMENT_TYPE = 'Payroll' THEN 1
                END
            ) AS PAYROLL_PAYMENT_COUNT,
            COUNT(
                CASE
                    WHEN PAYMENT_TYPE = 'Rent' THEN 1
                END
            ) AS RENT_PAYMENT_COUNT,
            -- Payment type percentage breakdown
            CASE
                WHEN COUNT(distinct PAYMENT_TYPE) > 0 THEN (
                    COUNT(
                        CASE
                            WHEN PAYMENT_TYPE = 'Supplier' THEN 1
                        END
                    ) / COUNT(distinct DWH_CARDUP_PAYMENT_ID)
                )
                ELSE 0
            END AS SUPPLIER_PAYMENT_PERCENT_COLLECT,
            CASE
                WHEN COUNT(distinct PAYMENT_TYPE) > 0 THEN (
                    COUNT(
                        CASE
                            WHEN PAYMENT_TYPE = 'Payroll' THEN 1
                        END
                    ) / COUNT(distinct DWH_CARDUP_PAYMENT_ID)
                )
                ELSE 0
            END AS PAYROLL_PAYMENT_PERCENT_COLLECT,
            CASE
                WHEN COUNT(distinct PAYMENT_TYPE) > 0 THEN (
                    COUNT(
                        CASE
                            WHEN PAYMENT_TYPE = 'Rent' THEN 1
                        END
                    ) / COUNT(distinct DWH_CARDUP_PAYMENT_ID)
                )
                ELSE 0
            END AS RENT_PAYMENT_PERCENT_COLLECT
        FROM
            TX_TABLE
        WHERE
        TRUE 
            and PAYMENT_DATE >= '2020-01-01'
            and MAKE_OR_COLLECT = 'Collect'
        GROUP BY
            COMPANY_ID
    ),
    AGG_TX_TABLE_GROWTH_YOY_MAKE as (
        SELECT
            COMPANY_ID,
            -- AVG for 2023
            AVG(
                CASE
                    WHEN YEAR(PAYMENT_DATE) = 2023 THEN CARDUP_PAYMENT_USD_AMT
                END
            ) AS AVG_USD_AMT_2023_MAKE,
            -- AVG for 2024
            AVG(
                CASE
                    WHEN YEAR(PAYMENT_DATE) = 2024 THEN CARDUP_PAYMENT_USD_AMT
                END
            ) AS AVG_USD_AMT_2024_MAKE,
            -- Calculate growth from 2023 to 2024
            CASE
                WHEN AVG(
                    CASE
                        WHEN YEAR(PAYMENT_DATE) = 2023 THEN CARDUP_PAYMENT_USD_AMT
                    END
                ) > 0 THEN (
                    AVG(
                        CASE
                            WHEN YEAR(PAYMENT_DATE) = 2024 THEN CARDUP_PAYMENT_USD_AMT
                        END
                    ) - AVG(
                        CASE
                            WHEN YEAR(PAYMENT_DATE) = 2023 THEN CARDUP_PAYMENT_USD_AMT
                        END
                    )
                ) / AVG(
                    CASE
                        WHEN YEAR(PAYMENT_DATE) = 2023 THEN CARDUP_PAYMENT_USD_AMT
                    END
                )
                ELSE NULL -- No growth if the 2023 average is zero
            END AS USD_AMT_GROWTH_PERCENTAGE_MAKE
        FROM
            TX_TABLE
        WHERE
            PAYMENT_DATE >= '2023-01-01'
            and MAKE_OR_COLLECT = 'Make'
        GROUP BY
            COMPANY_ID
    ),
    AGG_TX_TABLE_MONTHLY_MAKE as (
        select
            COMPANY_ID,
            MAKE_OR_COLLECT,
            PAYMENT_TYPE,
            DATE_TRUNC(MONTH, PAYMENT_DATE) PAYMENT_MONTH,
            SUM(CARDUP_PAYMENT_USD_AMT) as TOTAL_USD_AMT_MONTHLY_MAKE,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) as TOTAL_REVENUE_USD_AMT_MONTHLY_MAKE,
            SUM(CARDUP_PAYMENT_NET_REVENUE_USD_AMT) as TOTAL_NET_REVENUE_USD_AMT_MONTHLY_MAKE,
            SUM(CARDUP_PAYMENT_TOTAL_REVENUE_USD_AMT) / SUM(CARDUP_PAYMENT_USD_AMT) as AVG_CU_RATE_MONTHLY_MAKE,
            COUNT(distinct DWH_CARDUP_PAYMENT_ID) as TX_COUNT_MONTHLY_MAKE
        from
            TX_TABLE
        where
            PAYMENT_DATE >= '2020-01-01'
            and MAKE_OR_COLLECT = 'Make'
        group by
            1,
            2,
            3,
            4
    ),
    -- Step 1: Generate all months and include every customer, even those with no payments
    ALLMONTHS AS (
        SELECT DISTINCT
            COMPANY_ID,
            PAYMENT_MONTH
        FROM
            (
                SELECT DISTINCT
                    COMPANY_ID
                FROM
                    TX_TABLE
                WHERE
                    PAYMENT_DATE >= '2020-01-01'
            ) AS COMPANIES
            CROSS JOIN (
                SELECT
                    1 AS PAYMENT_MONTH
                UNION ALL
                SELECT
                    2
                UNION ALL
                SELECT
                    3
                UNION ALL
                SELECT
                    4
                UNION ALL
                SELECT
                    5
                UNION ALL
                SELECT
                    6
                UNION ALL
                SELECT
                    7
                UNION ALL
                SELECT
                    8
                UNION ALL
                SELECT
                    9
                UNION ALL
                SELECT
                    10
                UNION ALL
                SELECT
                    11
                UNION ALL
                SELECT
                    12
            ) AS MONTHS
    ),
    -- Step 2: Get the monthly payments data for "Make" action
    MONTHLYPAYMENT_MAKE AS (
        SELECT
            COMPANY_ID,
            COUNT(distinct MONTH(PAYMENT_DATE)) OVER (
                PARTITION BY
                    COMPANY_ID
            ) as COUNT_PAYMENT_MONTHS,
            MONTH(PAYMENT_DATE) AS PAYMENT_MONTH,
            DWH_CARDUP_PAYMENT_ID,
            CARDUP_PAYMENT_USD_AMT
        FROM
            TX_TABLE
        WHERE
            PAYMENT_DATE >= '2020-01-01'
            AND MAKE_OR_COLLECT = 'Make'
    ),
    MONTHLYPAYMENT_MAKE_COUNT_NUMBER_MONTHS AS (
        SELECT
            COMPANY_ID,
            COUNT(distinct MONTH(PAYMENT_DATE)) as COUNT_PAYMENT_MONTHS
        FROM
            TX_TABLE
        WHERE
            PAYMENT_DATE >= '2020-01-01'
            AND MAKE_OR_COLLECT = 'Make'
        group by
            1
    ),
    -- Step 3: Get the first payment date for each customer
    FIRST_PAYMENT_DATE AS (
        SELECT
            COMPANY_ID,
            MIN(PAYMENT_DATE) AS FIRST_PAYMENT_DATE
        FROM
            TX_TABLE
        WHERE
            PAYMENT_DATE >= '2020-01-01'
        GROUP BY
            COMPANY_ID
    ),
    -- Step 4: Combine all months with payments data, ensuring 0 for non-paying months
    CUSTOMERPAYMENTSUMMARY_MAKE AS (
        SELECT
            AM.COMPANY_ID,
            AM.PAYMENT_MONTH,
            COUNT(DISTINCT MP.DWH_CARDUP_PAYMENT_ID) AS TX_COUNT,
            COALESCE(
                SUM(MP.CARDUP_PAYMENT_USD_AMT),
                CASE
                    WHEN DATEDIFF(DAY, FP.FIRST_PAYMENT_DATE, CURRENT_DATE()) < 365 THEN NULL -- Set to NULL if first payment is less than 1 year ago
                    ELSE 0
                END
            ) AS TOTAL_USD_AMT
        FROM
            ALLMONTHS AM
            LEFT JOIN MONTHLYPAYMENT_MAKE MP ON AM.COMPANY_ID = MP.COMPANY_ID
            AND AM.PAYMENT_MONTH = MP.PAYMENT_MONTH
            LEFT JOIN FIRST_PAYMENT_DATE FP ON AM.COMPANY_ID = FP.COMPANY_ID
        GROUP BY
            AM.COMPANY_ID,
            AM.PAYMENT_MONTH,
            FP.FIRST_PAYMENT_DATE
    ),
    -- Step 5: Aggregate the monthly payment amounts per customer, including non-paying months
    AGG_TX_TABLE_MONTHLY_MONTHYEAR_MAKE AS (
        SELECT
            T1.COMPANY_ID,
            -- Calculate Mean (Average) for each customer across all months
            AVG(TOTAL_USD_AMT) AS AVG_PAYMENT_MAKE,
            -- Calculate Standard Deviation for each customer across all months
            STDDEV(TOTAL_USD_AMT) AS PAYMENT_STDDEV_MAKE,
            -- Calculate Relative Standard Deviation (RSD)
            CASE
                WHEN AVG(TOTAL_USD_AMT) > 0 THEN (
                    STDDEV(
                        case
                            when T2.COUNT_PAYMENT_MONTHS < 3 then null
                            else TOTAL_USD_AMT
                        end
                    ) / AVG(TOTAL_USD_AMT)
                )
                ELSE 0
            END AS RSD_PERCENTAGE_MAKE
        FROM
            CUSTOMERPAYMENTSUMMARY_MAKE T1
            join MONTHLYPAYMENT_MAKE_COUNT_NUMBER_MONTHS T2 on T1.COMPANY_ID = T2.COMPANY_ID
        GROUP BY
            T1.COMPANY_ID
    ),
    MAIN_TABLE as (
        select
            T1.COMPANY_ID,
            ENTITY_NAME,
            CU_COMPANY_L1_INDUSTRY,
            CU_COMPANY_L2_INDUSTRY,
            AVG_USD_AMT_ALL_MAKE,
            AVG_REVENUE_USD_AMT_ALL_MAKE,
            AVG_NET_REVENUE_USD_AMT_ALL_MAKE,
            AVG_CU_RATE_ALL_MAKE,
            TX_COUNT_ALL_MAKE,
            FREQ_ACTIVE_MAKE,
            PAYTYPE_COUNT_ALL_MAKE,
            SUPPLIER_PAYMENT_PERCENT_MAKE,
            RENT_PAYMENT_PERCENT_MAKE,
            PAYROLL_PAYMENT_PERCENT_MAKE,
            MONTHS_SINCE_FIRST_PAYMENT_ALL_MAKE,
            MONTHS_SINCE_LAST_PAYMENT_ALL_MAKE,
            
            RSD_PERCENTAGE_MAKE,
            case
                when RSD_PERCENTAGE_MAKE is null then 1
                else 0
            end as ONLY_ONEOFF_TWOOFF_MAKE,

            AVG_USD_AMT_ALL_COLLECT,
            AVG_REVENUE_USD_AMT_ALL_COLLECT,
            AVG_NET_REVENUE_USD_AMT_ALL_COLLECT,
            AVG_CU_RATE_ALL_COLLECT,
            TX_COUNT_ALL_COLLECT,
            FREQ_ACTIVE_COLLECT,
            PAYTYPE_COUNT_ALL_COLLECT,
            SUPPLIER_PAYMENT_PERCENT_COLLECT,
            RENT_PAYMENT_PERCENT_COLLECT,
            PAYROLL_PAYMENT_PERCENT_COLLECT,
            MONTHS_SINCE_FIRST_PAYMENT_ALL_COLLECT,
            MONTHS_SINCE_LAST_PAYMENT_ALL_COLLECT,

            USE_COLLECT
        from
            COMPANY_TABLE T1
            left outer join AGG_TX_TABLE_ALL_MAKE T2 on T1.COMPANY_ID = T2.COMPANY_ID
            left outer join AGG_TX_TABLE_ALL_COLLECT T5 on T1.COMPANY_ID = T5.COMPANY_ID
            left outer join AGG_TX_TABLE_MONTHLY_MONTHYEAR_MAKE T3 on T1.COMPANY_ID = T3.COMPANY_ID
            left outer join USE_COLLECT T4 on T1.COMPANY_ID = T4.COMPANY_ID
    )
select
    *
from
    MAIN_TABLE;
