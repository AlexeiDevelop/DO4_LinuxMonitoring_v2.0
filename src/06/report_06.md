Качаем утилиту и командой указываем пути до файла - формат смешанный

goaccess /home/patrickm/projects/DO4_LinuxMonitoring_v2.0.ID_356280-1/src/04/*.log --log-format=COMBINED

goaccess /home/patrickm/projects/DO4_LinuxMonitoring_v2.0.ID_356280-1/src/04/*.log \
>   --log-format=COMBINED \
>   --date-format=%d/%b/%Y \
>   --time-format=%H:%M:%S \
>   -o report.html \

goaccess /home/patrickm/projects/DO4_LinuxMonitoring_v2.0.ID_356280-1/src/04/*.log \
   --log-format=COMBINED \
   --date-format=%d/%b/%Y \
   --time-format=%H:%M:%S \
   -o report.html \
