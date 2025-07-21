# Designing the Staging Layer for SaaS Payment Metrics (MRR & ARR)  

In modern data pipelines, ELT (Extract, Load, Transform) has become the standard. Tools like Snowflake, a cloud-based data warehouse, and dbt (data build tool), an open-source transformation tool, allow teams to model data in a clean, scalable, and modular way. Before diving into the specifics of the staging layer, it's important to understand the core philosophy behind dbt. At its heart, dbt is built on the principle of modular, layered transformations. Meaning, the data pipelines are clearly defined into stages: staging, intermediate, and mart layers.  

This modular structure ensures maintainability, compatibility, and scalability as an organization evolves. Whether the data volume increases, new team members join, or the use cases expand to include dashboards, reports, or machine learning models, having a well-layered transformation pipeline ensures things stay manageable and reliable. One might argue as to why not use sql stored procedures and a scheduler to achieve what dbt does, well there is a clear distinction that is explained in this video ![dbt vs stored procedures](https://www.youtube.com/watch?v=QwY5PpDP0iI&t=465s).  

This project focuses specifically on planning and implementing the staging layer, which is the first and most foundational layer, responsible for standardizing raw SaaS payment data in preparation for calculating core metrics like MRR and ARR.  

### 1. Determining the purpose of data transformation.  

It is crucial to understand how the data will be applied by the organization prior to applying any transformation functions. While the most common goal is to produce clean and consistent dashboards and reports for analysts, product managers, and decision-makers, that’s only one part of the picture. The way you design a staging layer should be directly shaped by the end goals of your transformation pipeline.  

For example, the approach may vary depending on whether the data is used for metric standardization across teams, enforcing data quality, reshaping historical data for cohort or retention analysis, or powering downstream tools like BI dashboards, machine learning models, or operational workflows. Each of these use cases influences the structure of staging models, from which fields you clean and how you name columns, to how you handle anomalies and maintain consistency across pipelines.  

For this project, the end goal is to enable metric standardization. Specifically, to develop consistent, accurate, and scalable organization-wide definitions of Monthly Recurring Revenue (MRR) and Annual Recurring Revenue (ARR).  

### 2. Understanding the Raw Data and Loading it into the Data Warehouse  

For this project, I used a publicly available dataset from Kaggle titled Customer Subscription Data, which contains four key tables:  

1. Customer product activity – capturing sign-up and cancellation dates at the product level
2. Call center activity – customer support interactions
3. Customer demographics – age, region, etc.
4. Product pricing info – plan names, billing cycles, and prices

Together, these tables represent the basic payment operations of a typical SaaS organization: a set of products or plans charged on a recurring basis, tied to customer activity logs with consistent signup and cancellation timestamps. This raw information is foundational for understanding where revenue is generated, where it's lost, and how it evolves over time — making metrics like MRR and ARR essential to tracking a SaaS company’s growth and forecasting performance.

I loaded these .csv files directly into Snowflake without applying any upfront cleaning. My goal was to keep all transformation logic centralized within dbt staging models, ensuring that any future data additions go through the same cleaning process and stay consistent and reproducible across the pipeline.

Before moving on to modeling, I spent time reviewing the raw data — inspecting column names, data types, nullability, unique identifiers, and sample values, while watching for formatting issues or inconsistent encoding. This initial review helps build a strong intuition for the data, which is crucial for designing effective staging logic downstream.  

### 3. Project Configuration and Planning  

Setting up a dbt project starts with a clean working environment. I began by creating a dedicated directory, setting up a virtual environment to install dbt, and connecting it to my Snowflake database. Version control is essential for collaboration and tracking changes over time, so Git was initialized from the start.

One of the key principles in dbt is structure. A modular and well-organized file system makes the project easier to maintain as it grows. Consistent naming conventions across folders, model files, and columns help avoid confusion, especially when multiple people are involved or when the project scales over time. Inside the models directory, I created a staging folder to house all models related to raw source cleaning. This aligns with dbt’s philosophy of keeping early transformation layers simple and reversible.

Configuration files are also a core part of dbt. The sources.yml file is where raw tables are registered—defining the database, schema, table names, and column-level metadata exactly as they exist in the warehouse. This creates a clear link between the transformation logic and the raw data. The schema.yml file complements this by defining model-level details such as renaming rules, column descriptions, and data quality tests like not_null and unique. These tests help catch issues early and keep assumptions about the data explicit.

In the staging layer itself, it’s considered best practice to maintain a one-to-one mapping between source tables and models. Rather than performing joins or aggregations, the staging layer focuses on light, modular transformations—renaming fields, fixing data types, handling formatting issues, and applying standard naming conventions. Keeping this layer minimal ensures that it’s easy to adapt when the raw data structure changes, and it also supports clarity when building more complex models later on.


