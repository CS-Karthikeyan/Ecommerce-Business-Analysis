# Ecommerce Business Analytics project

## Description

This project aims to support the Analytics team at an E-Commerce company in generating valuable insights from data analytics. Additionally, it focuses on developing tailored dashboards for various audiences, including senior business leaders and on-ground sales teams. These insights and dashboards enable senior leaders to monitor key performance indicators, track business trends over time, and analyze performance against budget. For the sales team, these tools help identify key business drivers and develop strategies to enhance sales and overall business performance.

## Data source

The data is sourced from an e-commerce company.

## Tools Employed

- **MsSQL** for database management and querying
- **Python** for data processing and analysis
    - **Pandas** for data manipulation and analysis
    - **Matplotlib** and **Seaborn** for creating detailed data visualizations
- **PowerBI** for interactive visualizations and dashboards

## Data Understanding

- Before analysis, the data was thoroughly examined and understood. The data is provided in the form of Excel tables, spread across five workbooks:
    1. **FACT_InternetSales**
    2. **DIM_Customer**
    3. **DIM_Product**
    4. **DIM_Calendar**
    5. **SalesBudget**
- The sales data spans from January 2019 to January 2021, while the budget data covers the period from January 2020 to June 2021.

## Table-wise Data Understanding

### FACT_InternetSales Table

- This table contains information about all transactions that occurred on the marketplace.
- It includes a total of 58,168 records/transactions.
- Each row/record in the table contains the following information spread across seven columns:
    1. **OrderDateKey**: The key associated with the order date of the transaction, referencing the DateKey in the date table.
    2. **DueDateKey**: The key associated with the due date for the order.
    3. **ShipDateKey**: The shipping date key of an order.
    4. **CustomerKey**: The identifier for the customer of each transaction, referencing CustomerKey in the Customers table.
    5. **ProductKey**: The identifier for the product associated with each transaction, referencing the ProductKey from the products table.
    6. **SalesOrderNumber**: The order number for each transaction.
    7. **SalesAmount**: The sale amount associated with each transaction.
- The total number of transactions and distinct transactions differ due to duplicate SaleOrderNumbers. Different products purchased by a single customer on the same day are recorded as separate transactions under the same SaleOrderNumber.

### DIM_Customer Table

- This table contains demographic details of all customers on the marketplace.
- Each customer is uniquely identified by a CustomerKey.
- The demographic information includes First Name, Last Name, Full Name, Gender, and Customer City.
- The table contains a total of 18,484 unique records.

### DIM_Product Table

- The DIM_Product table contains all the information related to products.
- Each row describes the details and characteristics of a unique product.
- Each product is identified by a unique ProductKey, with 606 unique products available on the marketplace.
- The product data is categorized at three levels:
    - Product_Category
    - Sub_Category
    - Product_Name
- The table includes a Product Status column indicating the active or inactive status of each product.
- Other data in the product table includes Product Color, Product Size, Product Line, Product Model Name, and Product Description.
- The table contains null values in multiple columns, represented by the string ‘Null’.

### DIM_Calendar Table

- The DIM_Calendar is a date table containing all dates and related information within the data range of the FACT_InternetSales table.
- This table includes the DateKey column as a primary key, connecting with the InternetSales and SalesBudget tables through this key.

### SalesBudget Table

- The SalesBudget table contains monthly sales budget information.
- Budget data is available from January 2020 to June 2021.

## Analysis Approach

- The analysis is conducted in 3 stages outlined as follows:
    1. **Data Cleaning**: Preparing and cleaning the data for analysis.
    2. **Independent Analysis**: Analyzing sales, customer, and product tables separately.
    3. **Combined Analysis**: Conducting integrated analyses, such as sales vs. budget, sales vs. customer, sales vs. product, and sales vs. customer-product.
- Similar analyses were performed using both SQL and Python.
- In Python, data handling was done using Pandas, while visualizations were created using Matplotlib and Seaborn to enhance understanding.
- Visualizations and dashboards were developed in PowerBI, utilizing time intelligence and filter functions for better insights.
- The complete analysis was carried out in the local repository, and the files were then pushed to the remote repository using Git commands (add, commit, and push).

## Insights

### Sales

- **Total Unique Transactions**: There were a total of 25,429 unique transactions recorded.
- **Total Sales Amount**: The cumulative sales amount for the period was $22.23 million.
- **Yearly Sales Trends**: Sales were observed across two full years (2019 and 2020), with the highest sales recorded in 2020.
- **Monthly Sales Analysis**: December 2020 saw the highest sales, and the period from December 2019 to February 2020 showed the most significant improvement in sales amount.

### Budget

- **Total Sales Budget:** Total Sales Budget for the year 2020 is 15.3 Million$. For 2019 there is no budget allocation.
- **Budget and Sales Relationship**: The total sales amount generated across months was nearly equivalent to the sales budget.

### Customers

- **Customer Behavior Analysis**: Out of 18,484 total customers, 262 never made a purchase since 2019. Additionally, 287 customers who made purchases in 2019 did not visit the marketplace in 2020.
- **Gender Analysis**: The marketplace has an almost equal gender distribution (Female - 49.4%, Male - 50.6%), with a nearly equal distribution of total sales amount between genders.
- **Geographical Analysis**: Customers are present in 269 cities globally, with one city showing no purchases since 2019.
- **New Customer Analysis**: In 2020, there were 14,461 new customers who made their first purchase.

### Products

- **Product Category Analysis**: Among the 606 products, three categories are active, while no purchases were recorded in the "components" category.
- **Product Purchase Patterns**: Out of 606 products, 473 were never purchased. Among these, 304 are still non-outdated products.
- **Top-Selling Category**: The "bikes" category contributed significantly, accounting for 95.3% of the total sales amount.

### Sales-Customer-Product Insights

- **Gender-Based Purchase Patterns**: Both genders showed similar purchasing patterns across different categories and sub-categories, except for slight differences in the Clothing category.

**Note**: For Detailed insights please visit the code and visualizations document.
