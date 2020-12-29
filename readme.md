# Introduction
This repositry is the terraform code for the following article.  
https://qiita.com/ys_nishida/items/dc57862f18865750d8e6

# How to create https ilb for testing.
## 1. Download terraform code.
```
git clone https://github.com/ys-nishida/qiita-https-ilb-xff.git
```

## 2. Modify the unique setting.
| File | Setting to be modified | Row number |
| ---- | ---- | ---- |
| gcs_startup.tf | bucket name | 3 |
| variable.tf | project name, id | 3,4 |

## 3. Exec terraform
```
terraform init
terraform plan
terraform apply
```
