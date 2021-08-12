val("octopus/gateway/api/config.json") = "${api_config_escape}"

get octopus/gateway/api/config.json
%{ for idx, chain in chains ~}
get octopus/gateway/messenger/chains/${chain}.json
%{ endfor ~}
get octopus/gateway/messenger/config.json
get octopus/gateway/stat/config.json

put octopus/gateway/api/config.json ${api_config}
%{ for idx, chain in chains ~}
put octopus/gateway/messenger/chains/${chain}.json ${messenger_processor_config}
%{ endfor ~}
put octopus/gateway/messenger/config.json ${messenger_config}
put octopus/gateway/stat/config.json ${stat_config}
