[validator]
%{ for idx, addr in public_ips ~}
${addr} hostname=${hostnames[idx]} private_ip=${private_ips[idx]} p2p_peer_id=${peer_ids[idx]}
%{ endfor ~}

[validator:vars]
ansible_python_interpreter=/usr/bin/python3
