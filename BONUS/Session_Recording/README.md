# SSH Session Recording

This repo make uses of boundary_team_acctest_dev and associated repo. Using that as basis we have created a Boundary Org, project, targets using AWS plugins. We have also created the resources in Boundary to make use of SSH Session Recording:

* PKI Worker
* Storage Bucket
* S3 and IAM policies
* SSH Target
* SSH Injected Secret using Boundary Credential Storage
* Integration with Vault for SSH Secret Injection

```
cd BONUS/Session_Recording/PKI_Worker
cp ../../../4_Vault_SSH_Injection/vault_ca.pub .
terraform apply -auto-approve
```

This will create a new Org in our Boundary Cluster with a single target

![1690551980490](image/README/1690551980490.png)We can connect as usual. Once done, if we go to Boundary web UI we can see the recordings in the Global Org

![1690552088638](image/README/1690552088638.png)

![1690552190385](image/README/1690552190385.png)

## Clean Up

```bash
terraform destroy -auto-approve
```
