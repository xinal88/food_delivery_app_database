-- Update_audits_customers trigger

SELECT phone_number, gender FROM customers
WHERE customer_id = 'CUS2200'

UPDATE customers
SET phone_number = '+84346867145'
WHERE customer_id = 'CUS2200';

UPDATE customers
SET gender = 'Male'
WHERE customer_id = 'CUS2200';


SELECT * FROM audit;
DELETE FROM audit


-- Update_audits_restaurants trigger

SELECT name_res, status, open_time, close_time FROM restaurants
WHERE restaurant_id = 'RES20'

UPDATE restaurants
SET name_res = 'Ga Nuong Dien Bien Phu'
WHERE restaurant_id = 'RES20';

UPDATE restaurants
SET open_time = '9:00:00'
WHERE restaurant_id = 'RES20';

UPDATE restaurants
SET close_time = '20:00:00'
WHERE restaurant_id = 'RES20';

UPDATE restaurants
SET status = 'Available'
WHERE restaurant_id = 'RES20';

SELECT * FROM audit;
DELETE FROM audit


-- Update_audits_item_menu trigger

SELECT name, price, stock FROM item_menu
WHERE restaurant_id = 'RES20' AND item_id = 156;

UPDATE item_menu
SET price = '$15.00'
WHERE restaurant_id = 'RES20' AND item_id = 156;

UPDATE item_menu
SET stock = 500
WHERE restaurant_id = 'RES20' AND item_id = 156;

UPDATE item_menu
SET name = 'Chickenss Cheesesteak'
WHERE restaurant_id = 'RES20' AND item_id = 156;

SELECT * FROM audit;
DELETE FROM audit

------ADD_RATE TRIGGER

SELECT * from restaurants where restaurant_id='RES1';
SELECT * from drivers where driver_id='DVR199';

SELECT * from feedback f inner join orders o on f.order_id= o.order_id
where restaurant_id='RES1';

SELECT * from feedback f inner join orders o on f.order_id= o.order_id
                         inner join drivers d on d.driver_id=o.driver_id
where d.driver_id='DVR199';


------CHECK_ITEM_RESTAURANT TRIGGER

INSERT INTO orders(order_id,customer_id, driver_id, restaurant_id) values('OD20005','CUS199','DVR199','RES1');
SELECT * from item_menu where restaurant_id='RES1';
INSERT INTO order_detail values('OD20005',5,5);
INSERT INTO order_detail values('OD20005',8,5);--- Item_id does not belong to the restaurant in the order.

---------------------Update_Max_Use TRIGGER----------------------
SELECT coupon_id, discountvalue, max_usage FROM coupons
WHERE coupon_id = 'COUP1' OR coupon_id = 'COUP2'

INSERT INTO orders (order_id)
VALUES ('OD21000')

INSERT INTO coupon_order (order_id, coupon_id)
VALUES ('OD21000', 'COUP1')

INSERT INTO coupon_order (order_id, coupon_id)
VALUES ('OD21000', 'COUP2')

SELECT coupon_id, max_usage FROM coupons
WHERE coupon_id = 'COUP1' OR coupon_id = 'COUP2'

DELETE FROM coupon_order
WHERE order_id = 'OD21000'
DELETE FROM orders
WHERE order_id = 'OD21000'

UPDATE coupons
SET max_usage = '0'
WHERE coupon_id = 'COUP1'

SELECT coupon_id, discountvalue, max_usage FROM coupons
WHERE coupon_id = 'COUP1'

INSERT INTO orders (order_id)
VALUES ('OD21000')

INSERT INTO coupon_order (order_id, coupon_id)
VALUES ('OD21000', 'COUP1')

SELECT * FROM coupons WHERE coupon_id = 'COUP1'
SELECT * FROM messages

DELETE FROM messages

-----------------------Stock_Left-----------------------------
	
SELECT * FROM item_menu WHERE restaurant_id = 'RES1' AND item_id = '1' 

INSERT INTO orders (order_id, restaurant_id )
VALUES ('OD41000', 'RES1')
INSERT INTO order_detail 
VALUES ('OD41000', '1', '1')

SELECT * FROM item_menu WHERE restaurant_id = 'RES1' AND item_id = '1' 


DELETE FROM order_detail
WHERE order_id = 'OD41000'
DELETE FROM orders
WHERE order_id = 'OD41000'

INSERT INTO orders (order_id, restaurant_id )
VALUES ('OD41000', 'RES1')
INSERT INTO order_detail 
VALUES ('OD41000', '1', '200')

SELECT * FROM order_detail WHERE order_id = 'OD41000'
SELECT * FROM messages

DELETE FROM messages

----------------Update_cancel------------------ 	

SELECT order_id, status, res_cost, ship_cost, total_cost FROM orders
WHERE order_id = 'OD1' OR order_id = 'OD11'

UPDATE orders
SET status = 'CANCELED'
WHERE order_id = 'OD11'

SELECT order_id, status, res_cost, ship_cost, total_cost FROM orders
WHERE order_id = 'OD1' OR order_id = 'OD11'
SELECT * FROM messages

UPDATE orders
SET status = 'CANCELED'
WHERE order_id = 'OD1'

SELECT order_id, status, res_cost, ship_cost, total_cost FROM orders
WHERE order_id = 'OD1' OR order_id = 'OD11';

---------------Find_Restaurant_By_Dish Fuction --------------
SELECT * FROM findrestaurantbydish('Coke');
----------------Calculate_price_fuction
SELECT order_id, res_cost, ship_cost, total_cost FROM orders
WHERE order_id = 'OD2' ;
SELECT * from Calculate_price_fuction('OD2','MOMO');
SELECT order_id, res_cost, ship_cost, total_cost FROM orders
WHERE order_id = 'OD2' ;
--------Calculate_monthly_revenue
SELECT * FROM orders
WHERE restaurant_id = 'RES1' ;
SELECT * from calculate_monthly_revenue('RES1',4,2023) ---Only take orders which status is TAKEN (ORDER is completed)
-------get_top_foods_under_age
SELECT * FROM get_top_foods_under_age(25);
