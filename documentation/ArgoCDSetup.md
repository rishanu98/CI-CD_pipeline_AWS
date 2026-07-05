# AWS ALB Ingress Controller

# 1. Download IAM policy
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

# 2. Create IAM Policy
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json

# 3. Create IAM Service Account for Load Balancer Controller
eksctl create iamserviceaccount \
  --cluster vprofile-eks-cluster \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::<EnterYourAccountID>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region us-east-1

# Get Kube Config file
aws eks update-kubeconfig --name vprofile-eks-cluster --region us-east-1

# 4. Install cert-manager
kubectl apply --validate=false \
  -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.1/cert-manager.yaml

# Wait for it to be ready
kubectl wait --for=condition=available --timeout=180s \
  deployment/cert-manager \
  deployment/cert-manager-cainjector \
  deployment/cert-manager-webhook \
  -n cert-manager


# 5. Wait for cert-manager
kubectl wait --for=condition=available \
  --timeout=90s \
  deployment/cert-manager \
  deployment/cert-manager-cainjector \
  deployment/cert-manager-webhook \
  -n cert-manager

# 6. Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=vprofile-eks-cluster \
  --set region=us-east-1 \
  --set vpcId=<EnterEKSVPC_ID>  \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# If we want to create a service account on the go 
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<your-cluster-name> \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<lb_controller_irsa_role_arn> \
  --set region=<your-region> \
  --set vpcId=<your-vpc-id>

# 7. Verify controller.

kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl get endpoints aws-load-balancer-webhook-service -n kube-system
kubectl logs -n kube-system deployment/aws-load-balancer-controller --tail=30

Step 4: Install ArgoCD
Bash
# Add ArgoCD Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD
helm upgrade argocd argo/argo-cd --version 9.5.2 --install --create-namespace -n argocd

# Wait for ArgoCD server to be ready
kubectl rollout status deployment argocd-server -n argocd

Step 5: Create Ingress for ArgoCD
Get your ACM Certificate ARN:
Bash
aws acm list-certificates --region us-east-1 \
  --query "CertificateSummaryList[*].{Domain:DomainName, ARN:CertificateArn}" \
  --output table
Create file argocd-ingress.yaml:
YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: <YourCertificate-ARN>
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80},{"HTTPS":443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
spec:
  rules:
  - host: argocd.<YourDomain>
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
Important: Replace the certificate-arn with your actual ACM certificate ARN.
Apply the ingress:
Bash
kubectl apply -f argocd-ingress.yaml
Watch the ALB DNS name:
Bash
kubectl get ingress argocd-ingress -n argocd -w

Step 6: Configure DNS in GoDaddy
Add the following CNAME record in your GoDaddy domain settings:
Type => CNAME
Name => argocd
Value => IngressELBEndpoint



Step 7: Access ArgoCD
Bash

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

ArgoCD Login Details:
URL: https://argocd.hkhinfotek.xyz
Username: admin
Password: (output from above command)

Reset argocd password from UI
