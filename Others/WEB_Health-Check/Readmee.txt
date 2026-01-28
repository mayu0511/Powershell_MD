WEB
https://10.103.66.100/HealthWebServerApp/api/server/health
https://10.103.66.106/HealthWebServerApp/api/server/maintenance/1
https://10.103.66.106/HealthWebServerApp/api/server/maintenance/0

WCF
https://10.103.66.162/HealthWCFApp/api/server/health
https://10.103.66.162/HealthWCFApp/api/server/maintenance/1
https://10.103.66.162/HealthWCFApp/api/server/maintenance/0

sc managesaccount WebServerHealth false
sc create WebServerHealth binPath= "D:\WebServer\ServerHealth\Service\WebServerHealth.exe" DisplayName= "Web Server Health"