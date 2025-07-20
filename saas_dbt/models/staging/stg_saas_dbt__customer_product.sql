{{
    config(materialized = 'table')
}}

with source as(
    select * from {{source('saas_dbt_raw', 'customer_product')}}
),

renamed as(
    select 
        -- id
        customer_id as customer_id,
        product as product_id,

        -- timestamp
        cast(signup_date_time as timestamp_tz) as signup_time,
        cast(cancel_date_time as timestamp_tz) as cancel_time,

        -- boolean
        case when cancel_date_time is null then true else false end as is_active
    from
        source 
)

select * from renamed