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

Moreover, configuration files are also a core part of dbt. The sources.yml file is where raw tables are registered—defining the database, schema, table names, and column-level metadata exactly as they exist in the warehouse. This creates a clear link between the transformation logic and the raw data. The schema.yml file complements this by defining model-level details such as renaming rules, column descriptions, and data quality tests like not_null and unique. These tests help catch issues early and keep assumptions about the data explicit.

Additionally, in the staging layer itself, it’s considered best practice to maintain a one-to-one mapping between source tables and models. Rather than performing joins or aggregations, the staging layer focuses on light, modular transformations—renaming fields, fixing data types, handling formatting issues, and applying standard naming conventions. Keeping this layer minimal ensures that it’s easy to adapt when the raw data structure changes, and it also supports clarity when building more complex models later on.  

### 4. Transformation Planning: Designing with Upstream and Downstream Awareness  

When designing the staging layer, it’s important to think beyond the immediate task of cleaning data. A well-structured transformation pipeline requires awareness of both upstream volatility and downstream fragility the two factors that shape how resilient and scalable your models will be over time.

On the upstream side, it’s worth assessing how likely the raw source tables are to change. In this case, while the volume of the SaaS data is expected to grow, the schema itself is relatively stable and we’re unlikely to see sudden shifts in column names or table structure. That reduces the risk of unexpected breakages from the data source.

Downstream, however, the dependencies are extensive. Since MRR and ARR are core business metrics, they power multiple dashboards and reports, and are often accessed at various levels - by product, customer, region, or billing cycle. This makes the staging layer a critical foundation, and any inconsistencies here could ripple through the entire analytics stack.

To design a stable and reusable staging layer that meets these needs, I focused on four key principles:

![Materialization Type](https://docs.getdbt.com/docs/build/materializations)
For performance and reliability, I used table materialization. This ensures staging models are persisted in the warehouse and can be read efficiently across many downstream queries. Views are avoided as they recalculate on every run, and incremental materialization is skipped for now since the data doesn’t support row-based updates or changelogs.

Rigorous Standardization
All transformations, i.e. renaming, casting, formatting, and null handling are applied in a consistent, deterministic way. The staging layer acts as the single source of formatting truth, ensuring downstream models don’t have to reapply the same logic. This simplifies maintenance and supports cleaner business logic.

Test Coverage and Logic Consolidation
While dbt’s built-in tests like not_null and unique are applied where relevant, I also incorporated composite boolean columns using CASE statements to pre-encode business logic in the staging layer. These derived flags simplify operations in later models, reducing the need for repetitive conditional logic downstream.

Backward Compatibility
To preserve trust across all downstream layers, I avoid changing column names, types, or logic within the staging models without clear versioning or documentation. The staging layer is treated as an interface contract and stability here ensures that all dependent models and dashboards remain functional and consistent.

By planning with both the source data structure and the reporting needs in mind, the staging layer becomes a reliable interface and not just a cleanup step, but a well-defined starting point for building confident and scalable data models. Again, the design of the staging layer will always depend on the nature of upstream and downstream dependencies, whether the source is volatile or the downstream models are complex and widely used. Accounting for these dynamics early helps prevent costly rework later on.  

### 5. Building the Staging Model
   
Once the planning is in place, writing the model becomes a more of a following the blueprint task. However, the goal at this stage is to ensure the code is readable, explainable, and easy to maintain over time.

I use Common Table Expressions (CTEs) extensively to break down the logic into clean, modular steps. This makes it easier to understand each transformation in isolation and simplifies debugging or future updates. Additionally, wherever a transformation is applied, such as renaming a column, casting a data type, or filtering records, I include in-line comments to explain the reasoning behind the change. These comments provide context for anyone revisiting the model and are especially helpful when onboarding new team members.

Moreover, documentation plays a central role in model building. I include a table-level description that aligns the model with its business context, making it easier for both technical and non-technical stakeholders to understand its purpose. At the column level, I add clear descriptions to explain the role of each field, including any transformations or assumptions. It is equally important to reference decisions around testing, such as why certain fields require uniqueness or what values are considered valid. These details help preserve clarity as the model evolves.

In parallel, I follow disciplined version control practices. Before writing any model logic, I commit the completed schema planning to Git. As development progresses, I track changes through dedicated branches, isolate updates into clear pull requests, and write meaningful commit messages. This ensures that model iterations are easy to follow and reduces the risk of errors in collaborative settings.

Writing a model in dbt is not just about transforming data. It is about building a transparent, reliable foundation that others can trust and build on. With clean SQL, strong documentation, and version control in place, the staging layer becomes more than just a technical step. It becomes a cornerstone of data consistency and collaboration.




