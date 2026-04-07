---
layout: post
title: "Optimizing PostgreSQL Queries: From 2 Seconds to 20ms"
date: 2025-01-15
last_modified_at: 2025-02-01
description: "A deep dive into PostgreSQL query optimization."
image: /assets/img/posts/pg-optimization.jpg
author: Eugene Leontev
tags: [postgresql, query-optimization, database-performance]
categories: [engineering]
topics:
  - PostgreSQL
  - Query Optimization
faq:
  - question: "How much can query optimization improve performance?"
    answer: "In our case, we achieved a 100x improvement."
  - question: "When should you add indexes?"
    answer: "When queries scan more than 10% of the table."
---

This is a post about optimizing PostgreSQL queries.
We used Ruby on Rails and AWS to build the system.
