Login to argocd from command line.
 
$ argocd login argocd.hkhinfotek.xyz --username admin
Add Repository in argocd.
$ argocd repo add git@github.com:<YourGithubAccountName>/vprofile-helm.git --ssh-private-key-path ~/.ssh/<Keyname>


Attaching the IAM policy to the node group for ECR Access.

Find the node group name.
$ aws eks list-nodegroups \
  --cluster-name vprofile-eks-cluster \
  --region us-east-1

Find the ROLE name for the node group name.
$ aws eks describe-nodegroup   --cluster-name vprofile-eks-cluster   --nodegroup-name vprofile-eks-cluster-ng   --region us-east-1   --query "nodegroup.nodeRole"   --output text

Attach ECR read policy to the role
$ aws iam attach-role-policy \
  --role-name vprofile-eks-cluster-node-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

List the attached policies
$ aws iam list-attached-role-policies \
  --role-name vprofile-eks-cluster-node-role \
  --output table




Create folder argocd in that create apps and projects folder.
cat argocd/projects/vprofile-project.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: vprofile
  namespace: argocd
spec:
  description: vProfile application project
  sourceRepos:
    - git@github.com:<GithubAccountName>/vprofile-helm.git
  destinations:
    - namespace: vprofile
      server: https://kubernetes.default.svc
  clusterResourceWhitelist:
    - group: ""
      kind: Namespace
  namespaceResourceWhitelist:
    - group: "*"
      kind: "*"

cat argocd/apps/vprofile-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: vprofile
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: vprofile
  source:
    repoURL: git@github.com:<GithubAccountName>/vprofile-helm.git
    targetRevision: main
    path: helm/vprofile-chart
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: vprofile
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true

