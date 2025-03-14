with

source as (

    SELECT 
        order_id,
        location_id,
        customer_id,
        subtotal_cents,
        tax_paid_cents,
        order_total_cents,
        subtotal,
        tax_paid,
        order_total,
        ordered_at,
        order_cost,
        order_items_subtotal,
        count_food_items,
        count_drink_items,
        count_order_items,
        is_food_order,
        is_drink_order,
        customer_order_number
    FROM {{ source('urn:datacontract:project:jaffle-shop:dbt:process-model:orders', 'orders') }}

)

SELECT
  DATE(ordered_at) AS calendar_id,
  location_id,
  SUM(subtotal) AS gsv,
  SUM(tax_paid) AS trade,
  SUM(subtotal) - SUM(tax_paid) AS nsv,
  SUM(order_cost) AS cogs,
  SUM(subtotal) - SUM(tax_paid) - SUM(order_cost) AS mac
FROM source
GROUP BY ordered_at, location_id;
