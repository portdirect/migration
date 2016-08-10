import multiprocessing

bind = '127.0.0.1:8080'
user = 'root'
group = 'root'

timeout = 30
backlog = 2048
keepalive = 2

workers = 1

loglevel = 'info'
errorlog = '-'
accesslog = '-'
