{% macro generate_composite_key(column1, column2) %}

    concat(cast({{ column1 }} as varchar), '-', cast({{ column2 }} as varchar))

{% endmacro %}
