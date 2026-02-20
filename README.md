# Swimlane DevOps Practical

Node.js + MongoDB app running on a self-managed Kubernetes cluster on AWS.

## The setup

Everything sits behind a bastion host. The K8s nodes don't have public IPs -- they live in private subnets and talk to the internet through a NAT Gateway. The only way in is through the bastion, which also runs Nginx to serve the app on port 80.

```
you --> bastion (nginx, port 80) --> master (nodeport 30000) --> app pod
                                 --> worker
                                 
        private nodes --> NAT Gateway --> internet (docker pull, apt, etc.)
```

## Tools used

- **Packer** -- bakes an AMI with K8s dependencies so nodes boot fast
- **Terraform** -- creates the VPC, subnets, NAT, bastion, and K8s nodes
- **Ansible** -- bootstraps the cluster (kubeadm init, worker join, nginx on bastion)
- **Kustomize** -- deploys the app with dev/prod overlays

## How to deploy

### Build the AMI

```bash
cd packer
packer init k8s-node.pkr.hcl
packer build k8s-node.pkr.hcl
```

Grab the AMI ID from the output.

### Spin up the infra

```bash
cd terraform/private
terraform init
terraform apply -var key_name=mykey -var ami_id=ami-xxxxx
```

You'll get three IPs: bastion (public), master (private), worker (private).

### Set up the inventory

Put the IPs into `ansible/inventory/hosts.ini`. The bastion public IP goes under `[bastion]`, master and worker private IPs go under `[master]` and `[workers]`. Don't forget to update the ProxyCommand and key path too.

### Run ansible

```bash
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbook.yml
```

### Deploy the app

```bash
eval $(ssh-agent)
ssh-add ~/.ssh/mykey.pem

# copy manifests to master
scp -r -o ProxyCommand="ssh -A -W %h:%p ubuntu@BASTION_IP" \
  k8s/ ubuntu@MASTER_IP:~/k8s/

# ssh in and apply
ssh -A ubuntu@BASTION_IP
ssh ubuntu@MASTER_IP
kubectl apply -k ~/k8s/overlays/dev/
```

### Set up nginx on bastion

SSH into the bastion, edit `/etc/nginx/sites-available/default`:

```nginx
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://MASTER_IP:30000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

```bash
sudo nginx -t && sudo systemctl reload nginx
```

Hit `http://BASTION_IP` in your browser.

## Running locally

```bash
npm install
cp .env.example .env
docker-compose up
```

App runs at http://localhost:3000.

## Tearing it down

```bash
cd terraform/private
terraform destroy -var key_name=mykey -var ami_id=ami-xxxxx
```

Delete the Packer AMI and its snapshot from the AWS console if you don't need them.

## Project layout

```
terraform/private/   -- prod infra (private subnets, bastion, NAT)
terraform/public/    -- simple infra (public IPs, default VPC)
ansible/             -- playbooks and roles (bastion, ntp, k8s, master, worker)
packer/              -- AMI build config
k8s/                 -- kustomize manifests (base + dev/prod overlays)
```

See [docs/private-infra-setup.md](docs/private-infra-setup.md) for the full walkthrough with traffic flow diagrams and security group details.
