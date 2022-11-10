# 1.1 How many users have interacted with the eCommerce website?

# SELECT Count(DISTINCT user_id) user_count
# FROM   `2019-oct`

# 1.2 How many products have been viewed by those users?
# by each user

# SELECT user_id,
#        Count(DISTINCT product_id) amount
# FROM   `2019-oct`
# WHERE  event_type = 'view'
# GROUP  BY user_id
# ORDER  BY amount DESC

# overall
# SELECT Count(DISTINCT product_id)
# FROM   `2019-oct`
# WHERE  event_type = 'view'


# 2 What were the top 5 most viewed products in October 2019?

# WITH temp1 AS
# (
#          SELECT   product_id ,
#                   Count(event_type) time_viewed
#          FROM     `2019-oct`
#          WHERE    event_type='view'
#          GROUP BY product_id), temp2 AS
# (
#          SELECT   * ,
#                   rank() OVER (ORDER BY time_viewed DESC ) TOP
#          FROM     temp1)
# SELECT *
# FROM   temp2
# WHERE  TOP<=5

# 3 On average, how many items were added to the cart?
# 3.1 By user

# WITH temp1 AS
# (
#          SELECT   user_id ,
#                   Count(event_type) cart
#          FROM     `2019-oct`
#          WHERE    event_type='cart'
#          GROUP BY user_id)
# SELECT avg(cart)
# FROM   temp1

# 3.2 By user session

# WITH temp1 AS
# (
#          SELECT   user_session ,
#                   Count(event_type) cart
#          FROM     `2019-oct`
#          WHERE    event_type='cart'
#          GROUP BY user_session)
# SELECT avg(cart)
# FROM   temp1

# 3.3 Looking at the results of parts 1 & 2 of Question N 3, what can you say about the average number of sessions per user?

# WITH temp AS
# (
#          SELECT   user_id ,
#                   Count(DISTINCT user_session) session_number
#          FROM     `2019-oct`
#          WHERE    event_type='cart'
#          GROUP BY 1)
# SELECT avg(session_number)
# FROM   temp

#the 3.3th is also equal to avg.user/avg.session. We also have written the version down below

# WITH counts AS
# (
#        SELECT Count(product_id)            prodnum ,
#               Count(DISTINCT user_id)      usernum ,
#               Count(DISTINCT user_session) sessionnum
#        FROM   `2019-oct`
#        WHERE  event_type = 'cart' )
# SELECT prodnum   /usernum                    avguser ,
#        prodnum   /sessionnum                 avgsession ,
#        sessionnum/usernum #it IS the same AS avguser/avgsession
# FROM   counts


# 4.1 How many DAU does the E-Commerce website have? Any peaks/troughs?

# WITH temp AS
# (
#          SELECT   Day(event_time) day_ ,
#                   user_id ,
#                   Count(DISTINCT event_type) type
#          FROM     `2019-oct`
#          GROUP BY 1,
#                   2)
# SELECT   day_ ,
#          count(user_id) dau
# FROM     temp
# WHERE    type=4
# GROUP BY day_

# 4.2 WAU

# WITH temp AS
# (
#          SELECT   Week(event_time) week_ ,
#                   user_id ,
#                   Count(DISTINCT event_type) type
#          FROM     `2019-oct`
#          GROUP BY 1,
#                   2)
# SELECT   week_ ,
#          count(user_id)
# FROM     temp
# WHERE    type=4
# GROUP BY week_

# 4.3 MAU

# WITH temp AS
# (
#          SELECT   Month(event_time) month_ ,
#                   user_id ,
#                   Count(DISTINCT event_type) type
#          FROM     `2019-oct`
#          GROUP BY 1,
#                   2)
# SELECT   month_ ,
#          count(user_id)
# FROM     temp
# WHERE    type=4
# GROUP BY month_

# 5.1 What is the Average Revenue Per User (ARPU)?
# 1st version

# WITH temp AS
# (
#          SELECT   user_id ,
#                   Sum(price) purchase
#          FROM     `2019-oct`
#          WHERE    event_type='purchase'
#          GROUP BY user_id)
# SELECT avg(purchase)
# FROM   temp

# 2nd version
# SELECT Sum(price) / Count(DISTINCT user_id) ARPU
# FROM   `2019-oct`
# WHERE  event_type = "purchase"


# 5.2 What is the Average Expected Revenue Per User?

# WITH temp1 AS
# (
#          SELECT   user_id ,
#                   Sum(price) overall
#          FROM     `2019-oct`
#          WHERE    event_type='cart'
#          GROUP BY user_id ) , temp2 AS
# (
#        SELECT o.user_id ,
#               sum(price)
#        minus
#                 ,
#                 overall
#        FROM     `2019-oct` o
#        JOIN     temp1 t
#        ON       o.user_id=t.user_id
#        WHERE    event_type='remove_from_cart'
#        GROUP BY user_id
#        ORDER BY user_id)
# SELECT avg(overall-
# minus
#        ) expected_income
#  FROM  temp2


# 6 What was the product which was added FIRST to the cart the most by each user?

# WITH temp1 AS
# (
#          SELECT   user_id ,
#                   product_id ,
#                   event_type ,
#                   event_time ,
#                   Row_number() OVER (partition BY user_id ORDER BY event_time) TOP
#          FROM     `2019-oct`
#          WHERE    event_type='cart') , temp2 AS
# (
#        SELECT *
#        FROM   temp1
#        WHERE  TOP=1) , temp3 AS
# (
#          SELECT   product_id ,
#                   sum(TOP)                           times_first ,
#                   rank() OVER (ORDER BY sum(TOP)DESC)top_rank
#          FROM     temp2
#          GROUP BY product_id)
# SELECT product_id
# FROM   temp3
# WHERE  top_rank =1

# 7 On average, how long do users stay on the website for each session?

# WITH temp AS
# (
#        SELECT user_session ,
#               Min(event_time) start ,
#               Max(event_time)
#      end
#      FROM `2019-oct` GROUP BY user_session )
# SELECT avg(timestampdiff(minute , start,
# END)) interval_
# FROM   temp


# 8 -------On average, how long do users take to visit the website again?-------------
# WITH sessions AS
# (
#          SELECT   user_id ,
#                   user_session ,
#                   event_time                                                          start_session ,
#                   Lead(event_time, 1) OVER (partition BY user_id ORDER BY event_time) next_session
#          FROM     `2019-oct`
#          GROUP BY 1,
#                   2 ) , final AS
# (
#        SELECT user_id ,
#               timestampdiff(hour , start_session , next_session) diff
#        FROM   sessions )
# SELECT avg(diff)
# FROM   final

#--- 9 categorize customers into different categories based on the time period it takes them to revisit the website?---

# WITH sessions AS
# (
#          SELECT   user_id ,
#                   user_session ,
#                   event_time                                                          start_session ,
#                   Lead(event_time, 1) OVER (partition BY user_id ORDER BY event_time) next_session
#          FROM     `2019-oct`
#          GROUP BY 1,
#                   2 ) , final AS
# (
#        SELECT user_id ,
#               timestampdiff(hour , start_session , next_session) diff
#        FROM   sessions )
# SELECT   user_id ,
#          CASE
#                   WHEN diff IS NULL THEN 'OneTimeVisit'
#                   WHEN diff >=0
#                   AND      diff <= 32 THEN 'Active Visiter'
#                   WHEN diff > 32 THEN 'Passive Visiter'
#          END AS _range
# FROM     final
# ORDER BY diff