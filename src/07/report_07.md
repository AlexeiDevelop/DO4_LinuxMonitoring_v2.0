
patrickm@ws22:~/projects/DO4_LinuxMonitoring_v2.0.ID_356280-1/src/06$ sudo groupadd --system prometheus
patrickm@ws22:~/projects/DO4_LinuxMonitoring_v2.0.ID_356280-1/src/06$ sudo useradd -s /sbin/nologin --system -g prometheus prometheus
patrickm@ws22:~/projects/DO4_LinuxMonitoring_v2.0.ID_356280-1/src/06$ sudo mkdir /etc/prometheus
patrickm@ws22:~/projects/DO4_LinuxMonitoring_v2.0.ID_356280-1/src/06$ sudo mkdir /var/lib/prometheus
patrickm@ws22:~/projects/DO4_LinuxMonitoring_v2.0.ID_356280-1/src/06$ cd /tmp
patrickm@ws22:/tmp$ 
Качаем под нобходимую архитектуру у нас ARM64 LTS: wget https://github.com/prometheus/prometheus/releases/download/v3.5.0/prometheus-3.5.0.linux-arm64.tar.gz

- ```скачиваем Prometheus```<br>
    ![alt text](01.png)

## Распаковываем:
tar -zxvf prometheus-3.5.0.linux-arm64.tar.gz 


## Переходим в разархивированный каталог:
patrickm@ws22:/tmp$ cd prometheus-3.5.0.linux-arm64/

## Переносим бинарники и конфиг в ранее созданные папки:
patrickm@ws22:/tmp/prometheus-3.5.0.linux-arm64$ sudo mv prometheus /usr/local/bin
patrickm@ws22:/tmp/prometheus-3.5.0.linux-arm64$ sudo mv promtool /usr/local/bin
patrickm@ws22:/tmp/prometheus-3.5.0.linux-arm64$ sudo mv prometheus.yml /etc/prometheus/

## Назначаем владельца prometheus для всех путей:
patrickm@ws22:/tmp/prometheus-3.5.0.linux-arm64$ sudo chown prometheus:prometheus /usr/local/bin/prometheus
patrickm@ws22:/tmp/prometheus-3.5.0.linux-arm64$ sudo chown prometheus:prometheus /usr/local/bin/promtool
patrickm@ws22:/tmp/prometheus-3.5.0.linux-arm64$ sudo chown -R prometheus:prometheus /etc/prometheus
patrickm@ws22:/tmp/prometheus-3.5.0.linux-arm64$ sudo chown -R prometheus:prometheus /var/lib/prometheus

## Создаем unit-файл
sudo nano /etc/systemd/system/prometheus.service
- и заполняем его конфигурацией для запуска

[Unit]
Description=Prometheus Monitoring Service
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.listen-address=:9090

Restart=on-failure

[Install]
WantedBy=multi-user.target

## Применяем unit и зупускаем Prometheus 
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus
sudo systemctl status prometheus

- ```статус Prometheus```<br>
    ![alt text](02.png)

- ```Убедимся в наличие открытого соединения на порту 9090```<br>
    ![alt text](03.png)

- ```Необходимо пробросить порты в настройках VB после чего можно открыть интерфейс по адресу http://127.0.0.1:9090```<br>
    ![alt text](04.png)

## Теперь переходим к Grafana
- Для установки пользовался гайдом: https://grafana.com/docs/grafana/latest/setup-grafana/installation/debian/
- Поэтому нет смысла описывать каждый шаг

- На моменте получения ключа был затык - сервер не выдавал его - излечимо сменой IP адреса через подключение ВПН
- ```Лечение проблемы```<br>
    ![alt text](05.png)

- ```Используем stable версию и обновляем```<br>
    ![alt text](06.png)

- ```Пробуем запускать сервер - команды на скрине```<br>
    ![alt text](07.png)

- ```Для доступа с локальной машины нужно также пробросить порты```<br>
    ![alt text](08.png)

- https://grafana.com/docs/grafana/latest/getting-started/build-first-dashboard/

- ```Тогда мы сможем зайти по порту 3000 http://localhost:3000 - как и сказано в Guide```<br>
    ![alt text](09.png)

- Теперь для сбора метрик нам нужен node_exporter ищем и качаем его также с официального сайта: https://prometheus.io/download/

- ```Скачиваем в папку tmp```<br>
    ![alt text](10.png)

- Перенесем исполняемый файл
patrickm@ws22:/tmp$ sudo mv node_exporter-1.10.2.linux-arm64/node_exporter /usr/local/bin/

- Создаем службу systemd:
patrickm@ws22:/tmp$ sudo nano /etc/systemd/system/node_exporter.service

- ```Редактируем конфиг файл```<br>
    ![alt text](11.png)

- ```Запускаем службу```<br>
    ![alt text](12.png)

- ```Редактируем yaml файл - добавляем node_exporter на хост 9100```<br>
    ![alt text](13.png)

- Перезапускаем Prometheus

- ```Проверяем - сервис подключен```<br>
    ![alt text](14.png)

- Пробуем счетчик состояния процессора с момента запуска системы
- ```Пробуем сбор метрик по процессору```<br>
    ![alt text](15.png)

- ```Добавляем источник даннх Prometheus для Grafana```<br>
    ![alt text](16.png)

- ```Пробуем выбрать ту же метрику в Grafana```<br>
    ![alt text](17.png)

- ```Дополняя метрики регулируем вывод - сейчас показан выход только по CPU 0```<br>
    ![alt text](18.png)

- Дополняя фильтарми мы можем скорректировать вывод метрики
- mode=idle - выбираем время когда CPU не был занят процессами
- rate([1m]) - скорость изменения значений 1 минута

- ```В таком варианте получим нагружку CPU по времени, обратному idle - то есть простою CPU. Иными словами загрузка CPU в процентах в минуту```<br>
    ![alt text](19.png)

- ```Для доступной оперативной памяти, свободное место и кол-во операций ввода/вывода на жестком диске - синаксис следующий (также выведет в процентах)```<br>
    ![alt text](20.png)

- Теперь запустим bash скрипт из части 2
- ```Папки созданы в директории 02```<br>
    ![alt text](21.png)

- ```Обновляем и видим изменения на графиках - нагрузка ЦПУ разово возросла, Кол-во доступной памяти резко сократилось```<br>
    ![alt text](22.png)

- Для 4 праметра - нагрузка жесткого диска (место на диске и операции чтения/записи). Собран такой query

- ```Синаксис для 4 параметра```<br>
    ![alt text](23.png)

• node_disk_io_time_seconds_total — накопленное время, когда диск был занят I/O.
 • rate(...[5m]) → доля времени «занят» в секунду (например, 0.73 = 73%).
 • * 100 → перевод в проценты.
 • clamp_max(<vector>, 100) — ограничиваем сверху на 100 (правильный порядок аргументов: сначала вектор, потом скаляр!).

- ```Запускаем утилиту на ВМ```<br>
    ![alt text](24.png)

- ```Смотрим на изменения графиков```<br>
    ![alt text](25.png)

- Видно что тест отработал, кол-во доступной памяти ожидаемо не изменилось, однако тест почти не оказал влияние на оперативную память, попробуем увеличить показатели

- ```Увеличиваем показатели для теста```<br>
    ![alt text](27.png)

- ```Теперь видны изменения и в нагрузке оперативной памяти```<br>
    ![alt text](26.png)