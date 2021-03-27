version: "3.8"
services:
  seashell:
    image: {{ base_image }}
    container_name: seashell
    command: >
{% if start_cmd is defined and start_cmd|length %}
      {{ start_cmd }}
{% endif %}
      --base-path /home/seashell/chain_data
      --chain /home/seashell/chainSpec.json
      --node-key-file /home/seashell/.node_key
      --port 30333
      --rpc-port 9933
      --rpc-cors all
      --rpc-external
      --rpc-methods Unsafe
      --ws-port 9944
      --ws-external
      --validator
      --wasm-runtime-overrides /home/seashell/wasm
{% for node in groups['validator'] %}{% if hostvars[inventory_hostname].p2p_peer_id != hostvars[node].p2p_peer_id %}
      --bootnodes /ip4/{{ node }}/tcp/30333/p2p/{{ hostvars[node].p2p_peer_id }}
{% endif %}{% endfor %}
    ports:
      - 9933:9933
      - 9944:9944
      - 30333:30333
    volumes:
      - ./chain_data:/home/seashell/chain_data
      - ./chainSpec.json:/home/seashell/chainSpec.json
      - ./.node_key:/home/seashell/.node_key
      - ./node_runtime.wasm:/home/seashell/wasm/node_runtime.wasm
    restart: always
    user: root
