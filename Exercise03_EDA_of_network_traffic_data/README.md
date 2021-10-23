Analyze and report on honeypot data contained in marx-geo.tar.gz.

Rows summarize network packets (captured with iptables) for honeypots running from March to September, 2013.
Column descriptions:

    datetime: time packets were captured
    host: hostname for honeypot (destination)
    src: source IP (as integer)
    srcstr: source IP (as string)
    spt: source port
    dpt: destination port (on the host)
    proto: network protocol
    type: type code field
    country: country of source
    cc: short country code
    locale, localeabbr, postalcode, latitude, longitude: additional geolocale details (based on source IP)

Tasks:

    Load and clean the data
        Ensure consistent rows and columns
        Handle missing values
    Perform Exploratory Data Analysis
        Do any distributional or other trends pop out?
        What features are most interesting about this data?
        How would you summarize the dataset overall?
    Business questions
        Which areas of the network see higher volume of traffic?
        Is traffic primarily internal or external?
        Which countries/origins are most likely running scans against our networks?
    Data storytelling and next steps
        How would you frame this dataset for a tech business running in the cloud?
        What are some initial takeaways?
        What would you suggest for further investigation and analysis?

Rules and Deliverables

    Use Python for data processing and analysis
    Add your Python code (notebook and/or modules) to the git repository
    Prepare a presentation that is accessible to a general (non-data) audience - we want the code to see how you solve the problem, but the end result should not require reading the code to understand it

