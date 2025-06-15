# Дипломный практикум в Yandex.Cloud - Сергей Яремко
  * [Цели:](#цели)
  * [Этапы выполнения:](#этапы-выполнения)
     * [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
     * [Создание Kubernetes кластера](#создание-kubernetes-кластера)
     * [Создание тестового приложения](#создание-тестового-приложения)
     * [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
     * [Установка и настройка CI/CD](#установка-и-настройка-cicd)
  * [Что необходимо для сдачи задания?](#что-необходимо-для-сдачи-задания)
  * [Как правильно задавать вопросы дипломному руководителю?](#как-правильно-задавать-вопросы-дипломному-руководителю)

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

---
## Цели:

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

---
## Этапы выполнения:


### Создание облачной инфраструктуры

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://www.terraform.io/).

Особенности выполнения:

- Бюджет купона ограничен, что следует иметь в виду при проектировании инфраструктуры и использовании ресурсов;
Для облачного k8s используйте региональный мастер(неотказоустойчивый). Для self-hosted k8s минимизируйте ресурсы ВМ и долю ЦПУ. В обоих вариантах используйте прерываемые ВМ для worker nodes.

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создайте сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя
2. Подготовьте [backend](https://developer.hashicorp.com/terraform/language/backend) для Terraform:  
   а. Рекомендуемый вариант: S3 bucket в созданном ЯО аккаунте(создание бакета через TF)
   б. Альтернативный вариант:  [Terraform Cloud](https://app.terraform.io/)
3. Создайте конфигурацию Terrafrom, используя созданный бакет ранее как бекенд для хранения стейт файла. Конфигурации Terraform для создания сервисного аккаунта и бакета и основной инфраструктуры следует сохранить в разных папках.
4. Создайте VPC с подсетями в разных зонах доступности.
5. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.
6. В случае использования [Terraform Cloud](https://app.terraform.io/) в качестве [backend](https://developer.hashicorp.com/terraform/language/backend) убедитесь, что применение изменений успешно проходит, используя web-интерфейс Terraform cloud.

Ожидаемые результаты:

1. Terraform сконфигурирован и создание инфраструктуры посредством Terraform возможно без дополнительных ручных действий, стейт основной конфигурации сохраняется в бакете или Terraform Cloud
2. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.

### Создание облачной инфраструктуры. Решение.

Натачиваем (от слова touch, а не точить) файлы:

[service_account.tf](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/backet/service_account.tf)

```.tf
# create service account
resource "yandex_iam_service_account" "service-editor" {
  name        = var.service_account_name
  folder_id   = var.folder_id
}

# create role
resource "yandex_resourcemanager_folder_iam_member" "service-editor-role" {
  folder_id = var.folder_id
  role      = var.service_account_role
  member    = "serviceAccount:${yandex_iam_service_account.service-editor.id}"
}

#create static key
resource "yandex_iam_service_account_static_access_key" "service-editor-key" {
  service_account_id = yandex_iam_service_account.service-editor.id
}
```
[backend.tf](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/backet/backend.tf)

```.tf
#create backet
resource "yandex_storage_bucket" "diplom-bucket" {
  bucket     = var.diplom_backet
  access_key = yandex_iam_service_account_static_access_key.service-editor-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.service-editor-key.secret_key

  anonymous_access_flags {
    read = false
    list = false
  }

  force_destroy = true

provisioner "local-exec" {
  command = "echo export ACCESS_KEY=${yandex_iam_service_account_static_access_key.service-editor-key.access_key} > ./backend.tfvars"
}

provisioner "local-exec" {
  command = "echo export SECRET_KEY=${yandex_iam_service_account_static_access_key.service-editor-key.secret_key} >> ./backend.tfvars"
}
}
```
[variables.tf](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/backet/variables.tf)

```.tf
###cloud vars
variable "token" {
  type        = string
  description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
  #default = ""
  #sensitive = true
}

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
  #default = ""
  #sensitive = true
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
  #default = ""
  #sensitive = true
}

variable "service_account_name" {
  type        = string
  default     = "service-editor"
  description = "service account name"
}

variable "service_account_role" {
  type        = string
  default     = "editor"
  description = "service account role"
}

variable "diplom_backet" {
  type        = string
  default     = "diplom-backet"
  description = "backet"
}
```
Далее по порядку:

```
terraform init
```
```
terraform validate
```
```
terraform plan
```
```
terraform apply --auto-approve
```
Скринотени:

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/VirtualBox_Ubuntu-50Gb_13_06_2025_11_13_28.png)

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/Снимок_2025-06-13_112635_console.yandex.cloud.png)

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/Снимок_2025-06-13_112711_console.yandex.cloud.png)

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/Снимок_2025-06-13_112800_console.yandex.cloud.png)



---
### Создание Kubernetes кластера

На этом этапе необходимо создать [Kubernetes](https://kubernetes.io/ru/docs/concepts/overview/what-is-kubernetes/) кластер на базе предварительно созданной инфраструктуры.   Требуется обеспечить доступ к ресурсам из Интернета.

Это можно сделать двумя способами:

1. Рекомендуемый вариант: самостоятельная установка Kubernetes кластера.  
   а. При помощи Terraform подготовить как минимум 3 виртуальных машины Compute Cloud для создания Kubernetes-кластера. Тип виртуальной машины следует выбрать самостоятельно с учётом требовании к производительности и стоимости. Если в дальнейшем поймете, что необходимо сменить тип инстанса, используйте Terraform для внесения изменений.  
   б. Подготовить [ansible](https://www.ansible.com/) конфигурации, можно воспользоваться, например [Kubespray](https://kubernetes.io/docs/setup/production-environment/tools/kubespray/)  
   в. Задеплоить Kubernetes на подготовленные ранее инстансы, в случае нехватки каких-либо ресурсов вы всегда можете создать их при помощи Terraform.
2. Альтернативный вариант: воспользуйтесь сервисом [Yandex Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes)  
  а. С помощью terraform resource для [kubernetes](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster) создать **региональный** мастер kubernetes с размещением нод в разных 3 подсетях      
  б. С помощью terraform resource для [kubernetes node group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group)
  
Ожидаемый результат:

1. Работоспособный Kubernetes кластер.
2. В файле `~/.kube/config` находятся данные для доступа к кластеру.
3. Команда `kubectl get pods --all-namespaces` отрабатывает без ошибок.

### Создание Kubernetes кластера. Решение

[код для terraform тут](https://github.com/s-bessonniy/devops-diplom-yandexcloud/tree/main/k8s)

Устанавливаем:

```
terraform init -backend-config="access_key=$ACCESS_KEY" -backend-config="secret_key=$SECRET_KEY"
```
```
terraform validate
```
```
terraform plan
```
```
terraform apply -auto-approve
```

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/VirtualBox_Ubuntu-50Gb_14_06_2025_11_37_54.png)

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/Снимок_2025-06-14_060652_console.yandex.cloud.png)

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/Снимок_2025-06-14_060731_console.yandex.cloud.png)

И получился у нас специальный файл:

[hosts.yaml](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/k8s/hosts.yaml)

Затем надо собрать кластер
```
git clone https://github.com/kubernetes-sigs/kubespray
```
```
python3 -m venv myenv
```
```
source myenv/bin/activate
```
```
pip install -r requirements.txt
```
```
ansible-playbook -i inventory/hosts.yaml -u ubuntu --become --become-user=root --private-key=/home/deck/.ssh/id_ed25519 -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no"' cluster.yml --flush-cache
```
По итогу:

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/VirtualBox_Ubuntu-50Gb_14_06_2025_06_00_14.png)

Далее нам нужно закреатить конфиг для доступа. Переходим с мастер ноду и джимбеним:
```
mkdir ~/.kube
```
```
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
```
```
sudo chown -R ubuntu:ubuntu $HOME/.kube/config
```
```
ll ~/.kube/
```
```
kubectl get nodes
```
```
kubectl get pods --all-namespaces
```

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/VirtualBox_Ubuntu-50Gb_14_06_2025_06_03_18.png)

И потом этот конфиг копирнул на свою тачку и прекрасно работал с нее.

---
### Создание тестового приложения

Для перехода к следующему этапу необходимо подготовить тестовое приложение, эмулирующее основное приложение разрабатываемое вашей компанией.

Способ подготовки:

1. Рекомендуемый вариант:  
   а. Создайте отдельный git репозиторий с простым nginx конфигом, который будет отдавать статические данные.  
   б. Подготовьте Dockerfile для создания образа приложения.  
2. Альтернативный вариант:  
   а. Используйте любой другой код, главное, чтобы был самостоятельно создан Dockerfile.

Ожидаемый результат:

1. Git репозиторий с тестовым приложением и Dockerfile.
2. Регистри с собранным docker image. В качестве регистри может быть DockerHub или [Yandex Container Registry](https://cloud.yandex.ru/services/container-registry), созданный также с помощью terraform.

### Создание тестового приложения. Решение
Погнали:
```
docker build -t yaremko-test-nginx .
```
```
docker tag yaremko-test-nginx:latest insommnia/yaremko-test-nginx:latest
```
```
docker push insommnia/yaremko-test-nginx:latest
```

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/VirtualBox_Ubuntu-50Gb_13_06_2025_10_25_58.png)

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/Снимок_2025-06-13_102641_hub.docker.com.png)

---
### Подготовка cистемы мониторинга и деплой приложения

Уже должны быть готовы конфигурации для автоматического создания облачной инфраструктуры и поднятия Kubernetes кластера.  
Теперь необходимо подготовить конфигурационные файлы для настройки нашего Kubernetes кластера.

Цель:
1. Задеплоить в кластер [prometheus](https://prometheus.io/), [grafana](https://grafana.com/), [alertmanager](https://github.com/prometheus/alertmanager), [экспортер](https://github.com/prometheus/node_exporter) основных метрик Kubernetes.
2. Задеплоить тестовое приложение, например, [nginx](https://www.nginx.com/) сервер отдающий статическую страницу.

Способ выполнения:
1. Воспользоваться пакетом [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus), который уже включает в себя [Kubernetes оператор](https://operatorhub.io/) для [grafana](https://grafana.com/), [prometheus](https://prometheus.io/), [alertmanager](https://github.com/prometheus/alertmanager) и [node_exporter](https://github.com/prometheus/node_exporter). Альтернативный вариант - использовать набор helm чартов от [bitnami](https://github.com/bitnami/charts/tree/main/bitnami).

### Деплой инфраструктуры в terraform pipeline

1. Если на первом этапе вы не воспользовались [Terraform Cloud](https://app.terraform.io/), то задеплойте и настройте в кластере [atlantis](https://www.runatlantis.io/) для отслеживания изменений инфраструктуры. Альтернативный вариант 3 задания: вместо Terraform Cloud или atlantis настройте на автоматический запуск и применение конфигурации terraform из вашего git-репозитория в выбранной вами CI-CD системе при любом комите в main ветку. Предоставьте скриншоты работы пайплайна из CI/CD системы.

Ожидаемый результат:
1. Git репозиторий с конфигурационными файлами для настройки Kubernetes.
2. Http доступ на 80 порту к web интерфейсу grafana.
3. Дашборды в grafana отображающие состояние Kubernetes кластера.
4. Http доступ на 80 порту к тестовому приложению.
5. Atlantis или terraform cloud или ci/cd-terraform

### Подготовка cистемы мониторинга и деплой приложения. Решение

Используем helm

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```
```
helm repo update
```
```
helm install prometheus-stack  prometheus-community/kube-prometheus-stack
```
```
kubectl --namespace default get secrets prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
prom-operator
```
---

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/VirtualBox_Ubuntu-50Gb_14_06_2025_06_44_33.png)

Далее создаем сервис для проброса портов:

```.yaml
apiVersion: v1
kind: Service
metadata:
  name: grafana
spec:
  type: NodePort
  selector:
    app.kubernetes.io/name: grafana
  ports:
    - name: http
      nodePort: 30902
      port: 3000
      targetPort: 3000
```
Пилим:
```
kubectl apply -f grafana.yaml
```
Смотрим. Огнище

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/VirtualBox_Ubuntu-50Gb_14_06_2025_15_31_03.png)

Далее на нужно сдклать пропихун нашего приложения:

```.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: diplom-nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: yaremko-test-nginx
        image: insommnia/yaremko-test-nginx:latest
        ports:
        - containerPort: 80
```
```
kubectl apply -f deploy.yaml
```
Смотрим что почем. 
```
kubectl get pod -o wide
```
Пропих засчитан.

Далее нужен еще сервис, что ты погляделки устроить.
```.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - name: web
      nodePort: 30903
      port: 80
      targetPort: 80
```
Пишнули:
```
kubectl apply -f service.yaml
```
Чекнули:
```
kubectl get svc -w
```

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/VirtualBox_Ubuntu-50Gb_14_06_2025_16_51_16.png)

Все конфиги здеся:

[configs](https://github.com/s-bessonniy/devops-diplom-yandexcloud/tree/main/configs)

### Установка и настройка CI/CD

Осталось настроить ci/cd систему для автоматической сборки docker image и деплоя приложения при изменении кода.

Цель:

1. Автоматическая сборка docker образа при коммите в репозиторий с тестовым приложением.
2. Автоматический деплой нового docker образа.

Можно использовать [teamcity](https://www.jetbrains.com/ru-ru/teamcity/), [jenkins](https://www.jenkins.io/), [GitLab CI](https://about.gitlab.com/stages-devops-lifecycle/continuous-integration/) или GitHub Actions.

Ожидаемый результат:

1. Интерфейс ci/cd сервиса доступен по http.
2. При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр Docker образа.
3. При создании тега (например, v1.0.0) происходит сборка и отправка с соответствующим label в регистри, а также деплой соответствующего Docker образа в кластер Kubernetes.

### Установка и настройка CI/CD.Решение

Пятьсот миллиардов раз переределывал, но я смогун.

Юзать, значит, будем GitHub Actions.

Креатим докер токен

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/Opera%20Снимок_2025-06-15_113749_app.docker.com.png)

Добавляем секреты в Git

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/Opera%20Снимок_2025-06-15_113900_github.com.png)

Креатим workflow файл для автоматической сборки приложения nginx:

build.yml
```.yaml
name: Сборка Docker-образа

on:
  push:
    branches:
      - '*'
jobs:
  my_build_job:
    runs-on: ubuntu-latest

    steps:
      - name: Проверка кода
        uses: actions/checkout@v4

      - name: Вход на Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.USER_DOCKER_HUB }}
          password: ${{ secrets.MY_TOKEN_DOCKER_HUB }}

      - name: Сборка Docker-образа
        run: |
          docker build . --file app/Dockerfile --tag yaremko-test-nginx:2.2.2
          docker tag yaremko-test-nginx:2.2.2 ${{ secrets.USER_DOCKER_HUB }}/yaremko-test-nginx:2.2.2

      - name: Push Docker-образа в Docker Hub
        run: |
          docker push ${{ secrets.USER_DOCKER_HUB }}/yaremko-test-nginx:2.2.2
```

Посмотрим что кого:

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/Opera%20Снимок_2025-06-15_114702_github.com.png)

В докер залетело приложение, это то, которое с тегом три гуся:

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/Opera%20Снимок_2025-06-15_114855_hub.docker.com.png)

Далее креатим файл deploy.yaml

```.yaml
name: Сборка и Развертывание
on:
  push:
    branches:
      - '*'
  create:
    tags:
      - '*'

env:
  IMAGE_TAG: insommnia/yaremko-test-nginx

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Проверка кода
        uses: actions/checkout@v4

      - name: Установка Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Вход на Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.USER_DOCKER_HUB }}
          password: ${{ secrets.MY_TOKEN_DOCKER_HUB }}

      - name: Определяем версию
        run: |
          echo "GITHUB_REF: ${GITHUB_REF}"
          if [[ "${GITHUB_REF}" == refs/tags/* ]]; then
            VERSION=${GITHUB_REF#refs/tags/}
          else
            VERSION=$(git log -1 --pretty=format:%B | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
          fi
          if [[ -z "$VERSION" ]]; then
            echo "No version found in the commit message or tag"
            exit 1
          fi
          VERSION=${VERSION//[[:space:]]/}  # Remove any spaces
          echo "Using version: $VERSION"
          echo "VERSION=${VERSION}" >> $GITHUB_ENV

      - name: Сборка и push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: app/Dockerfile
          push: true
          tags: ${{ env.IMAGE_TAG }}:${{ env.VERSION }}

  deploy:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Проверка кода
        uses: actions/checkout@v4

      - name: Установка kubectl
        run: |
          curl -LO "https://dl.k8s.io/release/v1.30.3/bin/linux/amd64/kubectl"
          chmod +x ./kubectl
          sudo mv ./kubectl /usr/local/bin/kubectl
          kubectl version --client

      - name: Конфигурирование kubectl, развертыввание и деплой
        run: |
          echo "${{ secrets.KUBECONFIG }}" > config.yml
          export KUBECONFIG=config.yml
          kubectl config view
          kubectl get nodes
          kubectl get pods --all-namespaces
          kubectl delete -f configs/deploy.yaml
          kubectl get pods --all-namespaces
          kubectl apply -f app/deploy.yaml
    env:
      KUBECONFIG: ${{ secrets.KUBECONFIG }}
```

Смотрим:

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/Opera%20Снимок_2025-06-15_121134_github.com.png)

Браузер:

![](https://github.com/s-bessonniy/devops-diplom-yandexcloud/blob/main/screenshots/VirtualBox_Ubuntu-50Gb_15_06_2025_12_03_06.png)

Файлы:

[тута](https://github.com/s-bessonniy/devops-diplom-yandexcloud/tree/main/app)

---
## Что необходимо для сдачи задания?

1. Репозиторий с конфигурационными файлами Terraform и готовность продемонстрировать создание всех ресурсов с нуля.
2. Пример pull request с комментариями созданными atlantis'ом или снимки экрана из Terraform Cloud или вашего CI-CD-terraform pipeline.
3. Репозиторий с конфигурацией ansible, если был выбран способ создания Kubernetes кластера при помощи ansible.
4. Репозиторий с Dockerfile тестового приложения и ссылка на собранный docker image.
5. Репозиторий с конфигурацией Kubernetes кластера.
6. Ссылка на тестовое приложение и веб интерфейс Grafana с данными доступа.
7. Все репозитории рекомендуется хранить на одном ресурсе (github, gitlab)

