	
CREATE TABLE customers
(
    customer_id character(10) ,
    first_name character(50),
    last_name character(50) ,
    gender character(15) ,
    date_of_birth date,
    phone_number character(20) ,
    city character(20) ,
    district character(20) ,
    street character(20) ,
    lo double precision,
    lat double precision,
    CONSTRAINT customers_pkey PRIMARY KEY (customer_id)
)
;
 
CREATE TABLE drivers
(
    driver_id character(10),
    first_name character(50) ,
    last_name character(50) ,
    phone_number character(15) ,
    number_plate character(15),
    rate numeric(2,1),
    CONSTRAINT drivers_pkey PRIMARY KEY (driver_id)
)

;

CREATE TABLE restaurants
(
    restaurant_id character(10) ,
    name_res character(50) ,
    phone_number character(12) ,
    rate numeric(2,1),
    status character(10) ,
    open_time time ,
    close_time time ,
    city character(20) ,
    district character(20),
    street character(20) ,
    lat double precision,
    lo double precision,
    CONSTRAINT restaurants_pkey PRIMARY KEY (restaurant_id)
)

;


CREATE TABLE orders
(
    order_id character(15) ,
    customer_id character(15) ,
    driver_id character(15) ,
    restaurant_id character(15) ,
    time_order timestamp with time zone,
    status character(15) ,
    location_ship integer,
    note character(20) ,
    res_cost money,
    ship_cost money,
    total_cost money,
    payment_method character(10) ,
    CONSTRAINT orders_pkey PRIMARY KEY (order_id),
    CONSTRAINT fk_cus FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id),
    CONSTRAINT fk_driver FOREIGN KEY (driver_id)
        REFERENCES drivers (driver_id) ,
    CONSTRAINT fk_res FOREIGN KEY (restaurant_id)
        REFERENCES restaurants (restaurant_id) ,
    CONSTRAINT check_status CHECK (status IN ('ORDERING', 'DELIVERING','PREPARING', 'TAKEN', 'CANCELED'))
)
;

CREATE TABLE item_menu
(
    restaurant_id character(10) ,
    item_id integer,
    name character(100) ,
    price money,
    stock integer,
    CONSTRAINT pk_item_menu PRIMARY KEY (item_id),
    CONSTRAINT fgitem_res FOREIGN KEY (restaurant_id)
        REFERENCES restaurants (restaurant_id)
)
;

CREATE TABLE order_detail
(
    order_id character(15) ,
    item_id integer ,
    quantity integer,
    CONSTRAINT pk_order_detail PRIMARY KEY (order_id, item_id),
    CONSTRAINT fk_order_detail FOREIGN KEY (order_id)
        REFERENCES orders (order_id) ,
    CONSTRAINT fk_order_detail_item FOREIGN KEY (item_id)
        REFERENCES item_menu (item_id) 
)

;

CREATE TABLE coupons
(
    coupon_id character(15) ,
    discountvalue integer,
    max_usage integer,
    CONSTRAINT coupons_pkey PRIMARY KEY (coupon_id)
)

;


CREATE TABLE coupon_order
(
    order_id character(10) ,
    coupon_id character(10) ,
    CONSTRAINT coupon_orderdetail_pkey PRIMARY KEY (order_id, coupon_id),
    CONSTRAINT "fk_coupon-coupon" FOREIGN KEY (coupon_id)
        REFERENCES coupons(coupon_id) ,
    CONSTRAINT fk_coupon_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id) 
)

;

CREATE TABLE feedback
(
    order_id character(10) ,
    fcontent character(50) ,
    rate_res numeric(2,1),
    rate_driver numeric(2,1),
    CONSTRAINT pk_feedback PRIMARY KEY (order_id),
    CONSTRAINT feedback_order_id_fkey FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
)

;



CREATE TABLE messages
(
    ID_MES serial,
       ORDER_ID char(10),
  message_content char(300),
    CONSTRAINT fk_order FOREIGN KEY (order_id) REFERENCES orders (order_id) 
)
;

CREATE TABLE audit
(
    audit_id serial,
    changed_table character(20) ,
    id character(10) ,
    field1 character(30) ,
    old_data character(30) ,
    new_data character(30) ,
    action_time timestamp with time zone NOT NULL
)

;