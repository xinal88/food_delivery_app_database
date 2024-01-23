--update_max_use

CREATE OR REPLACE FUNCTION update_max_use()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    
AS $BODY$
DECLARE 
	USE_LEFT4ID INT;
BEGIN
	UPDATE coupons SET MAX_USAGE = MAX_USAGE - 1 WHERE coupon_id = NEW.coupon_id;

	SELECT MAX_USAGE INTO USE_LEFT4ID FROM coupons WHERE coupon_id = NEW.coupon_id LIMIT 1;

	IF USE_LEFT4ID <= 0 THEN 
		UPDATE coupons SET discountvalue = 0 WHERE coupon_id = NEW.coupon_id; 
	END IF;
	
	IF USE_LEFT4ID <= 0 THEN 
		INSERT INTO MESSAGES(ORDER_ID, MESSAGE_CONTENT) VALUES(NEW.ORDER_ID, CONCAT(NEW.coupon_id, ' OUT OF VOUCHER'));
    END IF;

	RETURN NEW;
END;
$BODY$;


	
CREATE OR REPLACE TRIGGER max_use_trigger
    BEFORE INSERT
    ON coupon_order
    FOR EACH ROW
    EXECUTE FUNCTION update_max_use();
	

--update_audits_customers

CREATE OR REPLACE FUNCTION update_audits_customers()
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
BEGIN		
    IF (NEW.phone_number != OLD.phone_number) THEN
        INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME) 
        VALUES (OLD.customer_id, 'CUSTOMERS', 'UPDATE PHONE NUMBER', OLD.phone_number, NEW.phone_number, NOW());
    END IF;
	
	IF (NEW.gender != OLD.gender) THEN
        INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME) 
        VALUES (OLD.customer_id, 'CUSTOMERS', 'UPDATE PHONE NUMBER', OLD.gender, NEW.gender, NOW());
    END IF;

    RETURN NEW;
END;
$BODY$;

CREATE OR REPLACE TRIGGER update_audits_customers_trigger
    BEFORE UPDATE 
    ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_audits_customers();
	

--update_audit_item

CREATE OR REPLACE FUNCTION update_audit_item()
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
	IF (NEW.name != OLD.name) THEN
		INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME) VALUES (OLD.restaurant_id, 'ITEM_MENU', 'UPDATE ITEM NAME', OLD.name, NEW.name, NOW()); 
	END IF;
	IF (NEW.price != OLD.price) THEN 
		INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME) VALUES (OLD.restaurant_id, 'ITEM_MENU', 'UPDATE ITEM PRICE', OLD.PRICE, NEW.PRICE, NOW()); 
	END IF;
	IF (NEW.stock != OLD.stock) THEN 
		INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME) VALUES (OLD.restaurant_id, 'ITEM_MENU', 'UPDATE ITEM STOCK', OLD.stock, NEW.stock, NOW()); 
	END IF;
	RETURN NEW;
END;
  
$BODY$;


CREATE OR REPLACE TRIGGER update_audit_item_trigger
    BEFORE UPDATE 
    ON item_menu
    FOR EACH ROW
    EXECUTE FUNCTION update_audit_item();
	
	
--check_item_restaurant

CREATE OR REPLACE FUNCTION check_item_restaurant()
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Kiểm tra xem Item_id có thuộc nhà hàng đặt trong bảng orders không
    IF NOT EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.order_id = NEW.order_id
          AND EXISTS (
              SELECT 1
              FROM item_menu i
              WHERE i.item_id = NEW.item_id
                AND i.restaurant_id = o.restaurant_id
          )
    ) THEN
        -- Nếu không đáp ứng điều kiện, kích hoạt lỗi
        RAISE EXCEPTION 'Item_id does not belong to the restaurant in the order.';
    END IF;

    RETURN NEW;
END;
$BODY$;

	
CREATE OR REPLACE TRIGGER check_insert_order_detail
    BEFORE INSERT
    ON order_detail
    FOR EACH ROW
    EXECUTE FUNCTION check_item_restaurant();
	
	
--stock_left

CREATE OR REPLACE FUNCTION stock_left()
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE 
    QUAN INT;
    SL INT;
    FN CHAR(100);
BEGIN
    SELECT stock INTO SL
    FROM item_menu
    WHERE  item_menu.item_id=NEW.item_id ;
	
SELECT  item_menu.name into FN
    FROM item_menu
    WHERE  item_menu.item_id=NEW.item_id ;
   
   QUAN = NEW.quantity;
	
        IF NEW.quantity > SL THEN
            INSERT INTO MESSAGES(order_id, message_content) VALUES (NEW.order_id, CONCAT('Only ', SL, ' ', FN, ' left'));
            NEW.quantity := 0;
        ELSE
            UPDATE item_menu SET stock = stock - QUAN
            WHERE item_menu.item_id=NEW.item_id ;
        END IF;
    RETURN NEW;
END;
$BODY$;

CREATE OR REPLACE TRIGGER stock_left_trigger
    BEFORE INSERT
    ON order_detail
    FOR EACH ROW
    EXECUTE FUNCTION stock_left();
	
	
--update_cancel
CREATE OR REPLACE FUNCTION update_cancel()
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
BEGIN 
    IF NEW.status = 'CANCELED' AND OLD.status <> 'ORDERING' 
    THEN
        INSERT INTO MESSAGES(ORDER_ID, MESSAGE_CONTENT) VALUES (NEW.ORDER_ID, 'You cannot cancel this order!');
         RETURN NULL;
	END IF;
	
    IF NEW.status = 'CANCELED' AND OLD.status = 'ORDERING' 
    THEN
	  NEW.total_cost = 0;
          NEW.res_cost = 0;
          NEW.ship_cost = 0;
	END IF;
	RETURN NEW;	   
END;
$BODY$;

CREATE OR REPLACE TRIGGER update_cancel_trigger
    BEFORE UPDATE 
    ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_cancel();
	
	

--update_audit_res
CREATE OR REPLACE FUNCTION update_audit_res()
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    IF NEW.name_res IS DISTINCT FROM OLD.name_res THEN
        INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME)
        VALUES (OLD.restaurant_id, 'RESTAURANTS', 'UPDATE RES NAME', OLD.name_res, NEW.name_res, NOW());
    END IF;

    IF NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME)
        VALUES (OLD.restaurant_id, 'RESTAURANTS', 'UPDATE STATUS', OLD.status, NEW.status, NOW());
    END IF;

    IF NEW.open_time IS DISTINCT FROM OLD.open_time THEN
        INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME)
        VALUES (OLD.restaurant_id, 'RESTAURANTS', 'UPDATE OPEN HOUR', OLD.open_time, NEW.open_time, NOW());
    END IF;

    IF NEW.close_time IS DISTINCT FROM OLD.close_time THEN
        INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME)
        VALUES (OLD.restaurant_id, 'RESTAURANTS', 'UPDATE CLOSE HOUR', OLD.close_time, NEW.close_time, NOW());
    END IF;

    RETURN NEW;
END;
$BODY$;


CREATE OR REPLACE TRIGGER update_audit_res_trigger
    BEFORE UPDATE 
    ON restaurants
    FOR EACH ROW
    EXECUTE FUNCTION update_audit_res();


--add_rate_function

CREATE OR REPLACE FUNCTION add_rate_function()
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    SS FLOAT;
    RR FLOAT;
    ID_DRIVER CHAR(10);
    ID_RES CHAR(10);
BEGIN
    SELECT DRIVER_ID, RESTAURANT_ID INTO ID_DRIVER, ID_RES
    FROM FEEDBACK
    INNER JOIN ORDERS ON FEEDBACK.order_id = ORDERS.order_id
    WHERE ORDERS.ORDER_ID = NEW.ORDER_ID;

    -- Tính trung bình các đánh giá cho lái xe
    SELECT AVG(rate_driver) INTO SS 
    FROM FEEDBACK
    INNER JOIN ORDERS ON FEEDBACK.order_id = ORDERS.order_id
    WHERE ORDERS.DRIVER_ID = ID_DRIVER AND rate_driver IS NOT NULL;
    
    -- Tính trung bình các đánh giá cho nhà hàng
    SELECT AVG(rate_res) INTO RR 
    FROM FEEDBACK
    INNER JOIN ORDERS ON FEEDBACK.order_id = ORDERS.order_id
    WHERE ORDERS.RESTAURANT_ID = ID_RES AND rate_res IS NOT NULL;

    -- Cập nhật số sao cho lái xe
    UPDATE DRIVERS 
    SET rate = SS
    WHERE DRIVERS.DRIVER_ID = ID_DRIVER;
    
    -- Cập nhật số sao cho nhà hàng
    UPDATE RESTAURANTS
    SET RATE = RR
    WHERE RESTAURANTS.RESTAURANT_ID = ID_RES;

    RETURN NEW;
END;
$BODY$;

CREATE OR REPLACE TRIGGER add_rate
    AFTER INSERT
    ON feedback
    FOR EACH ROW
    EXECUTE FUNCTION add_rate_function();
