[validator]
%{ for idx, addr in public_ips ~}
${addr} p2p_peer_id=${keys_octoup[idx]["peer_id"]} key_root_path=${keys_octoup[idx]["key_dir"]}
%{ endfor ~}

[validator:vars]
ansible_python_interpreter=/usr/bin/python3
