# para publicar a imagem no docker hub
cd apis/ms1 && docker build -t user-dockerhub/ms1-go . && \
 docker push user-dockerhub/ms1-go && cd .. && cd ms2 && \
 docker build -t user-dockerhub/ms2-go . && \
 docker push user-dockerhub/ms2-go

# testar
docker run --rm -p 3000:3000 user-dockerhub/ms1-go
curl http://localhost:3000
docker run --rm -p 3000:3000 user-dockerhub/ms2-go
curl http://localhost:3000


# criando cluster
# usar o contexto do projeto
cd ../../k8s/cluster && kind create cluster --name kubernetes-kong --config kind.yaml && \ 
 kubectl cluster-info --context kind-kubernetes-kong
 
# depois de instalar o helm no seu sistema operacional
# instalando kong no cluster
helm repo add kong https://charts.konghq.com && helm repo update && \
 kubectl create namespace kong && \
 helm install kong kong/kong --set ingressController.installCRDs=false \
  --set proxy.type=NodePort,proxy.http.nodePort=30000,proxy.tls.nodePort=30003 \
  --set serviceMonitor.enabled=true \
  --set serviceMonitor.labels.release=promstack \
  --namespace kong

# aplicando o data-plane e o control plane
cd ../kong && kubectl apply -f . && kubectl get pods -n kong

#espera os pods deo kong iniciar
# criando namespace
kubectl create ns api-test-namespace-dev && cd ../api-ms1 && \
 kubectl apply -f . && cd ../api-ms2 && kubectl apply -f .

# instalando plugin
cd ../kong/plugins && kubectl apply -f .

# test
kubectl api-resources --api-group='configuration.konghq.com'
kubectl get kongplugins -n kong

for i in {1..3}; do curl -i http://localhost:8080/user; done && \
 for i in {1..3}; do curl -i "http://localhost:8080/product"; done

# verificar se o kong recebe as req
kubectl get pods -n kong
kubectl logs -n kong kong-kong-b9759459b-tlf87 -c proxy

