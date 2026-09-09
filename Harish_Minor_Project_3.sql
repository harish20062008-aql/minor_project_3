USE redflag;
SHOW TABLES;
-- ====================== table structure =====================
DESCRIBE transactions;
-- ====================== total transactions ======================
SELECT COUNT(*) AS total_transactions
FROM transactions;
-- ====================== limited transactions ======================
SELECT * FROM transactions
LIMIT 10;

-- ====================== transaction status ==========================
SELECT status, COUNT(*) AS total
FROM transactions
GROUP BY status;
-- ======================= payment method ===============================
SELECT payment_mode, COUNT(*) AS total
FROM transactions
GROUP BY payment_mode;
-- ======================== transaction type ==============================
SELECT txn_type, COUNT(*) AS total
FROM transactions
GROUP BY txn_type;
-- =========== total transaction in a city descending order =================
SELECT city, COUNT(*) AS total
FROM transactions
GROUP BY city
ORDER BY total DESC;
-- ===================== amount statistics ===================================
SELECT
    MIN(amount) AS minimum_amount,
    MAX(amount) AS maximum_amount,
    ROUND(AVG(amount), 2) AS average_amount
FROM transactions;

-- ==================== velocity fraud ============================
SELECT
    user_id,
    DATE(txn_time) AS transaction_date,
    COUNT(*) AS transaction_count
FROM transactions
GROUP BY user_id, DATE(txn_time)
ORDER BY transaction_count DESC
LIMIT 20;

-- ==================== round amount clustering ===========================
SELECT
    user_id,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_transaction_amount
FROM transactions
GROUP BY user_id
ORDER BY total_transactions DESC
LIMIT 20;

-- ======================== low Value transaction detection ===============================
SELECT
    txn_id,
    user_id,
    amount,
    txn_time,
    payment_mode,
    status
FROM transactions
ORDER BY amount ASC
LIMIT 30;

-- ======================== failed transaction analysis ===================================
SELECT
    user_id,
    COUNT(*) AS failed_transaction_count
FROM transactions
WHERE status = 'FAILED'
GROUP BY user_id
ORDER BY failed_transaction_count DESC
LIMIT 20;

-- ============================= odd hour activity ===================================
SELECT
    COUNT(*) AS total_rows,
    COUNT(txn_time) AS non_null_times,
    MIN(txn_time) AS first_time,
    MAX(txn_time) AS last_time
FROM transactions;

SELECT
    txn_time,
    HOUR(txn_time) AS transaction_hour
FROM transactions
LIMIT 20;

SELECT
    HOUR(txn_time) AS transaction_hour,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY HOUR(txn_time)
ORDER BY transaction_hour;

-- ================================ mule account detection ==================================
SELECT
    m1.merchant_id,
    m1.user_id,
    m1.transaction_count,
    ROUND(m1.total_amount, 2) AS total_amount,

    (
        SELECT COUNT(*)
        FROM
        (
            SELECT
                merchant_id,
                user_id,
                COUNT(*) AS transaction_count
            FROM transactions
            GROUP BY merchant_id, user_id
        ) AS m2
        WHERE m2.merchant_id = m1.merchant_id
          AND m2.transaction_count > m1.transaction_count
    ) + 1 AS user_rank

FROM
(
    SELECT
        merchant_id,
        user_id,
        COUNT(*) AS transaction_count,
        SUM(amount) AS total_amount
    FROM transactions
    GROUP BY merchant_id, user_id
) AS m1

WHERE
(
    SELECT COUNT(*)
    FROM
    (
        SELECT
            merchant_id,
            user_id,
            COUNT(*) AS transaction_count
        FROM transactions
        GROUP BY merchant_id, user_id
    ) AS m3
    WHERE m3.merchant_id = m1.merchant_id
      AND m3.transaction_count > m1.transaction_count
) < 3

ORDER BY
    m1.merchant_id,
    user_rank

LIMIT 50;

-- ========================= ₹9,999 Structuring =====================================
SELECT
    user_id,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount,
    ROUND(AVG(amount), 2) AS avg_amount,
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount
FROM transactions
WHERE amount BETWEEN 9900 AND 10100
GROUP BY user_id
HAVING COUNT(*) >= 2
ORDER BY transaction_count DESC, total_amount DESC;

-- ========================= Dormant Then ActiveDormant Then Active ======================
SELECT
    d.user_id,
    d.previous_txn_time,
    d.activity_start,
    d.inactive_days,
    COUNT(t.txn_id) AS transactions_after_gap
FROM
(
    SELECT
        t1.user_id,
        MAX(t2.txn_time) AS previous_txn_time,
        t1.txn_time AS activity_start,
        TIMESTAMPDIFF(
            DAY,
            MAX(t2.txn_time),
            t1.txn_time
        ) AS inactive_days
    FROM transactions t1
    JOIN transactions t2
        ON t1.user_id = t2.user_id
        AND t2.txn_time < t1.txn_time
    GROUP BY
        t1.user_id,
        t1.txn_time
    HAVING
        TIMESTAMPDIFF(
            DAY,
            MAX(t2.txn_time),
            t1.txn_time
        ) >= 90
) AS d
JOIN transactions t
    ON t.user_id = d.user_id
    AND t.txn_time >= d.activity_start
GROUP BY
    d.user_id,
    d.previous_txn_time,
    d.activity_start,
    d.inactive_days
HAVING COUNT(t.txn_id) >= 15
ORDER BY
    d.inactive_days DESC;

-- ============================= Velocity Spike =================================

SELECT
    user_statistics.user_id,

    ROUND(
        user_statistics.average_monthly_count,
        2
    ) AS average_monthly_count,

    user_statistics.peak_monthly_count,

    ROUND(
        user_statistics.peak_monthly_count /
        user_statistics.average_monthly_count,
        2
    ) AS spike_ratio

FROM
(
    SELECT
        monthly_transactions.user_id,

        AVG(
            monthly_transactions.monthly_transaction_count
        ) AS average_monthly_count,

        MAX(
            monthly_transactions.monthly_transaction_count
        ) AS peak_monthly_count

    FROM
    (
        SELECT
            user_id,
            DATE_FORMAT(txn_time, '%Y-%m') AS transaction_month,
            COUNT(*) AS monthly_transaction_count

        FROM transactions

        GROUP BY
            user_id,
            DATE_FORMAT(txn_time, '%Y-%m')
    ) AS monthly_transactions

    GROUP BY
        monthly_transactions.user_id

) AS user_statistics

WHERE
    user_statistics.peak_monthly_count >= 20

    AND user_statistics.peak_monthly_count >=
        5 * user_statistics.average_monthly_count

ORDER BY
    spike_ratio DESC;

-- =============================== Geographic Impossibility =======================
SELECT
    t1.user_id,
    t2.city AS previous_city,
    t1.city,
    t2.txn_time AS previous_txn_time,
    t1.txn_time,
    TIMESTAMPDIFF(
        MINUTE,
        t2.txn_time,
        t1.txn_time
    ) AS minutes_between
FROM transactions t1
JOIN transactions t2
    ON t1.user_id = t2.user_id
    AND t2.txn_time = (
        SELECT MAX(t3.txn_time)
        FROM transactions t3
        WHERE t3.user_id = t1.user_id
          AND t3.txn_time < t1.txn_time
    )
WHERE t1.city <> t2.city
ORDER BY minutes_between ASC
LIMIT 20;

-- ========================================================================================================
SELECT COUNT(*) AS total_transactions
FROM transactions;

-- =======================================================================================================
SELECT
    txn_type,
    COUNT(*) AS total
FROM transactions
GROUP BY txn_type;
-- ========================================================================================================
