[validator]
%{ for idx, addr in public_ips ~}
${addr} p2p_peer_id=${peer_ids[idx]}
%{ endfor ~}

[validator:vars]
ansible_python_interpreter=/usr/bin/python3
