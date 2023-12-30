--Update users information 
CREATE OR REPLACE FUNCTION update_customers()
RETURNS TRIGGER AS $$
BEGIN		
    IF (NEW.phone_number != OLD.phone_number) THEN
        INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME) 
        VALUES (OLD.customer_id, 'USERS', 'UPDATE PHONE NUMBER', OLD.phone_number, NEW.phone_number, NOW());
    END IF;

    IF (NEW.customer_address1 != OLD.customer_address1) THEN
        INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME) 
        VALUES (OLD.customer_id, 'USERS', 'UPDATE MAIN ADDRESS', OLD.customer_address1, NEW.customer_address1, NOW());
    END IF;

    IF (NEW.customer_address2 != OLD.customer_address2) THEN
        INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME) 
        VALUES (OLD.customer_id, 'USERS', 'UPDATE SUPPLEMENTARY ADDRESS', OLD.customer_address2, NEW.customer_address2, NOW());
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_customers_trigger
BEFORE UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION update_customers();

-- Update items in menu
CREATE OR REPLACE FUNCTION update_foods()
RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.name != OLD.name) THEN
		INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME) VALUES (OLD.restaurant_id, 'FOOD', 'UPDATE FOOD NAME', OLD.name, NEW.name, NOW()); 
	END IF;
	IF (NEW.price != OLD.price) THEN 
		INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME) VALUES (OLD.restaurant_id, 'FOOD', 'UPDATE FOOD PRICE', OLD.PRICE, NEW.PRICE, NOW()); 
	END IF;
	IF (NEW.stock != OLD.stock) THEN 
		INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME) VALUES (OLD.restaurant_id, 'FOOD', 'UPDATE FOOD STOCK', OLD.stock, NEW.stock, NOW()); 
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_foods_trigger
BEFORE UPDATE ON item_menu
FOR EACH ROW
EXECUTE FUNCTION update_foods();

-- Update audit payment method
CREATE OR REPLACE FUNCTION update_audit_payments()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.payment IS DISTINCT FROM OLD.payment THEN
        INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME)
        VALUES (OLD.order_id, 'ORDERS', 'UPDATE PAYMENT', OLD.payment, NEW.payment, NOW());
    END IF;

    IF NEW.total_cost IS DISTINCT FROM OLD.total_cost THEN
        INSERT INTO AUDIT(ID, CHANGED_TABLE, FIELD1, OLD_DATA, NEW_DATA, ACTION_TIME)
        VALUES (OLD.order_id, 'ORDERS', 'UPDATE TOTAL PRICE', OLD.total_cost, NEW.total_cost, NOW());
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_audit_payments_trigger
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_audit_payments();

-- Update restaurant information
CREATE OR REPLACE FUNCTION update_audit_res()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_audit_res_trigger
BEFORE UPDATE ON RESTAURANTS
FOR EACH ROW
EXECUTE FUNCTION update_audit_res();

--
DROP TRIGGER IF EXISTS update_cancel_trigger ON orders;

--Update cancel
CREATE OR REPLACE FUNCTION update_cancel()
RETURNS TRIGGER AS $$
BEGIN 
	IF NEW.status = 'CANCELED' THEN
		IF OLD.status = 'ORDERING' THEN
			UPDATE orders 
			SET total_cost = 0, rate_restaurant = 0, total_price = 0
			WHERE id_order = NEW.id_order; -- Make sure to specify the correct primary key column
		ELSE
			INSERT INTO MESSAGES(ID_ORDER, MESSAGE) VALUES (NEW.ID_ORDER, 'You cannot cancel this order!');
			RETURN NULL; -- Cancel the update
		END IF;
	END IF;
		
	IF OLD.status = 'ORDERING' THEN
		IF NOW() - OLD.time_order > INTERVAL '20 minutes' THEN
			UPDATE orders
			SET total_cost = 0, rate_restaurant = 0, total_price = 0
			WHERE id_order = NEW.id_order; -- Make sure to specify the correct primary key column
			INSERT INTO MESSAGES(ID_ORDER, MESSAGE) VALUES (NEW.ID_ORDER, 'Your order is over 20 minutes. So we cancel this order. Thank you!');
		END IF;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_cancel_trigger
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_cancel();

-- Add price into order_detail
CREATE OR REPLACE FUNCTION add_price_od()
RETURNS TRIGGER AS $$
DECLARE 
    P MONEY;
BEGIN
    SELECT price INTO P FROM item_menu 
    WHERE NEW.item_id = item_menu.item_id;

    IF FOUND THEN
        NEW.price := NEW.quantity * P;
    ELSE
        -- Handle the case where item_id is not found in item_menu
        RAISE EXCEPTION 'Item not found in item_menu for item_id: %', NEW.item_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER add_price_od_trigger
BEFORE INSERT ON order_detail
FOR EACH ROW
EXECUTE FUNCTION add_price_od();

-- Check stock left
CREATE OR REPLACE FUNCTION stock_left()
RETURNS TRIGGER AS $$
DECLARE 
    QUAN INT;
    SL INT;
    FN CHAR(50);
BEGIN
    SELECT stock INTO SL
    FROM item_menu
    WHERE NEW.item_id = item_menu.item_id;

    IF FOUND THEN
        QUAN := NEW.quantity;

        IF NEW.quantity > SL THEN
            INSERT INTO MESSAGES(ID_ORDER, MESSAGE) VALUES (NEW.order_id, CONCAT('Only ', SL, ' ', FN, ' left'));
            SET NEW.quantity = 0;
        ELSE
            UPDATE item_menu SET stock = stock - QUAN
            WHERE NEW.item_id = item_menu.item_id;
        END IF;
    ELSE
        -- Handle the case where item_id is not found in item_menu
        RAISE EXCEPTION 'Item not found in item_menu for item_id: %', NEW.item_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER stock_left_trigger
BEFORE INSERT ON order_detail
FOR EACH ROW
EXECUTE FUNCTION stock_left();

-- Max use for vouchers
CREATE OR REPLACE FUNCTION update_max_use()
RETURNS TRIGGER AS $$
DECLARE 
	USE_LEFT4ID INT;
BEGIN
	UPDATE coupons SET MAX_USE = MAX_USE - 1 WHERE coupon_id = NEW.coupon_id;

	SELECT MAX_USE INTO USE_LEFT4ID FROM coupons WHERE coupon_id = NEW.coupon_id LIMIT 1;

	IF USE_LEFT4ID <= 0 THEN 
		UPDATE coupons SET discountvalue = 0 WHERE coupon_id = NEW.coupon_id; 
	END IF;
	
	IF USE_LEFT4ID <= 0 THEN 
		INSERT INTO MESSAGES(ID_ORDER, MESSAGE) VALUES(NEW.ID_ORDER, CONCAT(NEW.coupon_id, ' OUT OF VOUCHER'));
    END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER max_use_trigger
BEFORE INSERT ON coupon_order
FOR EACH ROW
EXECUTE FUNCTION update_max_use();
