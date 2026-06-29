## 1. Create and test Helm chart locally

### Step 1: Create a Helm chart

```powershell
helm create <chart-name>
```

This creates a Helm chart folder containing files such as:

```text
Chart.yaml
values.yaml
templates/
charts/
```

Example:

```powershell
helm create vprofile
```

---

### Step 2: Check the Helm chart syntax and structure

```powershell
helm lint <chart-folder-path>
```

Example:

```powershell
helm lint helm
```

This checks whether the chart structure and Helm template syntax are valid.

---

### Step 3: Render the Kubernetes YAML files locally

```powershell
helm template <release-name> <chart-folder-path>
```

Example:

```powershell
helm template webapp helm
```

This command does not install anything. It only shows the final Kubernetes YAML generated from the Helm templates and `values.yaml`.

Use this to verify whether variables from `values.yaml` are correctly referenced inside the templates.

---

### Step 4: Test installation without creating resources

```powershell
helm install <release-name> <chart-folder-path> -n <namespace> --create-namespace --dry-run --debug
```

Example:

```powershell
helm install webapp helm -n webapp-ns --create-namespace --dry-run --debug
```

This simulates the installation and shows detailed debug output, but it does not create Pods, Services, Deployments, or Ingress resources.

---

### Step 5: Install the Helm chart into the cluster

```powershell
helm install <release-name> <chart-folder-path> -n <namespace> --create-namespace
```

Example:

```powershell
helm install webapp helm -n webapp-ns --create-namespace
```

This installs the Helm chart into the Kubernetes cluster and creates the resources defined inside the chart.

---

### Step 6: Verify the namespace

```powershell
kubectl get ns
```

or:

```powershell
kubectl get ns <namespace>
```

Example:

```powershell
kubectl get ns webapp-ns
```

---

### Step 7: Check the Helm release

```powershell
helm list -n <namespace>
```

Example:

```powershell
helm list -n webapp-ns
```

This shows the Helm releases installed inside the namespace.

You can also check all releases in all namespaces:

```powershell
helm list -A
```

---

### Step 8: Check Kubernetes resources created by Helm

```powershell
kubectl get all -n <namespace>
```

Example:

```powershell
kubectl get all -n webapp-ns
```

You can also check individual resources:

```powershell
kubectl get pods -n webapp-ns
kubectl get svc -n webapp-ns
kubectl get ingress -n webapp-ns
```

---

## 2. Check and configure Ingress in Minikube

The Ingress resource alone does not route traffic. It only defines routing rules.

You also need an Ingress Controller, such as NGINX Ingress Controller, to actually process those rules and forward traffic to the correct Kubernetes Service.

---

### Step 1: Check whether the NGINX Ingress Controller is running

```powershell
kubectl get pods -n ingress-nginx
```

If you see a controller Pod like this, the Ingress Controller is running:

```text
ingress-nginx-controller-xxxxx   1/1   Running
```

The `Completed` admission Pods are normal and are not an error.

---

### Step 2: Enable Ingress addon in Minikube if it is not installed

If the namespace `ingress-nginx` is not found, or no controller Pod is running, enable the Minikube Ingress addon:

```powershell
minikube addons enable ingress
```

Then check again:

```powershell
kubectl get pods -n ingress-nginx
```

---

### Step 3: Check the Ingress Controller Service

```powershell
kubectl get svc -n ingress-nginx
```

This shows the Service used by the NGINX Ingress Controller.

---

### Step 4: Check your application Ingress rule

```powershell
kubectl get ingress -n <namespace>
```

Example:

```powershell
kubectl get ingress -n webapp-ns
```

To see detailed routing information:

```powershell
kubectl describe ingress -n webapp-ns
```

or:

```powershell
kubectl describe ingress <ingress-name> -n webapp-ns
```

Example:

```powershell
kubectl describe ingress vpro-ingress -n webapp-ns
```

This shows the host, path, backend Service, and endpoint information.

---

### Step 5: Get the Minikube IP

```powershell
minikube ip
```

Example output:

```text
192.168.49.2
```

---

### Step 6: Add hostname mapping in Windows hosts file

If your Ingress host is:

```text
vprofile.local
```

then add this entry to the Windows hosts file:

```text
192.168.49.2   vprofile.local
```

The Windows hosts file is located at:

```text
C:\Windows\System32\drivers\etc\hosts
```

Open it as Administrator before editing.

---

### Step 7: Access the application

Open in browser:

```text
http://vprofile.local
```

or test from PowerShell:

```powershell
curl http://vprofile.local
```

---

## Summary

Helm creates Kubernetes resources from your chart templates.

Ingress defines routing rules, but the NGINX Ingress Controller actually implements those rules.

For local Minikube testing, the usual flow is:

```text
minikube start
helm lint
helm template
helm install --dry-run --debug
helm install
minikube addons enable ingress
kubectl get ingress
kubectl get pods -n ingress-nginx
minikube ip
edit hosts file
access app using local hostname
```
