
{% test no_overlapping_validity(model, key_columns) %}

with versions as (
    select
        {% for col in key_columns %}
            {{ col }},
        {% endfor %}
        dbt_valid_from,
        dbt_valid_to,

        lead(dbt_valid_from) over (
            partition by
                {{ key_columns | join(', ') }}
            order by dbt_valid_from, dbt_scd_id
        ) as next_valid_from

    from {{ model }}
),

validation as (
    select *
    from versions
    where
        next_valid_from is not null
        and (
            dbt_valid_to is null
            or dbt_valid_to > next_valid_from
        )
)

select *
from validation

{% endtest %}
