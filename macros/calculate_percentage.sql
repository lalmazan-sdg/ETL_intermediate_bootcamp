{% macro calculate_percentage(numerator, denominator, decimals=2) %}

    round(({{ numerator }}) / nullif({{ denominator }}, 0) * 100, {{ decimals }})

{% endmacro %}
