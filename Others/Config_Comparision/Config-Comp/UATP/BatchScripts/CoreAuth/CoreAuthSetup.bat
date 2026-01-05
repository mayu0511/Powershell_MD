REM ============= Changes required from here ===============

SET base=D:\DBBSetup

SET PrimaryDBServerODBCName=LISTPLAT

SET CoreAuthDBName=CCGS_CoreAuth

SET CoreLibraryDBName=CCGS_CoreLibrary

SET dbb_trace_path=D:\TraceFiles\CoreAuth\

SET EXECUTABLEPATH=D:\CC_runtime\

SET MailServerName=Dummy

SET CoreAuthScaleFile=scale_appCoreAuth.ini

SET CoreAuthPort=4427

SET ActiveDataCenter=PROD1

SET SourceSinkScaleFile=Scale_MC.ini
SET SourcePort=5011
SET SinkPort=5012

REM ---Merchant Processing
SET SCALE_SERVER_HOST=CCWEBe1PATUATb1
SET SCALE_SERVER_PORT=9999
SET MerchantAuth_SCALE_NAME=appCoreAcquireCoreAuth
SET MerchantAuth_PORT=4426


SET CAuth_PORT=4427
SET CAuth_SCALE_NAME=appCoreAuth
SET Enviroment=Testing
SET PROD1MCConnection1=10.140.46.55
SET PROD1MCConnection2=10.140.46.56
SET PROD2MCConnection1=10.140.50.55
SET PROD2MCConnection2=10.140.50.56

SET MACHINENAME=%COMPUTERNAME%




REM ============= Changes required till here ===============

SET post_dbms_server=%PrimaryDBServerODBCName%
SET post_dbms_name=%CoreAuthDBName%
SET post_dbms_login=windowslogin
SET post_dbms_passwd=windowslogin

SET cauth_dbms_server=%PrimaryDBServerODBCName%
SET cauth_dbms_name=%CoreAuthDBName%
SET cauth_dbms_login=windowslogin
SET cauth_dbms_passwd=windowslogin

SET lut_dbms_server=%PrimaryDBServerODBCName%
SET lut_dbms_name=%CoreAuthDBName%
SET lut_dbms_login=windowslogin
SET lut_dbms_passwd=windowslogin

SET fcn_dbms_server=%PrimaryDBServerODBCName%
SET fcn_dbms_name=%CoreLibraryDBName%
SET fcn_dbms_login=windowslogin
SET fcn_dbms_passwd=windowslogin

SET iss_dbms_server=%PrimaryDBServerODBCName%
SET iss_dbms_name=%CoreAuthDBName%
SET iss_dbms_login=windowslogin
SET iss_dbms_passwd=windowslogin

SET CORECARD_DEVELOPER=Dummy

SET dbbPath=%base%\DSLs\CoreAuth\
SET COREAUTHPATH=%base%\DSLs\CoreAuth\
SET ScalePath=%base%\ScaleFiles\

SET HSM=-1

REM Final Auth Recon

SET AUTHINTEGRATIONWSDL=%base%\WSDL\Final\FinalServices.wsdl
SET AUTHINTEGRATIONMETHOD=Authorization
SET PINGMETHOD=Ping
SET FINALSUPPORTEMAILID=Dummy 
SET CORECARDSUPPORTEMAILID=Dummy



REM=====================VARIABLES INTRODUCED AFTER 9.00.03

SET COLUMN1=123
SET COLUMN2=123
SET COLUMN3=123
SET COLUMN4=123
SET COLUMN5=123
SET ToEmailId=Dummy
SET EmailId=Dummy

SET AuthAPIHost=authengine.prod.getfinal.com
SET AuthAPIURL=/authorization
SET AuthAPIPort=443

SET APIConnectTimeout=1000
SET APISendTimeout=1000
SET APIReciveTimeout=1000
SET APIServiceType=xmlhttpcurl
SET APIWEBTimeout=2
SET APISourceDestinationType=json
SET APICallMethod=JSON

SET PingAPIHost=authengine.prod.getfinal.com
SET PingAPIURL=/ping
SET PingAPIPort=443
SET PingTimeout=2


REM=====================VARIABLES INTRODUCED AFTER 11.00.05


REM -------------------------------------------------
REM ---ADD BELOW ENV VARIABLES for Credit Stack  ----
REM -------------------------------------------------
REM ---------- Credit Stack End Point Auth ----------
REM -------------------------------------------------
SET CSAPICallMethod=JSON
SET CSAuthAPIURL=/services/auth
SET CSAuthAPIHost=bsystems.creditstacks.com
SET CSAuthAPIPort=443
SET CSAPIConnectTimeout=2000
SET CSAPISendTimeout=2000
SET CSAPIReciveTimeout=2000
SET CSAPIServiceType=xmlhttpcurl
SET CSAPIWEBTimeout=2
SET CSAPISourceDestinationType=json


SET CSAUTHINTEGRATIONWSDL=%base%\WSDL\Final\FinalServices.wsdl
SET CSAUTHINTEGRATIONMETHOD=Authorization
REM -------------------------------------------------

SET MailReciever=Dummy
SET MailSender=Dummy
SET mcoutput_path=Dummy
SET SCALE_RESTART_INI=Dummy

SET KafkaSorceAuthQueue=SourceAuthData
SET KafkaSorceAuthHost=10.206.1.121
SET KafkaCoreAuthQueue=AuthData
SET KafkaCoreAuthHost=10.206.1.121

REM SET ScalePathSourceSink=%ScalePath%Scale_MC_%COMPUTERNAME%
SET MastercardInterfaceProcessor=0.0.0.0(5545)

SET emKMSdefaultMachines=CCKMSe1PATUATb1 CCKMSe1PATUATb2

SET emThalesConnectionAddrBase=patuat.hsm.infra.marcus.com patuat-apps.hsm.infra.marcus.com


IF EXIST "RTMConfig.bat" (
call RTMConfig.bat
)



SET FilePath=%base%\Batchscripts\CoreAuth\
SET Network_File_Path=%dbb_trace_path%\NetworkMessage\

REM SET enum default values as 1 for all other processes execpt Mastercard Source workflows
SET KMSPRESENT=1
SET CMPRESENT=1

REM SET enum POD default values as POD1 and POD Supported as 0
SET DefaultPODNumber=POD1
SET PoddingSupported=0

SET CACertificate=D:\\DBBSetup\\BatchScripts\\CoreAuth\\PRDBankNetCASubG2.pem
SET DSLName=CS_MC_SIM
SET TLS12Required=YES
if /I %TLS12Required%==YES SET DSLName=CS_MC_TLS12
SET SendEchoTestMessage=1
SET emThalesMonitorInterval=120
SET emThalesCBTestInterval=300

SET Environment=PLAT
REM ******* ManualAdmin0800Msg - IP Address and Port for ManualAdmin Message Wf. This should be the IPAddress and port of 0302MsgScaleSource.
SET ManualAdmin0800Msg=%COMPUTERNAME%(5543)

REM ******* 0302MsgScaleSource - IP Address and Port for 0302MsgSource wf. IPAddress should always be the IPAddress of source wf machine. Port should not conflict with any other listner port.
SET 0302MsgScaleSource=%COMPUTERNAME%(5543)

REM ******* ICANumber - ICA Number given by mastercard.
SET ICANumber=019800

REM ******* GSINumber - GSI Number given by mastercard.
SET GSINumber=525363

SET NetworkManagementInformationCode=001
SET MCMessage_To_RemotePOD=%COMPUTERNAME%(6666)
SET MastercardInterfaceProcessor_SIM=%COMPUTERNAME%(6666)

REM ************ Replace existing variable MastercardInterfaceProcessor_SIM by AcrossPODServer **************************
SET AcrossPODServer=localhost(6666)

REM ************ it is required to be SETup only for local env**************************
SET SourceSinkScaleFile_AcrossPOD=Scale_MC_SIM.ini

SET HSMCommandCall=1
SET ShardMethod=0
SET SendActivateSessionOnReconnect=1
SET _emRatioMinMaxLimit=1
SET ReCheckFlag=1
SET ParseDE110UsingDatasetID=0
SET UpdateATCOnArQCSuccess=1
SET _emDoubleDecimalPlaces=12
SET _emExprNvlCurrencyCorrect=0
SET PanhashIsUnique=0
SET _emConsiderServiceExecErrCritical=0
SET UpdateATCOnARQCSuccess=1
SET Key_Family_For_Keyed_Hash=16
SET PANDecryptionMaxLimit=100

