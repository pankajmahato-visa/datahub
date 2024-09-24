#!/bin/sh

parse_yaml() {
    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @ | tr @ '\034')
    sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 |
        awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

eval $(parse_yaml $5 "recipe_config_")

#keytabs=("svcdlcnifi" "svchdlc1d" "svcdpidlcd")
IFS=',' read -ra keytabs <<< "$VDC_KEYTABS"
hive_config="false"
if [[ $recipe_config_source_type == "hive" && $recipe_config_source_config_options_connect_args_auth == "KERBEROS" && $recipe_config_source_config_username != "" ]]; then
    hive_config="true"
    keytab_found="false"
    echo "Initialising Kerberos Ticket Cache for $recipe_config_source_config_username"
    for keytab in "${keytabs[@]}"; do
        if [[ $keytab == $recipe_config_source_config_username ]]; then
            export KRB5CCNAME=/data/vdc/datahub/tickets/$keytab.ticket
            keytab_found="true"
        fi
    done

    if [[ $keytab_found == "false" ]]; then
        echo "No registered username (keytab) found for $recipe_config_source_config_username"
    fi
fi
