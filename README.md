# k8s-dns-lab

### Prerequisites
- awscli => 1.16.302
- kubectl => 1.14.0
- IAM role or user configured for awscli with Administrator policy


You can run the following make command to check your system configuration:
```bash
make depcheck
```

By default, the script will deploy an EKS cluster named k8s-dns-lab in eu-west-1 region. If you want to change this, modify the parameters.conf file, and adjust the value of variable ClusterName and StackRegion. 

**PLEASE**, adjust the following variables in parameters.conf before deploying:
- **StackBucket**, the name of the S3 bucket to upload the CFN stack artifacs
- **StackBucketRegion**, make sure to put the correct region where the bucket reside
- **KeyName**, make sure this EC2 key name is available in the region where you deploy the Cluster (configured via **StackRegion**)

### Deploying and Updating the Cluster
To deploy and update the cluster, run the following command:
```bash
make deploy
```

There are three branches on this repo
- **Master**
- **node-local-cache**, this will configure default pod dns config to point to node-local-cache
- **cache-with-fallback**, this will configure default pod dns config to have two nameservers for fallback

You can switch branch and redeploy the stack
```bash
git checkout <branch-name>
make deploy
```

### Deleting the Cluster
To delete all resources created through this script, execute the following command:
```bash
make delete
```