{{
    config(materialized = 'table')
}}

with source as(
    select * from {{source('saas_dbt_raw', 'product_info')}}
),

renamed as(
    select 
        -- id
        product_id as product_id,

        -- string -> renaming name to billing type (monthly or annual)
        -- trimming the values 'annual_subscription' to just 'annual' or 'monthly'
        trim(lower(replace(name, '_subscription', ''))) as billing_type,

        -- number
        price as price,
        cast(billing_cycle as int) as billing_cycle
    from   
        source
)

select * from renamed