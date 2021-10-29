## Task

You are provided with several years worth of Bitcoin stock data.
Create an ETL application that reads these files from a directory, parses them, and inserts them into a single table in a database.

The dataset contains 3286 CSV files split by date. They all share the same format:
- A time column, which denotes the time within a day
- Open, Close, High, Low price columns
- The volume of BTC and the volume of USD transacted inside the time window
- The Volume-Weighted Average Price (VWAP)
	
Technical spec:
- The date and time should be combined into a single column
- The application should be able to execute incrementally, i.e. it automatically detects which files are new and inserts only those
- New files always arrive chronologically
- No data loss should be possible
	
You are allowed to use
- any programming language
- any database server
