view: audience_labeling {
  derived_table: {
    datagroup_trigger: ecomm_daily
    sql: SELECT
        ml_generate_text_result['predictions'][0]['content'] AS generated_text,
        ml_generate_text_result['predictions'][0]['safetyAttributes']
          AS safety_attributes,
        * EXCEPT (ml_generate_text_result)
      FROM
        ML.GENERATE_TEXT(
          MODEL  `looker-private-demo.ecomm.email_promotion`,
          (
            SELECT FORMAT(
                CONCAT('''Please label the following cluster with a short catchy marketing name. Filling in the following data {"cluster_label": ,"cluster_description": } These labels should be based on the provided data. The labels will be used by marketers to effectively target their customer base, so keep that in mind when generating the labels. \n Cluster: %d, Total Audience in Cluster: %d, Average Spend Per User in Cluster: %f, Total Revenue: %f, Average Age: %f, Unique Brands Purchased From: %f,Total Order Count: %d,Average Return Rate: %f, Unique Categories Purchased From: %f''')
                  ,centroid_id
                  ,order_items_count
                  ,order_items_average_spend_per_user
                  ,order_items_total_gross_margin
                  ,users_average_age
                  ,products_brand_count
                  ,order_items_count
                  ,order_items_return_rate
                  ,products_category_count
                )  AS prompt
                , centroid_id
              FROM (
                SELECT audience_clustering.CENTROID_ID as centroid_id
                    ,COUNT(*)
                    ,AVG(audience_clustering.order_items_average_spend_per_user) as order_items_average_spend_per_user
                    ,SUM(audience_clustering.order_items_total_gross_margin) as order_items_total_gross_margin
                    ,AVG(audience_clustering.users_average_age) as users_average_age
                    ,AVG(audience_clustering.products_brand_count) as products_brand_count
                    ,SUM(audience_clustering.order_items_count) as order_items_count
                    ,AVG(audience_clustering.order_items_return_rate) as order_items_return_rate
                    ,AVG(audience_clustering.products_category_count) as products_category_count
                FROM ${audience_clustering.SQL_TABLE_NAME} as audience_clustering
                GROUP BY 1
              )
      ),
      STRUCT(
      0.2 AS temperature,
      100 AS max_output_tokens)) ;;
  }

  dimension: prompt {
    hidden: yes
  }

  dimension: generated_text {
    label: "Cluster Label"
    type: string
    sql: JSON_VALUE(JSON_VALUE(${TABLE}.generated_text), "$.cluster_label") ;;
  }

  dimension: generated_description {
    label: "Cluster Description"
    type: string
    sql: JSON_VALUE(JSON_VALUE(${TABLE}.generated_text), "$.cluster_description") ;;
    html: <div style="width:60%"><svg height="50" width="50" src="https://fonts.gstatic.com/s/i/short-term/release/googlesymbols/info_spark/default/24px.svg"></svg><span style="text-wrap:wrap">{{value}}</span></div> ;;
  }

  dimension: centroid_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.centroid_id ;;
  }
}
