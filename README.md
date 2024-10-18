This solution will deploy a secure VM with Terraform 

Steps : 

Here’s a simplified SetUp steps to follow :
1. Login to Azure: Sign in to your Azure Subscription.
2. Create a Service Principal:
- Open the Azure Cloud Shell and run the following command to create a service
principal and save the output.
```
az ad sp create-for-rbac --name "bankwork1" --role="Contributor"
--scopes="/subscriptions/<subscriptionID>"
```
3. Add Client Secret in Azure DevOps:
- Go to Azure DevOps → Pipelines → Library and add the `client_secret` from the
output of the previous step.
4. Create your own SSH Key and keep id_rsa.pub for further use .
- Generate an SSH key for secure login to the VM by running:
```
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```
- Copy the `id_rsa.pub` file for later use.
5. Create Azure DevOps Pipeline:
- Write a pipeline YAML file (`Azure-pipeline.yml`) that includes the secret variable
(`client_secret`) to deploy resources.
6. Push Files to Azure DevOps:
- Go to Azure DevOps → Create an organization → Repos.
- Push the following files to the repository:
1. `main.tf`
2. `user_data.sh`
3. `id_rsa.pub`
4. `Azure-pipeline.yml`
7. Update `main.tf`:
- Edit the `main.tf` file and add the `subscription_id`, `client_id`, `client_secret`, and
`tenant_id` obtained from Step 2.
8. Run the Pipeline:
- Trigger the pipeline using `Azure-pipeline.yml`. Once it finishes successfully, the
output will be the NGINX URL.
- Pipeline ask for Authentication before starting .
- Put the URL in the Browser to see the NGINX Welcome Page .
9. Check Resources:
- Go to the Azure portal to verify the resources under your resource group, access the
SSH key, and manage the VM.
