{{
    config(materialized = 'table')
}}

with source as(
    select * from {{source('saas_dbt_raw', 'customer_cases')}}
),

renamed as(

    select
        --id
        CASE_ID as case_id,
        CUSTOMER_ID as  customer_id,

        --strings
        lower(trim(CHANNEL)) as channel,
        lower(trim(REASON)) as reason,

        --datetime
        DATE_TIME::timestamp_tz as created_at

    from
        source

)

select * from renamed