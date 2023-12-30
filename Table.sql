CREATE TABLE IF NOT EXISTS public.address
(
    address_id integer NOT NULL,
    city character(20) COLLATE pg_catalog."default",
    district character(20) COLLATE pg_catalog."default",
    street character(20) COLLATE pg_catalog."default",
    lat character(20) COLLATE pg_catalog."default",
    lo character(20) COLLATE pg_catalog."default",
    CONSTRAINT pk_address PRIMARY KEY (address_id)
)
;
CREATE TABLE IF NOT EXISTS public.coupons
(
    coupon_id character(15) COLLATE pg_catalog."default" NOT NULL,
    discountvalue integer,
    max_usage integer,
    start_date date,
    expire_date date,
    CONSTRAINT coupons_pkey PRIMARY KEY (coupon_id)
)

;

CREATE TABLE IF NOT EXISTS public.customers
(
    customer_id character(10) COLLATE pg_catalog."default" NOT NULL,
    first_name character(50) COLLATE pg_catalog."default",
    last_name character(50) COLLATE pg_catalog."default",
    gender character(15) COLLATE pg_catalog."default",
    date_of_birth date,
    phone_number character(20) COLLATE pg_catalog."default",
    address_id character(5) COLLATE pg_catalog."default",
    CONSTRAINT customers_pkey PRIMARY KEY (customer_id)
)

;

CREATE TABLE IF NOT EXISTS public.drivers
(
    driver_id character(10) COLLATE pg_catalog."default" NOT NULL,
    first_name character(50) COLLATE pg_catalog."default",
    last_name character(50) COLLATE pg_catalog."default",
    phone_number character(15) COLLATE pg_catalog."default",
    number_plate character(15) COLLATE pg_catalog."default",
    rate numeric(2,1),
    CONSTRAINT drivers_pkey PRIMARY KEY (driver_id)
)
;

CREATE TABLE IF NOT EXISTS public.restaurants
(
    restaurant_id character(10) COLLATE pg_catalog."default" NOT NULL,
    name_res character(50) COLLATE pg_catalog."default",
    address_id integer,
    phone_number character(12) COLLATE pg_catalog."default",
    rate numeric(2,1),
    status character(10) COLLATE pg_catalog."default",
    open_time time without time zone,
    close_time time without time zone,
    CONSTRAINT restaurants_pkey PRIMARY KEY (restaurant_id)
)

;

CREATE TABLE IF NOT EXISTS public.orders
(
    order_id character(15) COLLATE pg_catalog."default" NOT NULL,
    customer_id character(15) COLLATE pg_catalog."default",
    driver_id character(15) COLLATE pg_catalog."default",
    restaurant_id character(15) COLLATE pg_catalog."default",
    time_order timestamp with time zone,
    status character(15) COLLATE pg_catalog."default",
    location_ship integer,
    " payment" character(15) COLLATE pg_catalog."default",
    note character(20) COLLATE pg_catalog."default",
    total_cost numeric(5,1),
    "rate_restẩunt" numeric(2,1),
    rate_driver numeric(2,1),
    CONSTRAINT orders_pkey PRIMARY KEY (order_id),
    CONSTRAINT fk_address FOREIGN KEY (location_ship)
        REFERENCES public.address (address_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    CONSTRAINT fk_cus FOREIGN KEY (customer_id)
        REFERENCES public.customers (customer_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    CONSTRAINT fk_driver FOREIGN KEY (driver_id)
        REFERENCES public.drivers (driver_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    CONSTRAINT fk_res FOREIGN KEY (restaurant_id)
        REFERENCES public.restaurants (restaurant_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
)
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.orders
    OWNER to postgres;
-- Index: fki_fk_address

-- DROP INDEX IF EXISTS public.fki_fk_address;

CREATE INDEX IF NOT EXISTS fki_fk_address
    ON public.orders USING btree
    (location_ship ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: fki_fk_cus

-- DROP INDEX IF EXISTS public.fki_fk_cus;

CREATE INDEX IF NOT EXISTS fki_fk_cus
    ON public.orders USING btree
    (customer_id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: fki_fk_driver

-- DROP INDEX IF EXISTS public.fki_fk_driver;

CREATE INDEX IF NOT EXISTS fki_fk_driver
    ON public.orders USING btree
    (driver_id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: fki_fk_res

-- DROP INDEX IF EXISTS public.fki_fk_res;

CREATE INDEX IF NOT EXISTS fki_fk_res
    ON public.orders USING btree
    (restaurant_id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

-- Trigger: update_location

-- DROP TRIGGER IF EXISTS update_location ON public.orders;


CREATE TABLE IF NOT EXISTS public.item_menu
(
    restaurant_id character(10) COLLATE pg_catalog."default" NOT NULL,
    item_id integer NOT NULL,
    name character(100) COLLATE pg_catalog."default",
    price money,
    stock integer,
    CONSTRAINT item_menu_pkey PRIMARY KEY (restaurant_id, item_id)
)
;

CREATE TABLE IF NOT EXISTS public.order_detail
(
    order_id character(15) COLLATE pg_catalog."default" NOT NULL,
    item_id integer NOT NULL,
    quantity integer,
    CONSTRAINT pkorddetail PRIMARY KEY (order_id, item_id)
)

;

CREATE TABLE IF NOT EXISTS public.coupon_order
(
    order_id character(10) COLLATE pg_catalog."default" NOT NULL,
    coupon_id character(10) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT coupon_orderdetail_pkey PRIMARY KEY (order_id, coupon_id),
    CONSTRAINT "fk_coupon-coupon" FOREIGN KEY (coupon_id)
        REFERENCES public.coupons (coupon_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    CONSTRAINT "fk_order-coupon" FOREIGN KEY (order_id)
        REFERENCES public.orders (order_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.coupon_order
    OWNER to postgres;
-- Index: fki_fk_order-coupon

-- DROP INDEX IF EXISTS public."fki_fk_order-coupon";

CREATE INDEX IF NOT EXISTS "fki_fk_order-coupon"
    ON public.coupon_order USING btree
    (coupon_id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;


CREATE TABLE IF NOT EXISTS public.feedback
(
    feedback_id character(10) COLLATE pg_catalog."default" NOT NULL,
    order_id character(10) COLLATE pg_catalog."default",
    fcontent character(50) COLLATE pg_catalog."default",
    CONSTRAINT feedback_pkey PRIMARY KEY (feedback_id),
    CONSTRAINT feedback_order_id_fkey FOREIGN KEY (order_id)
        REFERENCES public.orders (order_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE TABLE AUDIT (
    AUDIT_ID SERIAL PRIMARY KEY,
    CHANGED_TABLE CHAR(20) NOT NULL,
    ID CHAR(10) NOT NULL,
    FIELD1 CHAR(30) NOT NULL,
    OLD_DATA CHAR(30) DEFAULT NULL,
    NEW_DATA CHAR(30) DEFAULT NULL,
    ACTION_TIME TIMESTAMPTZ NOT NULL
);
