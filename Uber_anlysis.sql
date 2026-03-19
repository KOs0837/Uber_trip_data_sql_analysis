
------------------------Growth & Acquisition--------------------------
with main as (
Select 
to_char(created_at,'yyyy-mm') as created_at,
count(*) new_cust
from riders
group by 1
order by created_at)

Select main.*,
Lag(new_cust) over(order by created_at) as m_over_m,
new_cust-Lag(new_cust) over(order by created_at)
from main
--------------------------------------------------
---Which cities generate the most riders and drivers, and where are we underrepresented?
SELECT city, 
case when is_driver = 1 then 'Driver' else 'Rider' end as is_driver,
COUNT(*) N°
FROM users
Group by 1,2
ORDER BY is_driver, N°

---------------------------Revenue & Pricing-------------------------------
---What is our total revenue and average fare per trip? How much does surge pricing actually contribute?
SELECT Round(AVG(amount)::numeric,2) 
FROM payments
---
SELECT Round(sum(amount)::numeric,2) 
FROM payments
---Which payment methods are most used, and are there differences in average fare by payment type?
SELECT 
method,
count(*) as N°,
round(AVG(amount)::numeric,2) avg_price

from payments
group by 1
order by N°,avg_price
---------------------------Driver Performance-------------------------------

---Who are our top-performing drivers (rating,number of trips completed), and what share of drivers are currently inactive?
SELECT 
d.driver_id,
d.rating,
count(t.*) AS n_trips
FROM drivers AS d
left join trips AS t
ON d.driver_id = t.driver_id
Group by 1,2
order by rating desc, n_trips desc
limit 10
---% of inactive drivers
SELECT sum(case when is_active =0 then 1 else 0 end) n_inactive, 
round(sum(case when is_active =0 then 1 else 0 end)::numeric/count(*),2) "%_inactive"

from drivers

---Is there a correlation between a driver's vehicle age and their rating?
select
round(corr(extract(year from current_date)-vehicle_year,rating)::numeric,5)
from drivers
--------------------------- Rider Behavior--------------------------------
---What does the typical rider look like — how many trips have they taken, and what is their average rating?
SELECT 
round(count(trip_id)::numeric/count(distinct(r.rider_id)),2) avg_numb_trips,
round(avg(rating) ::numeric,2) average_rating
FROM riders r
LEFT JOIN trips t
	ON r.rider_id = t.rider_id
---Which riders haven't taken a trip in a long time — who are we at risk of losing?
with dd as (
select cast (max(started_at) as date) ddate 
	From trips
)---This will allow us to get the recent date in the dataset
Select 
t.rider_id,
dd.ddate,
cast (max(started_at) as date) last_trip,
dd.ddate-cast (max(started_at) as date) diff
from trips as t,dd
WHERE status = 'completed'
group by 1,2
order by diff desc


--------------------------- Operations & Zones--------------------------------
---Which pickup and dropoff zones are the busiest, and at what times of day?
select
l.zone_name ,
'dropoff' as type,
EXTRACT(hour FROM t.started_at) hour_,
count(t.trip_id) as n_trips
from trips as t
left join locations as l
ON t.dropoff_location_id = l.location_id 
WHERE t.status = 'completed'
group by 1,2,3

union all

select
l.zone_name ,
'pickup' as type,
EXTRACT(hour FROM t.started_at) hour_,
count(t.trip_id) as n_trips
from trips as t
left join locations as l
ON t.pickup_location_id = l.location_id 
WHERE t.status = 'completed'
group by 1,2,3
order by type desc,  n_trips desc

---What are the most popular origin-destination pairs (zone to zone)?
Select 
l.zone_name,
l2.zone_name,
count(trip_id) pair_desti_count
From trips t
Left join locations l
On t.pickup_location_id = l.location_id
Left join locations l2
On t.dropoff_location_id = l2.location_id
group by 1,2
order by pair_desti_count desc

