{{
    config(materialized = 'table')
}}

with source as(
    select * from {{source('saas_dbt_raw', 'customer_cases')}}
),

renamed as(

    select
        --id
        case_id as case_id,
        customer_id as  customer_id,

        --strings
        lower(trim(channel)) as channel,
        lower(trim(reason)) as reason,

        --datetime
        cast(date_time as timestamp_tz) as created_at

    from
        source

)

select * from renamed