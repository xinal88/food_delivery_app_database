CREATE INDEX IF NOT EXISTS fki_fk_cus
    ON orders USING btree (customer_id) ;

CREATE INDEX IF NOT EXISTS fki_fk_res
    ON orders USING btree (restaurant_id);

CREATE INDEX IF NOT EXISTS index_order_driver
    ON orders USING btree (driver_id);
	
CREATE INDEX IF NOT EXISTS "fki_fk_order-coupon"
    ON coupon_order USING btree(coupon_id);

CREATE INDEX IF NOT EXISTS index_item_id_orderdetail
    ON order_detail USING btree(item_id );
