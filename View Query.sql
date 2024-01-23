----View customer_information
CREATE OR REPLACE VIEW customer_information
 AS
 SELECT cus.customer_id,
    cus.last_name,
    cus.first_name,
    cus.gender,
    cus.date_of_birth,
    cus.phone_number,
    concat(ad.city, ',', ad.district, ',', ad.street) AS address
   FROM customers cus
     JOIN customer_address ad USING (address_id);

-----View best_seller_restaurant
CREATE OR REPLACE VIEW best_seller_restaurant
 AS
 SELECT restaurant_id,
    name_res,
    name
   FROM ( SELECT r.restaurant_id,
            r.name_res,
            itm.name,
            sum(od.quantity) AS countf,
            rank() OVER (PARTITION BY r.restaurant_id ORDER BY (sum(od.quantity)) DESC) AS ranking
           FROM restaurants r
             JOIN item_menu itm ON itm.restaurant_id = r.restaurant_id
             JOIN order_detail od ON od.item_id = itm.item_id
          GROUP BY r.restaurant_id, itm.name) unnamed_subquery
  WHERE ranking = 1;

----- VIew bill
CREATE OR REPLACE VIEW bill
 AS
 SELECT o.order_id,
    r.name_res AS restaurant,
    string_agg(f.name::text, ', '::text) AS menu,
    concat(z.driname1, ' ', z.driname2) AS driver,
    concat(z.cusname1, ' ', z.cusname2) AS customer,
    o.total_cost AS total
   FROM orders o
     JOIN order_detail od ON od.order_id = o.order_id
     JOIN item_menu f ON f.item_id = od.item_id
     JOIN restaurants r ON r.restaurant_id = o.restaurant_id
     JOIN customers cus ON cus.customer_id = o.customer_id
     JOIN ( SELECT o_1.order_id AS od1,
            o_1.customer_id AS cusid,
            cus_1.first_name AS cusname1,
            cus_1.last_name AS cusname2,
            o_1.driver_id AS driid,
            d.first_name AS driname1,
            d.last_name AS driname2
           FROM orders o_1
             JOIN customers cus_1 ON o_1.customer_id = cus_1.customer_id
             JOIN drivers d ON o_1.driver_id = d.driver_id) z ON o.order_id = z.od1
  GROUP BY o.order_id, o.total_cost, r.name_res, (concat(z.driname1, ' ', z.driname2)), (concat(z.cusname1, ' ', z.cusname2));


----View highest_revenue_district
CREATE OR REPLACE VIEW highest_revenue_district
 AS
 SELECT restaurant_id,
    district,
    total_revenue,
    ranking
   FROM ( SELECT store_revenue.restaurant_id,
            store_revenue.district,
            store_revenue.total_revenue,
            rank() OVER (PARTITION BY store_revenue.district ORDER BY store_revenue.total_revenue DESC) AS ranking
           FROM ( SELECT r.restaurant_id,
                    r.district,
                    sum(o.res_cost) AS total_revenue
                   FROM restaurants r
                     JOIN orders o ON r.restaurant_id = o.restaurant_id
                  WHERE o.status = 'TAKEN'::bpchar
                  GROUP BY r.restaurant_id, r.district) store_revenue) unnamed_subquery
  WHERE ranking = 1;


----View highrate_res_district

CREATE OR REPLACE VIEW highrate_res_district
 AS
 SELECT restaurants.restaurant_id,
    restaurants.name_res,
    restaurants.rate,
    restaurants.district
   FROM restaurants
     JOIN ( SELECT r.district,
            max(r.rate) AS max_district
           FROM restaurants r
          GROUP BY r.district) s ON restaurants.district = s.district
  WHERE restaurants.rate = s.max_district;
