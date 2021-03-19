
import os
import json
import subprocess
import shutil
import jinja2
import shortuuid


# - workspace
#   - template
#       - terraform
#           - aws
#           - ...
#           - gcp
#       - ansible
#   -{uuid}
#       - terraform
#       - ansible
def run_task(workspace, userdata):

    with open(os.path.join(userdata, 'userdata.json')) as f:
        task = json.loads(f.read())

    # 1 root dir
    uuid = shortuuid.uuid()
    task_dir = os.path.join(workspace, uuid)
    tmpl_dir = os.path.join(workspace, 'template')
    os.makedirs(task_dir)

    # 2 ssh key
    ssh_dir = os.path.join(task_dir, 'ssh')
    ssh_file = os.path.join(ssh_dir, uuid)
    os.makedirs(ssh_dir)
    cmd = f"ssh-keygen -t rsa -P '' -f {ssh_file}"
    os.system(cmd)
    if not os.path.exists(ssh_file):
        raise Exception

    # 3 generate template
    cloud_ext = {
        'vpc_name': f'vpd-{uuid}',
        'vswitch_name': f'vsw-{uuid}',
        'security_group_name': f'sg-{uuid}',
        'instance_name': f'ecs-{uuid}',
    }
    task['cloud'].update(cloud_ext)

    with open(ssh_file+'.pub') as f:
        pub_key = f.read().rstrip()
    task_ext = {
        'ssh': {
            'key_name': f'key-{uuid}',
            'public_key': pub_key,
            'private_key_file': os.path.join('..', 'ssh', uuid),
        },
        'user': {
            'user': uuid, 
            'group': uuid,
        }
    }
    task.update(task_ext)

    # 3.1 terraform
    if task['cloud']['type'] not in ('aws', 'gcp', 'azure', 'alicloud'):
        raise Exception
    tmpl_src = os.path.join(tmpl_dir, 'terraform', task['cloud']['type'])
    tmpl_dst = os.path.join(task_dir, 'terraform')
    shutil.copytree(tmpl_src, tmpl_dst)

    inputs_src = os.path.join(tmpl_dir, 'terraform/inputs-tmpl.tfvars')
    inputs_dst = os.path.join(task_dir, 'terraform/terraform.tfvars')
    with open(inputs_src) as fi, open(inputs_dst, 'w') as fo:
        print(task)
        template = jinja2.Template(fi.read())
        fo.write(template.render(task))

    # 3.2 ansible
    tmpl_src = os.path.join(tmpl_dir, 'ansible', 'playbooks')
    tmpl_dst = os.path.join(task_dir, 'ansible', 'playbooks')
    shutil.copytree(tmpl_src, tmpl_dst)

    cfg_src = os.path.join(tmpl_dir, 'ansible/ansible-tmpl.cfg')
    cfg_dst = os.path.join(task_dir, 'ansible/ansible.cfg')
    with open(cfg_src) as fi, open(cfg_dst, 'w') as fo:
        template = jinja2.Template(fi.read())
        fo.write(template.render(task))

    inputs_src = os.path.join(tmpl_dir, 'ansible/inputs-tmpl.yml')
    inputs_dst = os.path.join(task_dir, 'ansible/playbooks/roles/chain_node/vars/main/inputs.yml')
    with open(inputs_src) as fi, open(inputs_dst, 'w') as fo:
        template = jinja2.Template(fi.read())
        fo.write(template.render(task))
    
    spec_src = os.path.join(userdata, 'chainSpecRaw.json')
    spec_dst = os.path.join(task_dir, 'ansible/playbooks/roles/chain_node/files/chainSpec.json')
    shutil.copy(spec_src, spec_dst)

    # 4 run terraform
    cmd = f'terraform -chdir={uuid}/terraform init && terraform -chdir={uuid}/terraform plan && terraform -chdir={uuid}/terraform apply -auto-approve'
    os.system(cmd)


run_task('.', 'data/example-1')
