{# Macro import #}
{% if not helpers.empty('OPNsense.Netmaker.general.enabled') %}
netmaker_enable="YES"
mosquitto_enable="YES"
{% else %}
netmaker_enable="NO"
mosquitto_enable="NO"
{% endif %}
