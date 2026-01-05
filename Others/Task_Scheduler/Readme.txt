#--Batch Server (BAT2)--#
-Path - D:\DBBSetup\MonitoringScript\SSM_Scripts\
#--Task Name--#
-SetupFile-Validation
-Process-Status-Validation
-EnvironmentValidationReport
-InstanceRebootedStatus

#--WEB(WEB1)--#
-Path D:\WebServer\SSM_Scripts\
#--Task Name--#
-Services-WebSite-Validation
-CoreIssue-WebSite-Validation

#--WCF(WCF1)---#
-Path D:\WebServer\SSM_Scripts\
#--Task Name--#
-CoreCardServices-Validation
-WCF-Validation
-NetworkmessageAPI

#--KMS(KMS1)--#
Path D:\SSM_Scripts\
#--Task Name--#
-KMS-Validation

#--E-WEB(WEB1)--
-Path D:\WebServer\SSM_Scripts\
#--Task Name--
-CoreCredit_WebSite_Validation
