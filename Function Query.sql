----Function calculate_monthly_revenue

CREATE OR REPLACE FUNCTION calculate_monthly_revenue(
	p_restaurant_id character,
	p_month integer,
	p_year integer)
    RETURNS numeric
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    total_revenue NUMERIC := 0;
BEGIN
    SELECT COALESCE(SUM(res_cost)::NUMERIC(20, 1), 0) 
    INTO total_revenue
    FROM orders
    WHERE restaurant_id = p_restaurant_id
        AND EXTRACT(MONTH FROM time_order) = p_month
        AND EXTRACT(YEAR FROM time_order) = p_year;
    RETURN total_revenue;
END;
$BODY$;


-------Function calculate_price_fuction
CREATE EXTENSION IF NOT EXISTS cube;
CREATE EXTENSION IF NOT EXISTS earthdistance;

CREATE OR REPLACE FUNCTION calculate_price_fuction(
	p_order_id character,
	payment_method1 character)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    LAT1 DOUBLE PRECISION;
    LO1 DOUBLE PRECISION;
    LAT2 DOUBLE PRECISION;
    LO2 DOUBLE PRECISION;
    S_DISTANCE NUMERIC(10, 1);
    S_COST NUMERIC(10, 1);
    RES_PRICE NUMERIC(10, 1);
    DISCOUNT_NUM INT;
    CALCULATED_PRICE NUMERIC(20, 1);
BEGIN
    -- Calculate the shipping cost
    SELECT CUSTOMERS.LAT, CUSTOMERS.LO
    INTO LAT1, LO1
    FROM ORDERS
    INNER JOIN CUSTOMERS ON CUSTOMERS.customer_id = ORDERS.customer_id
    WHERE ORDERS.ORDER_ID = p_order_id;

    SELECT RESTAURANTS.LAT, RESTAURANTS.LO
    INTO LAT2, LO2
    FROM ORDERS
    JOIN RESTAURANTS ON RESTAURANTS.RESTAURANT_ID = ORDERS.RESTAURANT_ID
    WHERE ORDERS.ORDER_ID = p_order_id;

    SELECT earth_distance(
        ll_to_earth(LAT1, LO1),
        ll_to_earth(LAT2, LO2)
    ) INTO S_DISTANCE;
    
    S_COST := (S_DISTANCE / 1000) * 2; 
    -- Calculate the restaurant cost
    SELECT COALESCE(SUM(ITEM_MENU.PRICE * ORDER_DETAIL.QUANTITY)::NUMERIC(10, 1), 0)
    INTO RES_PRICE
FROM ORDERS
JOIN ORDER_DETAIL ON ORDERS.ORDER_ID = ORDER_DETAIL.ORDER_ID
JOIN ITEM_MENU ON ORDER_DETAIL.ITEM_ID = ITEM_MENU.ITEM_ID
WHERE ORDER_DETAIL.ORDER_ID = p_order_id;

    -- Calculate the discount
    SELECT COALESCE(SUM(COU.DISCOUNTVALUE), 0)
    INTO DISCOUNT_NUM
    FROM COUPON_ORDER CO
    INNER JOIN COUPONS COU ON CO.COUPON_ID = COU.COUPON_ID
    WHERE CO.ORDER_ID = p_order_id;

    -- Calculate the total cost considering the discount
    CALCULATED_PRICE := S_COST + RES_PRICE * (1 - (DISCOUNT_NUM / 100.0));

    RAISE NOTICE 'Calculated Total Cost: %', CALCULATED_PRICE;

    -- Update payment record
    UPDATE orders
    SET res_cost = RES_PRICE, ship_cost = S_COST, total_cost = CALCULATED_PRICE, payment_method =payment_method1
    WHERE order_id = p_order_id;

END;
$BODY$;
-----Function findrestaurantbydish 
CREATE OR REPLACE FUNCTION findrestaurantbydish(
	dish_name character varying)
    RETURNS TABLE(restaurant_id character, name_res character, item_id integer, name character) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    RETURN QUERY
    SELECT R.restaurant_id, R.name_res AS restaurant_name, ITM.item_id, ITM.name AS dish_name
    FROM RESTAURANTS R
    JOIN ITEM_MENU ITM ON R.restaurant_id = ITM.restaurant_id
    WHERE ITM.name ILIKE '%' || dish_name || '%';
END;
$BODY$;

-----FUNCTION get_top_foods_under_age
CREATE OR REPLACE FUNCTION get_top_foods_under_age(age_threshold INTEGER)
RETURNS TABLE(food_name char(100), quantity INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ITEM_MENU.name AS food_name,
        COUNT(ORDER_DETAIL.order_id)::INTEGER AS quantity
    FROM
        CUSTOMERS
    JOIN
        ORDERS ON CUSTOMERS.customer_id = ORDERS.customer_id
    JOIN
        ORDER_DETAIL ON ORDER_DETAIL.order_id = ORDERS.order_id
    JOIN
        ITEM_MENU ON ORDER_DETAIL.item_id = ITEM_MENU.item_id
    WHERE
        AGE(CUSTOMERS.date_of_birth) < INTERVAL '1 year' * age_threshold
    GROUP BY
        ITEM_MENU.item_id
    ORDER BY
        quantity DESC
    LIMIT 5;
END;
$$ LANGUAGE plpgsql;
