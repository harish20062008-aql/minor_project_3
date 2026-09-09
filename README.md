# minor_project_3
RedFlag is an end-to-end SQL-based fraud detection engine built to identify anomalous behavior across 200,000+ financial transactions without relying on machine learning or external programming languages. The system uses pure MySQL constructs—including window functions, CTEs, correlated subqueries, time-series analysis, and conditional aggregation—to isolate 12 distinct financial fraud tactics commonly targeted in fintech.

Technical Modules & Detection Logic.

1.Velocity Fraud (Single-Day Bursts): Detects users performing excessive transactions in a single day by grouping records by user ID and date, filtering for days where transaction volume exceeds 30. 

2.Round Amount Clustering: Identifies deliberate usage of round figure transactions (e.g., 100, 500, 1000) by grouping user activity on exact round amounts to detect laundering or bot activity.  

3.Card Testing (Micro-Transactions): Flags automated card validation attempts by identifying rapid successions of micro-transactions under ₹10 per user within a single day.  

4.Failed Transaction Exploits: Isolates account brute-forcing or payment gateway abuse by identifying users accumulating 20 or more failed transactions.  

5.Odd-Hour Activity Analysis: Uncovers suspicious nocturnal operational patterns by extracting the hour component of payment timestamps and capturing spikes occurring strictly between 2 AM and 4 AM.  

6.Mule Account Tracking: Pinpoints intermediary accounts accumulating disproportionately high credit volumes through correlated subqueries that rank and compare merchant-user transaction frequencies.  

7.Refund Abuse Detection: Identifies accounts exploiting cash-back or refund mechanisms by applying conditional aggregation to flag users whose refund transaction volume exceeds 40% of their total activity.  

8.Merchant Collusion Analysis: Uncovers artificially inflated merchant numbers by running window ranking functions (ROW_NUMBER(), SUM() OVER()) to isolate instances where the top 5 users account for over 60% of a merchant's volume.  

9.Structuring & Anti-Money Laundering (AML): Catches users splitting large sums to bypass single-transaction threshold limits (such as ₹10,000) by querying repeated transactions clustered tightly between ₹9,900 and ₹10,100.  

10.Dormant-to-Active Reactivation: Detects compromised or hijacked accounts by executing self-joins with date-difference calculations (TIMESTAMPDIFF) to flag accounts inactive for over 90 days that suddenly perform 15+ rapid transactions.  

11.Velocity Spike Monitoring: Tracks long-term behavioral changes by calculating baseline monthly user averages against peak monthly counts, identifying anomalous spikes where a peak month exceeds 5 times the user's historical average.  

12.Geographic Impossibility (Impossible Travel): Highlights physical distance anomalies by computing time deltas between sequential transactions for a single user, flagging consecutive payments made in different cities within 60 minutes.  
