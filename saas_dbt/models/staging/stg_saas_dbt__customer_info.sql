{{
    config(materialized = 'table')
}}

with source as(
    select * from {{source('saas_dbt_raw', 'customer_info')}}
),

renamed as(
    
    select
        --id
        customer_id as customer_id,

        -- number
        cast(age as int) as age,

        -- strings
        lower(trim(gender)) as gender
    
    from
        source
)

select * from renamed