# PRACTICA FINAL LIBERANDO PRODUCTOS - OSCAR MONTES

## Necesario:
 * python3 (en mi caso Python 3.10.6)
   
 * VirtualEnv:

    ```sh
    pip3 install virtualenv || sudo apt-get update && sudo apt-get install -y python3.10-venv
    ```
 
 * Docker

### Modificaciones previas:

 * Creamos un nuevo endpoint; para ello añadimos en el fichero src/aplication/app.py lo siguiente:
 
     ```
     BYE_ENDPOINT_REQUESTS = Counter('bye_requests_total', 'Total number of requests to main byeendpoint')
    
    ...
 
    @app.get("/bye")
    async def read_main():
        """Implement bye endpoint"""
        # Increment counter used for register the total number of calls in the webserver
        REQUESTS.inc()
        # Increment counter used for register the total number of calls in the main endpoint
        BYE_ENDPOINT_REQUESTS.inc()
        return {"msg": "Bye Dubai"}
     ```
* Creación de test unitario para el nuevo endpoint añadido en el fichero src/tests/app_test.py:

    ```
    @pytest.mark.asyncio
    async def read_bye_test(self):
        """Tests the bye endpoint"""
        response = client.get("/bye")

        assert response.status_code == 200
        assert response.json() == {"msg": "Bye Dubai"}
    ```
    
## Servidor:

### Servidor con Python:

 * Instalación: 
   * Obtener versión python: 
    
      ```sh
      python3 --version
      ```

   * Crear VirtualEnv en la raíz: 

      ```sh
      python3.10 -m venv venv
      ```

 * Activar VirtualEnv: 

    ```sh
    source venv/bin/activate
    ```

 * Instalar librerías (requirements.txt):

    ```sh
    pip3 install -r requirements.txt
    ```

 * Arrancar Servidor:

    ```sh
    python3 src/app.py
    ```
 * Veremos la URL de la App:
  
    ```sh
    Running on http://0.0.0.0:8081 (CTRL + C to quit)
    ```

### Servidor con Docker:

 * Creamos imagen Docker (en el directorio en el que está el Dockerfile)

    ```sh
    docker build -t app-practica ./   (esta imagen la subí a DockerHub para utilizarla en los ejercicios posteriores)
    ```

 * Arrancamos la imagen construída (mapeando los puertos de FastApi y Prometheus)

    ```sh
    docker run -d -p 8000:8000 -p 8081:8081 --name server server:0.0.1

 * Ejecuta `docker logs -f server` y te aparecerá la URL a la que puedes acceder:

     ```sh
    Running on http://0.0.0.0:8081 (CTRL + C to quit)
    ```

## Para correr los Tests:

 * Corre todos los test:
   
   ```sh
   pytest
   ``` 

 * Corre los test mostrando cobertura:
   
   ```sh
   pytest --cov
   ```

 * Corre los test generando un reporte de cobertura html:

   ```sh
   pytest --cov --cov-report=html
   ```
  * Con el resultado: 
  
  ![tests](https://user-images.githubusercontent.com/119674766/234513253-f077d955-d6f9-4f33-8337-c10293175695.jpg)
  
## Creación de pipelines de CI/CD:

```
Para ello utilizo Github.
```
![gitaction1](https://user-images.githubusercontent.com/119674766/235340463-5d384bcd-862c-47cc-b1c2-0f2de048055c.png)

![gitaction2](https://user-images.githubusercontent.com/119674766/235340469-c64a8df5-1483-4b4e-8584-7a4ffc793240.png)

## Monitoring-Autoscaling:

### Prometheus:
#### Software Necesario:
 * Minikube - https://minikube.sigs.k8s.io/docs/
 * Kubectl - https://kubernetes.io/docs/reference/kubectl/kubectl
 * Helm - https://helm.sh

 * Para ver las métricas necesitamos Prometheus que a su vez necesita `minikube`:
   ```sh
   minikube start --kubernetes-version='v1.21.1' \
    --memory=4096 \
    --addons="metrics-server,default-storageclass,storage-provisioner" \
    -p monitoring-practica
   ```

 * Añadir repositorio helm
   ```sh
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   ```

 * Desplegar chart Prometheus
   ```sh
   helm -n monitoring upgrade --install prometheus prometheus-community/kube-prometheus-stack -f ./helm/kube-prometheus-stack/custom_values_prometheus.yaml --create-namespace --wait 

 * Port-forward al service de prometheus - http://localhost:9090
   ```sh
   kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 &
   ```

 * Port-forward al service de grafana - http://localhost:3000
   ```sh
   kubectl -n monitoring port-forward svc/prometheus-grafana 3000:80 &
   ```
 
 * Instalar metrics server
   ```sh
   minikube addons enable metrics-server -p monitoring-practica
   ```
 * Desplegar app con helm:
   ```sh
   helm -n fast-api upgrade my-app --wait --install --create-namespace fast-api-webapp
   ```
#### Alerta consumo

 * En el yaml de Prometheus en mychart/prometheus está la configuración para la alerta que se lanzará en el canal #pruebas, en mi caso... lo puedes configurar modificando los siguientes valores:

   ```yaml
   receivers:
    - name: 'null'
    - name: 'slack'
      slack_configs:
      - api_url: 'https://hooks.slack.com/services/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' # <--- AÑADIR EN ESTA LÍNEA EL WEBHOOK CREADO
        send_resolved: true
        channel: '#pruebas' # <--- AÑADIR EN ESTA LÍNEA EL CANAL
        title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] Monitoring Event Notification'
   ```

##### Funcionamiento de la alerta:

 * Para la comprobación se necesita desactiva HPA, porque sino no funcionará
   ```sh
   helm -n liberando-productos-practica upgrade --install my-app --create-namespace --wait helm/fast-api-webapp --set autoscaling.enabled=false
   ```
 * Obtener el POD
   ```sh
   export POD_NAME=$(kubectl get pods --namespace liberando-productos-practica -l "app.kubernetes.io/name=fast-api-webapp,app.kubernetes.io/instance=my-app" -o jsonpath="{.items[0].metadata.name}")
   ```

 * Nos conectamos al POD
   ```sh
   kubectl -n fast-api exec -it $POD_NAME -- /bin/sh
   ```
   * Dentro del POD
      * Instalamos software
         ```sh
         apk update && apk add git go
         ```
      * Descargamos software para prueba de estrés
         ```sh
         git clone https://github.com/jaeg/NodeWrecker.git
         cd NodeWrecker
         go build -o estres main.go
         ```
      * Ejecutamos binario
         ```sh
         ./estres -abuse-memory -escalate -max-duration 10000000
         ```
 *  Primero llega la alerta y después la recuperación:
    
![slack](https://user-images.githubusercontent.com/119674766/235288715-bf479a64-1491-4bd6-ac47-8b42dddadcd8.png)

### Grafana

 * Lo primero será importar el dashboard con el archivo dashboard-oscar.json 
 
```
   Para ello accederemos al panel de grafana:  https://0.0.0.0:3000
   El usuario es admin y la contraseña prom-operator
   En el menú vertical de la izquierda: + >> Import
   Selecciona el archivo dashboard-oscar.json del directorio monitoring del repositorio clonado.
```
 
  * Con lo que visualizaremos los diferentes Dashboards:
      
![grafana](https://user-images.githubusercontent.com/119674766/235290053-b667aa38-5545-49c4-ae89-472737fbca2a.png)




