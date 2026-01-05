rem ============= Changes required from here ===============
REM SET PHFileVersionName = 24.2.6
REM SET PHFileEnvName = P2MA_PLATQA

SET base=D:\DBBSetup

SET dump=D:\DBBSetup\Dump

SET PrimaryDBServerODBCName=LISTPLAT

SET DB_Server_NAME=CCAPPLIST1

SET CoreAuthDBName=CCGS_CoreAuth

SET CoreISSUEDBName=CCGS_CoreIssue

SET CoreLibraryDBName=CCGS_CoreLibrary

SET CoreMoneyDBName=CCGS_CoreCredit

SET CoreAPPDBName=CCGS_CoreApp

SET ReplicatedDBServerODBCName=LISTRPT

SET ReportsCoreAuthDBName=CCGS_RPT_CoreAuth

SET ReportsCoreISSUEDBName=CCGS_RPT_CoreIssue

SET ReportsCoreLibraryDBName=CCGS_RPT_CoreLibrary

SET ReportsCoreMoneyDBName=CCGS_RPT_CoreCredit

SET ReportsCoreAPPDBName=CCGS_RPT_CoreApp

rem ManualAuth Environmental Varialbe
set CAuth_SCALE_NAME=appCoreAuth
set CAuth_PORT=4427
set SCALE_SERVER_HOST=CCWEBe1QAb1
set SCALE_SERVER_PORT=9999

REM For Coreapp Setup (Testing|Production)
set ExperianSetup=Testing

Set Enviroment=Testing

REM PIIHub API Call from Which Environment DEV,PROD,QA,UAT,PATUAT,PATQA,PERFPROD
REM Earlier variable already introduced, For Local Testing, Use DEV
SET PlatPIIHubEnv=QA
SET PlatPIIHubTokenEnv=QA
SET PlatAutoRewardRedeem=QA
SET RelaxIssueStatusCheckForActivation=TEST

SET emKMSdefaultMachines=CCKMSe1QAb1 CCKMSe1QAb2 

SET emThalesConnectionAddrBase=qa.hsm.infra.marcus.com qa-apps.hsm.infra.marcus.com



Rem Update PlatModelScore value 
SET PlatModelScore=QA

rem 1 for 2 calls | 0 for 1 call
Set TokenRefreshCall=0

REM When UseCCardOrCCard2_IPM=0 then IPM Transaction will be inserted in CCard_Primary, When 1 then IPM Transaction will be inserted in CCard_Primary2
SET UseCCardOrCCard2_IPM=1

REM changed Value of MultiPODEnabled_IPM from 0 to 1 to support MultiPOD in PLAT Prod Env
SET MultiPODEnabled_IPM=1

rem ============= Changes required till here ===============

SET CoreIssueScaleFile=scale_appCoreIssue.ini

SET CoreIssuePort=4421

SET CoreIssueServicesScaleFile=scale_appServices.ini

SET CoreIssueServicesPort=4422

SET CoreIssueLink=https://ccApps.corecard.com/appCoreIssue.aspx

SET EXECUTABLEPATH=D:\CC_Runtime

SET dbb_trace_path=D:\TraceFiles\CoreIssue

SET CIReportsFolder=CoreIssueReports

set LettersVirDir=CoreIssueReports

SET MailServerName=Dummy

SET post_dbms_server=%PrimaryDBServerODBCName%
SET post_dbms_name=%CoreISSUEDBName%
SET post_dbms_login=windowslogin
SET post_dbms_passwd=windowslogin

set report_dbms_server=%ReplicatedDBServerODBCName%
set report_dbms_name=%ReportsCoreISSUEDBName%
set report_dbms_login=windowslogin
set report_dbms_passwd=windowslogin

set CauthReport_dbms_server=%ReplicatedDBServerODBCName%
set CauthReport_dbms_name=%ReportsCoreAuthDBName%
set CauthReport_dbms_login=windowslogin
set CauthReport_dbms_passwd=windowslogin

set CLReport_dbms_server=%ReplicatedDBServerODBCName%
set CLReport_dbms_name=%ReportsCoreLibraryDBName%
set CLReport_dbms_login=windowslogin
set CLReport_dbms_passwd=windowslogin

SET fcn_dbms_server=%PrimaryDBServerODBCName%
SET fcn_dbms_name=%CoreLibraryDBName%
SET fcn_dbms_login=windowslogin
SET fcn_dbms_passwd=windowslogin
SET FCN_DBMS_PASSWORD=windowslogin

SET acq_dbms_server=%PrimaryDBServerODBCName%
SET acq_dbms_name=%CoreISSUEDBName%
SET acq_dbms_login=windowslogin
SET acq_dbms_passwd=windowslogin

SET iss_dbms_server=%PrimaryDBServerODBCName%
SET iss_dbms_name=%CoreISSUEDBName%
SET iss_dbms_login=windowslogin
SET iss_dbms_passwd=windowslogin

SET lut_dbms_server=%PrimaryDBServerODBCName%
SET lut_dbms_name=%CoreISSUEDBName%
SET lut_dbms_login=windowslogin
SET lut_dbms_passwd=windowslogin

SET cauth_dbms_server=%PrimaryDBServerODBCName%
SET cauth_dbms_name=%CoreAuthDBName%
SET cauth_dbms_login=windowslogin
SET cauth_dbms_passwd=windowslogin

set capp_dbms_server=%PrimaryDBServerODBCName%
set capp_dbms_name=%CoreAPPDBName%
set capp_dbms_login=windowslogin
set capp_dbms_passwd=windowslogin

set portal_dbms_server=%PrimaryDBServerODBCName%
set portal_dbms_name=%CoreMoneyDBName%
set portal_dbms_login=windowslogin
set portal_dbms_passwd=windowslogin

set PortalReport_dbms_server=%ReplicatedDBServerODBCName%
set PortalReport_dbms_name=%ReportsCoreMoneyDBName%
set PortalReport_dbms_login=windowslogin
set PortalReport_dbms_passwd=windowslogin

set cappReport_dbms_server=%ReplicatedDBServerODBCName%
set cappReport_dbms_name=%ReportsCoreAPPDBName%
set cappReport_dbms_login=windowslogin
set cappReport_dbms_passwd=windowslogin

SET cod_dbms_server=%post_dbms_server%
SET cod_dbms_name=%post_dbms_name%
SET cod_dbms_login=%post_dbms_login%
SET cod_dbms_passwd=%post_dbms_passwd%

SET sales_dbms_server=%post_dbms_server%
SET sales_dbms_name=%post_dbms_name%
SET sales_dbms_login=%post_dbms_login%
SET sales_dbms_passwd=%post_dbms_passwd%

SET coll_dbms_server=%post_dbms_server%
SET coll_dbms_name=%post_dbms_name%
SET coll_dbms_login=%post_dbms_login%
SET coll_dbms_passwd=%post_dbms_passwd%

SET AppDashBoard_dbms_server=%post_dbms_server%
SET AppDashBoard_dbms_name=%post_dbms_name%
SET AppDashBoard_dbms_login=%post_dbms_login%
SET AppDashBoard_dbms_passwd=%post_dbms_passwd%

SET dbbPath=%base%\DSLs\Modularization\CoreIssue

SET ClearingQueue=.\private$\Clearing
SET interface_ci=DIRECT=OS:SKulshreshtha\private$\interface
set CoreAuthQueue=DIRECT=OS:SKulshreshtha\private$\CoreAuth

set Mayors_SettlementFileIN=%base%\SettlementFileIN
set Mayors_SettlementFileOUT=%base%\SettlementFileOUT
set Mayors_SettlementFileERROR=%base%\SettlementFileERROR
set Mayors_SettlementFileLOG=%base%\SettlementFileLOG

SET OUTGOING_EMBOSSING_PATH=%base%\Dump\Embossing\
REM SET OUTGOING_STMT_PATH=%dump%\Embossing\
SET ScalePath=%base%\ScaleFiles


SET COREISSUEPATH=%base%\DSLs\Modularization\CoreIssue
SET scriptpath=%base%\BatchScripts\CoreIssue
SET COREAUTHPATH=%base%\DSLs\CoreAuth
SET CODEDIR=%EXECUTABLEPATH%
SET SYSTEMDLLDIR=%EXECUTABLEPATH%


SET Bulk_Account_File=%base%\Outgoing
SET Bulk_Load_File=%base%\Outgoing
SET dbbcode=%codedir%
SET wd=%dbbcode%

set EmailId=Dummy
set Email_Operation=Dummy
set LostStolenCSREmailId1=Dummy
set LostStolenCSREmailId2=Dummy
set RequestCustomerServiceHelpCSREmailId1=Dummy
set RequestCustomerServiceHelpCSREmailId2=Dummy
set RequestCompanionCardCSREmailId1=Dummy
set RequestCompanionCardCSREmailId2=Dummy 
set TxnDisputeCSREmailId1=Dummy
set TxnDisputeCSREmailId2=Dummy
set RequestReplacementCardCSREmailId1=Dummy
set RequestReplacementCardCSREmailId2=Dummy
set NewCardRequestCSREmailId1=Dummy
set NewCardRequestCSREmailId2=Dummy

rem This variable would be use to perform auth with post function or without post function, so user need to set one of the variable in his/her set file.
set Auth=AuthWithoutPosting
rem set Auth=AuthWithPosting

SET ACHFileIN=%base%\ACH\IN
REM This is not in used
REM SET ACHFileOUT=%dump%\Final\ACH\Outgoing
SET ACHRtnFileOUT=%base%\ACH\Outgoing
SET ACHFileERROR=%base%\ACH\Error
SET ACH_LOG=%base%\ACH\Log

SET CLEARING_IN=%base%\ACH\clearing


SET CORECARD_DEVELOPER=Dummy
SET CORECARD_IS_DEVELOPMENT=0

SET LogClearing=Yes
SET TxnsPerBatch=200
SET InsEnrollmentQueue=Dummy
SET LETTERS_OUTGOING_FILE_PATH=Dummy
SET CBRCHANGEDATE=06012005010000
SET NEWSTATEMENTDATE=06012005010000
SET NEWCREDITDATE=06012005010000
SET MERCHANTARDATE=06012005010000
SET NEWDIRECTEDPAYMENTDATE=06012005010000
SET NEWCHARGEOFFDATE=06012005010000
SET NEWLATEFEEDATE=06012005010000
SET NEWACCTLEVELPAYMENT=06012005010000
SET FIXEDPAYMENTS1=06012005010000
SET INTERESTROUNDOFFDATE=06012005010000
SET DORMANCYIMPLEMENTATION=DormancyThin

set PATCH372=01032009010000
set PATCH37=04202008230200
Set OLDOVERDRAFTFEE=03202008010000
set PPRELEASE2A=06162008230200
set PPRELEASE3=11022008010000
set NEWFRAUDAUTHCONTROLS=11022008010000
set NEWCREDITREGULATIONDATE=02212010230001
rem set ROLLCPMCONTROL=11172004230001
set NEWINSCLAIMSDISASTERDATE=12312009010000

rem Report Environment  Variable 
set ReportExtension=.aspx

rem This Variable would be use to Generate HotLink from CoreIssue to SelfService. Use Selfservice's App. Port No. in place of 4568.
set SelfServiceLink=http://10.150.0.58/appMayorsSS.aspx
set SelfServiceAppName=appMayorsSS

rem The right parameter is the name of the folder where your image is stored under the dbbimage folder
set CardImagePath=CardImageManagement

rem set PathName=%base%\StarCAF
rem set OutputFolder=%base%\StarCAF\output
rem set CAFOutputFolder=%base%\StarCAF
Set DriverPath=%base%

REM Set NetworkDrive=%base%\BackcardSetup

set AuthenticationMode=WA
REM The AuthenticationMode var must have its value in ALL CAPS like (WA or SA)

Set Recipients_ID=Dummy
Set Outlook_ID=Dummy
Set Sender_ID=Dummy

rem SET PortalBulkCardFile=%base%\FILES
rem SET PortalBulkLoadFile=%base%\FILES



rem Credit Bureau Reporting Env var
set CBRCHANGEDATE=05302005230000
set CBREPORTING_FILE_PATH=D:\DBBSetup\Dump\CBReporting\CBR
set CBREmailFrom=Dummy
set CBRNotifyEmail=Dummy

SET EmailStatementLink=http://10.150.0.58/handlerSelfServicelogin.html 
SET EmailStatementClientName=Dummy
SET EmailStatementSubject=Your monthly statement ready for viewing!!!



rem Set the CBR files location

rem Set CBR_OutputFolder=%base%\CBR\Output
rem Set CBR_ErrorFolder=%base%\CBR\Error
rem Set CBR_LogFileFolderName=%base%\CBR\log
rem set PathNameCBR=%base%\CBR

SET EmailFooter=Frys Customer Care

SET PassEncryBatchSize=5000 

set NEWFEECREDIT=10312010230000
set KBDATEOFTOTALDUE=05202010230000
REM SET NEWINSCLAIMSDISASTERDATE=08202012020000
SET INOVICENOIMPLEMENTATION=08202012000000
SET REVERSALTRANCODEDATE=08202012230000
SET EmailFooterPhone=1-866-322-8008
SET regzeffectivedate=08202012230000
SET DBB_DOLINE_NEWLOGIC_DATE=08/20/2012 23:00:01:000
SET DBB_TEMPORAL_NEWLOGIC_DATE=08/20/2012 23:00:01:000
SET BTLateFeeCalc=08202012230000
SET NewMinimumDueCalc=08202012230000
SET OverPaymentAllocThreshold=08202012230000
SET Quickkeydelimator=//
SET MinimumDueAdjOnCredit=08202012230000
SET CurrentDueCalculation=08202012230000
SET RoudingMinimumDue=08202012230000
SET MinimumDueAdjOnCredits=08202012230000
SET MiniAmtDueThreshold=08202012230000
SET PRINCIPALDEFERRMENTDATE=08202012235958
SET feeCredffectivedate=08202012230000
SET BaseCreditDistribution=08202012230000
REM SET NoBlobStartDate=0820201230000
SET NoBlobStartDate=04162013230000
SET InterestLeapYearNew=08202012230000

SET envInstAID_US=1042
SET envInstAID_UK=1050
SET envCPMAID_US=5081
SET envCPMAID_UK=5095

SET PayVarEnhancement=11212013064500
SET NBReageEntry=11212013064500

SET WaiveDueAsStatus=01152014230000
SET RFEESCPLAN=01152014230000
SET ChargeOffCT8415=01292014035400
set WaiveDueAsStatusSetting=03212014042500

set PaymentEnhancement=04282014021500
set DNApplyPayEnhancement=04282014021500

set BacktoBackPayment=05192014014500

SET AccountLevelTotalDueIssue=06102014024500
Set AdjMinDueTime=06302014044500
SET NewApplicationVersion=1031201423000000
SET HoldStatement=Yes


REM TideWater OTB File Variables
REM OTBFileIN  folder name should be ?TideWater_OTBFile_In? and should have read/write permisssion.

REM SET OTBFileIN=%dump%\TideWater_OTBFile\OTBFile_IN

SET OTBFileIN=\\CCSQL02\TideWater\OTBFile_IN


SET OTBFileOUT=%dump%\TideWater_OTBFile\OTBFile_OUT
SET OTBFileERROR=%dump%\TideWater_OTBFile\OTBFile_ERROR
SET OTBFileLOG=%dump%\TideWater_OTBFile\OTBFile_LOG

REM TideWater Clearing File Variables
SET TideWater_SettlementFileIN=%dump%\TideWater_Clearing\ClearingFileIN
SET TideWater_SettlementFileOUT=%dump%\TideWater_Clearing\ClearingFileOUT
SET TideWater_SettlementFileLog=%dump%\TideWater_Clearing\ClearingFileLOG
SET TideWater_SettlementFileError=%dump%\TideWater_Clearing\ClearingFileERROR

REM TideWater ArrowEye File Validation
SET InputEmbossingFile=%base%\Dump\Embossing\Irving
SET OutputEmbossingFile=%base%\Dump\Embossing\Irving\OUT
SET LogEmbossingFile=%base%\Dump\Embossing\Irving\LOG
SET ErrorFolder=%base%\Dump\Embossing\Irving\ERROR

REM Tidewater ArrowEye Embossing Shipment file Reconciliation
SET TW_EmbossingReconciliationIN=%base%\OutgoingFiles\ArrowEye\TW_ShipmentFile\IN
SET TW_EmbossingReconciliationOUT=%base%\OutgoingFiles\ArrowEye\TW_ShipmentFile\OUT
SET TW_EmbossingReconciliationERROR=%base%\OutgoingFiles\ArrowEye\TW_ShipmentFile\Error
SET TW_EmbossingReconciliationLOG=%base%\OutgoingFiles\ArrowEye\TW_ShipmentFile\Log


REM Set environment variable to access coreapp db from coreissue.

REM VantivRecon files locations

set VantivIN=%dump%\Final\VantivRecon\IN
set VantivOUT=%dump%\Final\VantivRecon\OUT
set VantivError=%dump%\Final\VantivRecon\Error
set VantivLog=%dump%\Final\VantivRecon\Log

REM FINAL ACH

SET FINAL_ACHFileIN=%dump%\Final\ACH\Incoming\IN
SET FINAL_ACHFileOUT=%dump%\Final\ACH\Incoming\OUT
SET FINAL_ACHFileLOG=%dump%\Final\ACH\Incoming\Log
SET FINAL_ACHFileERROR=%dump%\Final\ACH\Incoming\ERROR


REM AuthRecon

SET FinalReconFilePathName=%dump%\Final\AuthReconFile


REM DownloadRoutingFile
SET RoutingRecordFileLocation=%dump%\CreditProcessing\RoutingFile\IN
SET Routing_LOG=%dump%\CreditProcessing\RoutingFile\Log\
SET MailSender=Dummy
SET MailReciever=Dummy
REM set RoutDownloadFileLocation=https://www.frbservices.org/EPaymentsDirectory/FedACHdir.txt
set RoutDownloadFileLocation=https://www.frbservices.org/EPaymentsDirectory/FedACHdir.txt?AgreementSessionObject=Agree

REM This is not in used
REM SET ACHFileOUT_AOC=%dump%\AOC\ACH\Outgoing

SET AOC_ACHFileIN=%dump%\AOC\ACH\Incoming\IN
SET AOC_ACHFileOUT=%dump%\AOC\ACH\Incoming\OUT
SET AOC_ACHFileERROR=%dump%\AOC\ACH\Incoming\ERROR
SET AOC_ACHFileLOG=%dump%\AOC\ACH\Incoming\LOG

set AOC_SettlementFileIN=%dump%\AOC\Settlement\IN
set AOC_SettlementFileOUT=%dump%\AOC\Settlement\OUT
set AOC_SettlementFileERROR=%dump%\AOC\Settlement\ERROR
set AOC_SettlementFileLOG=%dump%\AOC\Settlement\LOG

REM SET OUTGOING_STMT_PATH_AOC=%dump%\AOC\Statement
SET OUTGOING_STMT_PATH_AOC=\\DB02\Mayors\Dump\AOC\Statement


REM Cardopen Service 
SET VantivWSDL=%base%\WSDL\Final\CardOpen.wsdl
SET APIPWD=D7AFD30230D3F6C38C572145595C3B96

SET VantivAPICall=QA

REM UpdateCall 
SET UPDATECALLWSDLPATH=%base%\WSDL\Final\FinalUpdateServices.wsdl
SET UPDATECALLMETHOD=AccountUpdates

SET ARMAST_FILE_PATH=%dump%\R2S\ARMAST_File
SET ARMAST_FILE_NAME=%dump%\R2S\ARMAST_File\ARMAST.dat
SET OUTGOING_STMT_PATH=%dump%\R2S\OutGoingStatement


REM Final ACH Outgoing File New Env variable
SET FinalACHOutgoingFileIN=%dump%\Final\ACH\Outgoing\IN
SET FinalACHOutgoingFileOUT=%dump%\Final\ACH\Outgoing\OUT
SET FinalACHOutgoingFileLOG=%dump%\Final\ACH\Outgoing\LOG
SET FinalACHOutgoingFileERROR=%dump%\Final\ACH\Outgoing\ERROR

REM AOC ACH Outgoing File New Env variable
REM SET AOCACHOutgoingFileIN=%dump%\AOC\ACH\Outgoing\IN
REM SET AOCACHOutgoingFileOUT=%dump%\AOC\ACH\Outgoing\OUT
REM SET AOCACHOutgoingFileLOG=%dump%\AOC\ACH\Outgoing\LOG
REM SET AOCACHOutgoingFileERROR=%dump%\AOC\ACH\Outgoing\ERROR


REM AOC AvidiaBankCAD ACH Outgoing File New Env variable 
SET AvidiaBankCADACHOutgoingFileIN=%dump%\AOC\ACH\Outgoing\AvidiaBankCAD\IN
SET AvidiaBankCADACHOutgoingFileOUT=%dump%\AOC\ACH\Outgoing\AvidiaBankCAD\OUT
SET AvidiaBankCADACHOutgoingFileLOG=%dump%\AOC\ACH\Outgoing\AvidiaBankCAD\LOG
SET AvidiaBankCADACHOutgoingFileERROR=%dump%\AOC\ACH\Outgoing\AvidiaBankCAD\ERROR

REM AOC AvidiaBankUSA ACH Outgoing File New Env variable 
SET AvidiaBankUSAACHOutgoingFileIN=%dump%\AOC\ACH\Outgoing\AvidiaBankUSA\IN
SET AvidiaBankUSAACHOutgoingFileOUT=%dump%\AOC\ACH\Outgoing\AvidiaBankUSA\OUT
SET AvidiaBankUSAACHOutgoingFileLOG=%dump%\AOC\ACH\Outgoing\AvidiaBankUSA\LOG
SET AvidiaBankUSAACHOutgoingFileERROR=%dump%\AOC\ACH\Outgoing\AvidiaBankUSA\ERROR

REM AOC AOCBankandTrust ACH Outgoing File New Env variable 
SET AOCBankandTrustACHOutgoingFileIN=%dump%\AOC\ACH\Outgoing\AOCBankandTrust\IN
SET AOCBankandTrustACHOutgoingFileOUT=%dump%\AOC\ACH\Outgoing\AOCBankandTrust\OUT
SET AOCBankandTrustACHOutgoingFileLOG=%dump%\AOC\ACH\Outgoing\AOCBankandTrust\LOG
SET AOCBankandTrustACHOutgoingFileERROR=%dump%\AOC\ACH\Outgoing\AOCBankandTrust\ERROR

REM IPM Outgoing Settlement
SET OUTGOING_FILES_PATH=%dump%\MasterCard\IPMSettlement\Outgoing\IN
SET OUTGOING_IPMOUT=%dump%\MasterCard\IPMSettlement\Outgoing\OUT
SET OUTGOING_IPMERROR=%dump%\MasterCard\IPMSettlement\Outgoing\ERROR
SET OUTGOING_IPMLOG=%dump%\MasterCard\IPMSettlement\Outgoing\LOG

REM IPM Incoming Settlement
SET IPMFileIN=%dump%\MasterCard\IPMSettlement\Incoming\T112
SET IPMFileOUT=%dump%\MasterCard\IPMSettlement\Incoming\OUT
SET IPM_LOG=%dump%\MasterCard\IPMSettlement\Incoming\LOG
SET IPM_ERROR=%dump%\MasterCard\IPMSettlement\Incoming\ERROR
SET IPMFileArchive=%dump%\MasterCard\IPMSettlement\Incoming\T112\Archive

REM Jazz Migrated Dispute Incoming file Environment variables 
SET DisputeFileIN=%dump%\Dispute\IN
SET DisputeFileOut=%dump%\Dispute\Out
SET DisputeFileERROR=%dump%\Dispute\ERROR
SET DisputeFileLOG=%dump%\Dispute\LOG
SET DisputeFileResponse=%dump%\Dispute\Response\


REM=====================VARIABLES INTRODUCED AFTER 9.00.03

SET APICallMethod=JSON
SET APIConnectTimeout=1000
SET APIReciveTimeout=1000
SET APISendTimeout=1000
SET APIServiceType=xmlhttpcurl
SET APISourceDestinationType=json
SET APIWEBTimeout=10000
SET AUTHAPICONNECTTIMEOUT=1500
SET AUTHAPIRECEIVETIMEOUT=1900
SET AUTHAPISENDTIMEOUT=1700
SET AUTHAPISERVICETYPE=xmlhttpcurl
SET BNFEBRELEASE=1212
SET BTSAgentBranch=Dummy
SET BTSAgentCode=123
SET BTSAgentCountryCode=Dummy
SET BTSAgentRegion=Dummy
SET BTSAgentStateCode=Dummy
SET BTSAgentStateCode=Dummy
SET BTSAgentStateCode=Dummy
SET BTStransactionserviceWsdl=123
SET CLEARING_FILE_PATH=D:\abc\abc\CI
SET EmailSMSFromId=Dummy
SET EXISTING_PEX_PDF_PATH=1212
SET ExpCardSupportFromEmailId=Dummy
SET IC3_Host=dev1-raftwebportal.FTPSllc.com
SET IC3_Port=3109
SET IC3_Url=/FTPS/services/Crdopen2
SET MailSenderName=%MailServerName%
SET NEWADJUSTMENTTXN=Y
SET NEWAUTOINSREFUND=asd
SET OFACEmailId=Dummy
SET OUTGOING_EMBOSSING_PATH_SUPP=""
SET PEX_PDF_PATH=12
SET PortalBulkCardFile=Dummy
SET PortalBulkLoadFile=1212
SET TemplatePath=j:\projectsetup
SET UpdateCallHost=update-api.prod2.getfinal.com
SET UpdateCallURL=/api/update
SET WEBTIMEOUT=15



REM=====================VARIABLES INTRODUCED AFTER 11.00.05

REM --------------------Credit Stack
REM ---ADD and setup below env variable in SetupCI file
SET CreditStackReconFilePathName=%dump%\CreditStack\AuthReconFile


REM --------------------TideWater/AOC
REM ----env variable for Generating Clearing Out File For TideWater/AOC

REM SET OutFileGeneration_TW=%dump%\TideWater_Clearing\ClearingFileOUT
REM SET Logfolder=%dump%\TideWater_Clearing\ClearingFileLOG

REM --------------------FOR Alert, plz update folder and email as per req. 

SET BTSAgentRegion=%dump%
SET BTSAgentBranch=%dump%
SET BTSAgentStateCode=%dump%
SET BTSAgentCountryCode=%dump%
SET BTSAgentCode=%dump%
SET BTSTransactionServiceWsdl=%dump%
SET ALERTS_NO_OF_RETRY=2
SET ALERTS_DURATION_BTW_RETRY=2
REM SET ExpCardSupportFromEmailId=Dummy
REM SET EmailSMSFromId=Dummy
SET SMSgateway=WRONGemail.smsglobal.com
SET MailServerName=%MailServerName%
SET SMSGlobalhttpMaxSplit=2



REM ----env variable for Generating Clearing Out File For PayOpt

Rem PayOpt clearing File
set PayOpt_SettlementFileIN=%dump%\PayOpt\Settelment\IN
set PayOpt_SettlementFileOUT=%dump%\PayOpt\Settelment\Out
set PayOpt_SettlementFileERROR=%dump%\PayOpt\Settelment\Error
set PayOpt_SettlementFileLOG=%dump%\PayOpt\Settelment\Log



REM CreditStack ACH Outgoing File New Env variable 
SET CreditStackACHOutgoingFileIN=%dump%\CreditStack\ACH\Outgoing\IN
SET CreditStackACHOutgoingFileOUT=%dump%\CreditStack\ACH\Outgoing\OUT
SET CreditStackACHOutgoingFileLOG=%dump%\CreditStack\ACH\Outgoing\LOG
SET CreditStackACHOutgoingFileERROR=%dump%\CreditStack\ACH\Outgoing\ERROR


REM CreditStack ACH Incoming/Return File
SET CREDITSTACK_ACHFileIN=%dump%\CreditStack\ACH\Incoming\IN
SET CREDITSTACK_ACHFileOUT=%dump%\CreditStack\ACH\Incoming\OUT
SET CREDITSTACK_ACHFileERROR=%dump%\CreditStack\ACH\Incoming\ERROR
SET CREDITSTACK_ACHFileLOG=%dump%\CreditStack\ACH\Incoming\LOG


SET QRCodeUsername=Core
SET QRCodePassword=BALb6Ph2Ch4Bz8c73mRq6snBKjbA
SET QRCodeWEBTimeout=3000
SET QRCodeConnectTimeout=3000
SET QRCodeSendTimeout=3000
SET QRCodeReciveTimeout=3000
SET QRCodeAPIHost=bsystems.creditstack.com
SET QRCodeAPIURL=/services/getqrcode

REM Deserve ACH Outgoing File New Env variable 
SET DeserveACHOutgoingFileIN=%dump%\Deserve\ACH\Outgoing\IN
SET DeserveACHOutgoingFileOUT=%dump%\Deserve\ACH\Outgoing\OUT
SET DeserveACHOutgoingFileLOG=%dump%\Deserve\ACH\Outgoing\LOG
SET DeserveACHOutgoingFileERROR=%dump%\Deserve\ACH\Outgoing\ERROR


REM Deserve ACH Incoming/Return File
SET DESERVE_ACHFileIN=%dump%\Deserve\ACH\Incoming\IN
SET DESERVE_ACHFileOUT=%dump%\Deserve\ACH\Incoming\OUT
SET DESERVE_ACHFileERROR=%dump%\Deserve\ACH\Incoming\ERROR
SET DESERVE_ACHFileLOG=%dump%\Deserve\ACH\Incoming\LOG


REM Deserve Lock Box Payment Environment variables 
SET DeserveLockBoxIN=%dump%\Deserve\LockBox\IN
SET DeserveLockBoxOUT=%dump%\Deserve\LockBox\OUT
SET DeserveLockBoxLOG=%dump%\Deserve\LockBox\LOG
SET DeserveLockBoxERROR=%dump%\Deserve\LockBox\ERROR


REM --------- Create these folder on approprite folder and set below env variable in CIsetup.bat file.

SET IPMReportFile=%dump%\MasterCard\IPMSettlement\Report\T140
SET IPMReportArchive=%dump%\MasterCard\IPMSettlement\Report\Archive
SET IPMReportLOG=%dump%\MasterCard\IPMSettlement\Report\LOG
SET IPMReportERROR=%dump%\MasterCard\IPMSettlement\Report\ERROR

SET IPMErrorReportFile=%dump%\MasterCard\IPMSettlement\Chargeback\T140
SET IPMErrorReportArchive=%dump%\MasterCard\IPMSettlement\Chargeback\Archive
SET IPMErrorReportLOG=%dump%\MasterCard\IPMSettlement\Chargeback\LOG
SET IPMErrorReportERROR=%dump%\MasterCard\IPMSettlement\Chargeback\ERROR


REM Plat ACH Outgoing ACH Environment variables 
SET PLATACHOutgoingFileIN=%dump%\ACH\Outgoing\IN
SET PLATACHOutgoingFileOUT=%dump%\ACH\Outgoing\OUT
SET PLATACHOutgoingFileERROR=%dump%\ACH\Outgoing\ERROR
SET PLATACHOutgoingFileLOG=%dump%\ACH\Outgoing\LOG
SET PLATACHOutgoingFileIntermediate=%dump%\ACH\Outgoing\Intermediate

REM Plat ACH Incoming ACH Environment variables 
SET PLAT_ACHFileIN=%dump%\ACH\Incoming\IN
SET PLAT_ACHFileOUT=%dump%\ACH\Incoming\OUT
SET PLAT_ACHFileERROR=%dump%\ACH\Incoming\ERROR
SET PLAT_ACHFileLOG=%dump%\ACH\Incoming\LOG
SET PLAT_ACHIncomingFileServerPath=%dump%\ACH\Incoming\OUT
SET PLAT_ACHFileBLANKFILE=%dump%\ACH\Incoming\BLANKFILE

SET WEXACHOutgoingFileERROR=%dump%\AOC\ACH\Outgoing\WEX\ERROR
SET WEXACHOutgoingFileIN=%dump%\AOC\ACH\Outgoing\WEX\IN
SET WEXACHOutgoingFileLOG=%dump%\AOC\ACH\Outgoing\WEX\LOG
SET WEXACHOutgoingFileOUT=%dump%\AOC\ACH\Outgoing\WEX\OUT


REM Environment Variables which were missing but available In test
SET FinalLendingClubACHOutgoingFileIN=%dump%
SET TestBankCADACHOutgoingFileIN=%dump%
SET TestBankUSAACHOutgoingFileIN=%dump%
SET GreenSkyACHOutgoingFileIN=%dump%
SET DemoACHOutgoingFileIN=%dump%


SET interface_ca=CI_DB
SET EFBatchQueue=%base%\Final\Outgoing File\Auth Recon\Final
SET AuthScalePath=%base%\Final\Outgoing File\Auth Recon\Final
SET ClearingQueue=%base%\Final\Outgoing File\Auth Recon\Final
SET mcoutput_path=%base%\Final\Outgoing File\Auth Recon\Final
SET SCALE_RESTART_INI=%base%\Final\Outgoing File\Auth Recon\Final


SET ACHFileOut=%dump%\Final\ACH\Outgoing

SET ACHFileOUT_AOC=%dump%\AOC\ACH\Outgoing

SET CBR_ErrorFolder=%base%\CBR\Error

SET CBR_LogFileFolderName=%base%\CBR\log

SET CBR_OutputFolder=%base%\CBR\Output

SET DemoACHOutgoingFileERROR=%dump%\Demo\ACH\Outgoing\Demo\ERROR

SET DemoACHOutgoingFileLOG=%dump%\Demo\ACH\Outgoing\Demo\LOG

SET DemoACHOutgoingFileOUT=%dump%\Demo\ACH\Outgoing\Demo\OUT

SET FinalLendingClubACHOutgoingFileERROR=%dump%\Final\ACH\Outgoing\FinalLendingClub\ERROR

SET FinalLendingClubACHOutgoingFileLOG=%dump%\Final\ACH\Outgoing\FinalLendingClub\LOG

SET FinalLendingClubACHOutgoingFileOUT=%dump%\Final\ACH\Outgoing\FinalLendingClub\OUT

SET FinalReconFilePathName_LendingClub=%dump%\Final\AuthReconFile

SET GreenSkyACHOutgoingFileERROR=%dump%\GreenSky\ACH\Outgoing\GreenSky\ERROR

SET GreenSkyACHOutgoingFileLOG=%dump%\GreenSky\ACH\Outgoing\GreenSky\LOG

SET GreenSkyACHOutgoingFileOUT=%dump%\GreenSky\ACH\Outgoing\GreenSky\OUT

SET Logfolder=%dump%\TideWater\TideWater_Clearing\ClearingOutFIles_Tidewater\Log\

SET NEW_OFAC_ERROR=%base%\OFAC\NEW_OFAC_ERROR

SET NEW_OFAC_IN=%base%\OFAC\NEW_OFAC_IN

SET NEW_OFAC_LOG=%base%\OFAC\NEW_OFAC_LOG

SET NEW_OFAC_OUT=%base%\OFAC\NEW_OFAC_OUT

SET OutFileGeneration_TW=%dump%\TideWater\TideWater_Clearing\ClearingOutFIles_Tidewater

SET PathNameCBR=%base%\CBR

SET TestBankCADACHOutgoingFileERROR=%dump%\AOC\ACH\Outgoing\TestBankCAD\ERROR

SET TestBankCADACHOutgoingFileLOG=%dump%\AOC\ACH\Outgoing\TestBankCAD\LOG

SET TestBankCADACHOutgoingFileOUT=%dump%\AOC\ACH\Outgoing\TestBankCAD\OUT

SET TestBankUSAACHOutgoingFileERROR=%dump%\AOC\ACH\Outgoing\TestBankUSA\ERROR

SET TestBankUSAACHOutgoingFileLOG=%dump%\AOC\ACH\Outgoing\TestBankUSA\LOG

SET TestBankUSAACHOutgoingFileOUT=%dump%\AOC\ACH\Outgoing\TestBankUSA\OUT


REM ENvironment variables for Base Lock Box 
SET LockBoxIN=%dump%\LockBox\IN
SET LockBoxOUT=%dump%\LockBox\OUT
SET LockBoxError=%dump%\LockBox\ERROR
SET LockBoxLog=%dump%\LockBox\LOG
SET BulkCompromisedCardFiles=%base%\CoreBankCard\Dump
SET PortalBulkCardFile=%base%\CoreBankCard\Dump
SET BulkCardFileResponse=%dump%\BulkResponseFile
SET PlatReconFilePathName=%dump%\AuthReconFile



SET VISAFileIN=%dump%\VISARecon\VisaFileIn
SET VISAFileOut=%dump%\VISARecon\VisaFileOut
SET VISAFileError=%dump%\VISARecon\VisaFileError
SET VISAOutBound=%dump%\VISARecon\OutBound
SET VISA_LOG=%dump%\VISARecon\Log


SET DBMSReconCountCommit=1000

SET conversion_intermidiate_db_name=CCGS_CoreIssue

SET WEEKDAYBUSSINESSHOURSFROM=070000
SET WEEKDAYBUSSINESSHOURSTO=160000
SET WEEKENDBUSSINESSHOURSFROM=070000
SET WEEKENDBUSSINESSHOURSTO=120000



SET CoreCreditLink=https://ccCoreCredit.corecard.com


REM PlatLockBox
set PLATLockBoxIN=%dump%\Plat\LockBox\IN
set PLATLockBoxOUT=D:\DBBSetup\Dump\Plat\LockBox\OUT
set PLATLockBoxError=%dump%\Plat\LockBox\ERROR
set PLATLockBoxLog=%dump%\Plat\LockBox\LOG
SET PLATLockBoxBlankFile=%dump%\Plat\LockBox\BLANK
SET PLATLockBoxFileServerPath=%dump%\Plat\LockBox\OUT
REM SET PLATLockBoxFileServerPath=%dump%\Plat\LockBox\OUT

SET TCIVRHostName=10.206.1.155
SET TCIVRQueueName=TCIvrRequest
SET NonMonetaryHostName=10.206.1.155
SET NonMonetaryQueueName=NonMonetaryLog

SET KafkaSendTimeout=1000
SET KafkaReadTimeout=1000
SET KafkaTraceQueueName=topic1
REM KafkaHostName=10.206.1.155
REM KafkaPort=9092
REM SendTraceDataToKafka=1

REM Plat ISO ACH Incoming Environment variables 
SET PLATISOACHIncomingFileIN=%dump%\ACH\ACHISOReturn\IN
SET PLATISOACHIncomingFileOUT=%dump%\ACH\ACHISOReturn\OUT
SET PLATISOACHIncomingFileLOG=%dump%\ACH\ACHISOReturn\LOG
SET PLATISOACHIncomingFileERROR=%dump%\ACH\ACHISOReturn\ERROR
SET GreenSkySSPortalProd=https://www.MyGreenSky.com


SET GS_CBREPORTING_LOGFILE_PATH=%base%\CBR\GreenSky\LogFile
set GS_CBREPORTING_FILE_PATH=%base%\CBR\GreenSky\File

SET GLDataFeed_IN=%dump%\GL\GLPostingDataFeed_IN
SET GLDataFeed_OUT=%dump%\GL\GLPostingDataFeed_OUT
SET GLDataFeed_Error= %dump%\GL\GLPostingDataFeed_Error
SET GLDataFeed_Log=%dump%\GL\GLPostingDataFeed_Log

SET Loyalty_FileIN=%dump%\LoyaltyTP\InputFile
SET Loyalty_FileOUT=%dump%\LoyaltyTP\OutputFile
SET Loyalty_FileERROR=%dump%\LoyaltyTP\ErrorFile
SET Loyalty_FileLOG=%dump%\LoyaltyTP\LogFile
SET MailTo=Dummy
SET MailFrom=Dummy
SET SMTP_SERVER=Dummy
SET SMTPPORT=25

REM GreenSkyMerchantACHSettlement outgoing File New Env variable 
SET GreenSkyMerchantACHSettlementIN=%dump%\GreenSky\ACH\MerchantSettlementOutgoing\IN
SET GreenSkyMerchantACHSettlementOUT=%dump%\GreenSky\ACH\MerchantSettlementOutgoing\OUT
SET GreenSkyMerchantACHSettlementLOG=%dump%\GreenSky\ACH\MerchantSettlementOutgoing\LOG
SET GreenSkyMerchantACHSettlementERROR=%dump%\GreenSky\ACH\MerchantSettlementOutgoing\ERROR
SET GreenSkyMerchantACHSettlementIntermediate=%dump%\GreenSky\ACH\MerchantSettlementOutgoing\Intermediate



SET ManualCheckOutFile=%dump%\ManualCheck\OUT
SET ManualCheckLogFile=%dump%\ManualCheck\LOG

REM DownloadRoutingFile
SET RoutingRecordFileLocation=%dump%\RoutingFile\IN
SET RoutingRecordFileOUT=%dump%\RoutingFile\OUT
SET RoutingRecordFileLOG=%dump%\RoutingFile\LOG

REM SET RoutDownloadFileLocation=https://www.frbservices.org/EPaymentsDirectory/FedACHdir.txt
SET RoutDownloadFileLocation=https://www.frbservices.org/EPaymentsDirectory/FedACHdir.txt?AgreementSessionObject=Agree

SET IrvingReport_FileIN=%dump%\IrvingReport\IN
SET IrvingReport_FileOUT=%dump%\IrvingReport\OUT
SET IrvingReport_FileERROR=%dump%\IrvingReport\ERROR
SET IrvingReport_FileLOG=%dump%\IrvingReport\LOG


REM Added Env Variable for Delenquent Account File, plz update file location
SET DelinquentAccountFileInputDir=%dump%\DelinquentAccountFile\Input
SET DelinquentAccountFileArchiveDir=%dump%\DelinquentAccountFile\Archive
SET DelinquentAccountFileErrorDir=%dump%\DelinquentAccountFile\ERROR
SET DelinquentAccountFileLOGDir=%dump%\DelinquentAccountFile\LOG


REM Set this NO in Credit and YES for Plat env
SET OverrideLogoCardTermForReissue=YES

REM CollateralID Update via file
SET CIBUpdateInputFile=%dump%\CIBUpdate\INPUT
SET CIBUpdateErrorFile=%dump%\CIBUpdate\ERROR
SET CIBUpdateOutFile=%dump%\CIBUpdate\OUT
SET CIBUpdateLogFile=%dump%\CIBUpdate\LOG
SET CIBUpdateProcessedFile=%dump%\CIBUpdate\PROCESSED
REM SET InsitutionID=6969

REM Added Env Variable for Past Due Authorization strategy File, plz update file location
SET PastDueAuthStrategyInputDir=%dump%\Plat\PastDueAuthStrategy\Input
SET PastDueAuthStrategyArchiveDir=%dump%\Plat\PastDueAuthStrategy\Archive
SET PastDueAuthStrategyErrorDir=%dump%\Plat\PastDueAuthStrategy\ERROR
SET PastDueAuthStrategyLOGDir=%dump%\Plat\PastDueAuthStrategy\LOG

REM Added new Env Variables for IPM error reporting (please update file locations)
rem SET IPMErrorReportFile=%dump%\MasterCard\IPMSettlement\Report\Archive
rem SET IPMErrorReportArchive=%dump%\MasterCard\IPMSettlement\Report\ErrorReport\Archive
rem SET IPMErrorReportLOG=%dump%\MasterCard\IPMSettlement\Report\ErrorReport\LOG
rem SEt IPMErrorReportERROR=%dump%\MasterCard\IPMSettlement\Report\ErrorReport\ERROR

SET DummyMmsApiResult=Dummy
SET GreenSkyEmailFrom=Dummy
SET GreenSkyMailServerName=Dummy

REM Flag To Activate StatementValidation
SET StatementValidationActivation=TRUE
SET IPMBatchRecordCount=25000
SET UsePIIFromBearerForEmbossing=YES
SET GSPendingAppEmail=Dummy

REM Added for svcGetWelcomePackageURL, Value of this variable has to be Equal to respective environment's CoreAppsetup's ApplicationLetterHost Env. Variable.
REM Value Of this variable for CP Test region has to be - https://testcoreconsumer.corecard.com/
REM Value of this variable for CP Prod region has to be - https://coreconsumer.corecard.com/
SET ApplicationLetterHost=http://LocalHost/

REM Plat BillPayPayment Environment variables 
SET BillPayPaymentIN=%dump%\Plat\BillPayPayment\IN
SET BillPayPaymentOUT=%dump%\Plat\BillPayPayment\OUT
SET BillPayPaymentERROR=%dump%\Plat\BillPayPayment\ERROR
SET BillPayPaymentLOG=%dump%\Plat\BillPayPayment\LOG

REM GreenSky Merchant ACH Incoming File Env variable 
SEt GreenSky_Settle_ACHFileBLANKFILE=Dummy

REM GreenSky ACH Incoming File Env variable 
SEt GreenSky_ACHFileBLANKFILE=Dummy

REM DeserveCheckCBRFile
SET DeserveCheckCBRFileIN=Dummy
SET DeserveCheckCBRFileLOG=Dummy
SET DeserveCheckCBRFileERROR=Dummy

REM LOCKBOX SUMMARY MAIL
SET LockBoxMailFrom=Dummy
SET LockBoxMailTo=Dummy


Rem API Log variables only for green sky .
Set APILOg_FILE_PATH=Dummy
SET APILOg_LOGFILE_PATH=Dummy

SET ChargeBackTQR4File=%dump%\MasterCard\IPMSettlement\ChargebackTQR4\TQR4
SET ChargeBackTQR4Archive=%dump%\MasterCard\IPMSettlement\ChargebackTQR4\Archive
SET ChargeBackTQR4LOG=%dump%\MasterCard\IPMSettlement\ChargebackTQR4\LOG
SET ChargeBackTQR4ERROR=%dump%\MasterCard\IPMSettlement\ChargebackTQR4\ERROR



REM Added to write Statement Data in  Kafka Queue  (It requires StatementValidationActivation= TRUE)
SET KafkaDataProcessing=False

REM Put Kafka host server name instead of "localhost"

SET BulkCardFileResponseLog=%dump%\BulkResponseFile\LOG
SET BulkCardDetailFilePath=%dump%\BulkResponseFile\IntermediateFiles

SET WlcmPackURL=Dummy
SET WlcmPackHost=Dummy
SET PORTNUM=Dummy


SET InterestAlertByTNP=0

IF EXIST "RTMConfig.bat" (
call RTMConfig.bat
)


SET NumDayIPMRecDelete=20
SET NumDayIPMOutStdAuthData=30
SET IPMStreamDump=0
SET NumDaysToIPMRev=120
SET AuthUpdateBatchCount=5000


SET ExecuteParsingWorkStep=0
SET IPMNumRecBulkInsert=5000
SET IPMCSVFilePath=%dump%\MasterCard\Dummy
REM set own mailID
SET MrgActFailedAlertFrom=Dummy
SET MrgActFailedAlertTo=Dummy


SET ExecuteParsingWorkStep=2
SET EmbEncryptedChunkSize=50
REM JSON File will be created here
SET JSONCreatedFileLocation=%dump%\MasterCard\IPMSettlement\Incoming\IPMJSON\
REM Application will read JSON File from this location
SET JSONReadFileLocation=%dump%\MasterCard\IPMSettlement\Incoming\OUT\
SET IPMJSONCreatedFileLocation=D:\DBBSetup\Dump\MasterCard\IPMSettlement\Incoming\IPMJSON

SET ChargeBackTQR4ArchivePOD=%dump%\MasterCard\IPMSettlement\ChargebackTQR4\ChargeBackTQR4ArchivePOD
REM SET GLDataFeed_IN=%dump%\GL\GLDataFeeds_IN
REM Set GLDataFeed_Log=%dump%\GL\GLDataFeeds_Log
REM Set GLDataFeed_OUT=%dump%\GL\GLDataFeeds_OUT
REM Set GLDataFeed_Error=%dump%\GL\GLDataFeeds_Error

SET IPMCallInterval=1
SET CBRecordUpdateChunk=1000
SET CBR_PIIFileIntermediate = %base%\CBRReporting\Intermediate
SET CBR_LogFileFolderName = %base%\CBRReporting\log

SET DummyModelScore=Dummy
REM IPMValidationEnable 1 = Enable (SP :PR_MCIPMValidation) ,0 = Disable 
SET IPMValidationEnable=0

REM Modify variable to add servicegroup
REM SET LockBoxMailTo=servicegroup@corecard.com

SET EnableExceptionTest=0
SET IPMJobIdForRetry=0
REM MrgActAutoRetryEnable=1 for Testing Team to test and verify, for Prodcution Env. it should be 0
SET MrgActAutoRetryEnable=1

REM TestPIIAPI variable will be used for developer testing
SET TestPIIAPI=NO

REM Below added Environment variable will be used exclusively for Reconciliation/Settlement related Notification/Alerts.
SET MailServerName_StlRcn=email-smtp.us-east-1.amazonaws.com
SET MailSender_StlRcn=pod2-QA-alerts@infra.marcus.com
SET MailReceiver_StlRcn=pod2configteam@corecard.com,servicegroup@corecard.com,platalert@corecard.com

REM Value - 0, for regular CBR file generation (Used in WF_CBRGetPIIInfo)
REM Value - 1, Only record will be inserted into 
REM Data table for CBR file generation (Used in WF_CBRGetPIIInfo)
SET TestCBRFileWithoutPII=0

SET TQRJSONCreatedFileLocation=%dump%\MasterCard\IPMSettlement\ChargebackTQR4\TQR4Json
SET TQRCallInterval=5

SET emThalesMonitorInterval=120
SET emThalesCBTestInterval=300

REM It should get assigned with Link Server String from Main to Reporting Server
SET RptSrvrName_StlRcn=link_CCRPTE1QA1

REM It should get assigned with CI db name at Reporting Server
SET RptSrvrCIDbName_StlRcn=CCGS_RPT_CoreIssue

REM Time (HHMM 24 hours format), On or after that JAZZ files will be Holded
SET FileHoldTime=1600

REM It will inform that what extension files will be considered for Hold (if it is not assigned, then no file will be Holded)
SET FileToBeHold=A001,A002,A004,A006,IPM
SET DayDiff=

REM It should call "BHUBAPI" for Thirdparty API
SET UseBhubFromBearerForEmbossing=NO

REM This variable should contain all file Extensions in the sequence they arrive in Production Environment
REM In Lower/POD_2 Environments, file sequence should be as per file sequence of that env, e.g. A004,A005,A006,A001,A002
SET IPMFileSequence=A004,A005,A006,A001
REM Use to sqs Message Data For SQS Statement PDF Generation
REM it will work with platform SQS feature - 4.2.42.21
SET MessageQueueService=SQS
REM Use to enable/disable PII API call inside Extract CBR WF. 0-No, 1-Yes
SET CBRPIICallInAPI=0
REM During PII Fetch set use of CBRStatementDetails table. 0-No, 1-Yes
SET UseCBRStatementDetails=0

REM Use to enable/disable PII API call during schedule creation. 0-No, 1-Yes
SET ACHPIICallInAPI=0
REM AWS Access key from application

REM Put Kafka queue name instead of "test"

REM SQS Message store Variables

REM S3 Statement MetaData Alert
REM SET S3URLAlert=NONE
SET S3BucketNameAlert=stmt-notification-dileep

SET STMTDataQueueNameAlert=StatementTestConsumerInputDileep

REM SQS Statement MetaData Alert


REM to store API response in local
REM APIStore=Local for local qa Testing and S3 bi
SET APIStore=S3
REM Use to S3 OR Local Statementmetadata file generation.
SET StatementmetaDataPath=NONE

REM S3 Statement MetaData Alert
SET S3URLAlert=https://s3.us-east-1.amazonaws.com
REM SET S3BucketNameAlert=stmt-notification-dileep

REM SET STMTDataQueueNameAlert=StatementTestConsumerInputDileep

REM SQS Statement MetaData Alert

SET SQSURLAlert=https://sqs.us-east-1.amazonaws.com/684115146341
REM SET STMTDataQueueNameAlert=StatementTestConsumerInputDileep
SET _emSQSMinLengthForCompression=0
REM Use to enable/disable PII API call inside Extract CBR WF. 0-No, 1-Yes (Do not add variable if exists/only update the value)
SET SeperateFileForOvernightDelivery=0

REM Exclude current day in count of Payment hold Days if set to TRUE
SET ExcludeCurrenDayinHPOTB=TRUE

SET AWSRole=Dummy
SET ShardTimeout=4000
SET CurrentShard=SHARD1
SET PoddingSupported=0
SET DoDetailTxn=FALSE
SET SQSExternalID=123454323_12345
SET S3ExternalID=123454323_12345
SET AlertSQSExternalID=123454323_12345
SET AlertS3ExternalID=123454323_12345
SET StopPurgePosting=NO
SET TestStatementDataQueueName=NONE
SET TestSQSS3Bucket=NONE
SET TestSQSURL=NONE
SET TestSQSS3Url=NONE
SET TestS3BucketName=NONE
SET TestS3URL=NONE
SET TestMessageQueueService=NONE
SET CopyFileSource=DUMMY

SET KMS_SLL_DEBUG=0
SET ACHOutgoingFileLOG=%base%\Dump\ACH\Outgoing\Log

SET KafkaPort=9092
SET KafkaHostName=10.206.1.155
SET KafkaSorceAuthQueue=SourceAuthData
SET KafkaSorceAuthHost=10.206.1.121
SET emKeepProcessGoing=1
SET _emRatioMinMaxLimit=1

SET CreditStrategyCSVfileArchive=%dump%\Delinquent\CSVFile
SET CreditStrategyCallInterval=10
SET emThalesLBPresent=0

SET ActiveRegion=us-east-1

IF "%ActiveRegion%"=="us-east-1" (
REM AWS Access key from application
SET AWS_ACCESS_KEY_ID=NONE
SET KMSENC_AWS_SECRET_ACCESS_KEY=
SET StatementDataQueueName=CCPOD2-SQSQueue-QA-us-east-1
REM SQS Message store Variables
SET SQSRole=NONE
SET SQSURL=https://sqs.us-east-1.amazonaws.com/190251063267
SET SQSS3Bucket=NONE
SET SQSRegion=us-east-1
SET SQSSTSlink=https://sts.us-east-1.amazonaws.com
SET SQSSTSRegion=us-east-1
SET SQSS3Url=NONE
SET S3URL=https://s3.us-east-1.amazonaws.com
SET S3Role=NONE
SET S3BucketName=corecard-pod2-qa-us-east-1-statement-gen/notifications
SET S3Region=us-east-1
SET S3STSUrl=https://sts.us-east-1.amazonaws.com
SET S3STSRegion=us-east-1
SET AWSRoleAlert=NONE
SET SQSRegionAlert=NONE
SET SQSS3Region=NONE
SET S3RegionAlert=NONE
SET S3RoleAlert=NONE
SET S3STSUrlAlert=NONE
SET S3STSRegionAlert=NONE
SET SQSCustomURL=https://vpce-06c5ceec2b9bd5c8c-1b1xhhdg.sqs.us-east-1.vpce.amazonaws.com
SET StatementDataHostName=localhost
SET KMSENC_S3ExternalID=
SET KMSENC_SQSExternalID=
)
SET _emDBPDdisable=1
REM For Production please SET AllowExtendExpirationDate=PROD other than PROD we set only AllowExtendExpirationDate=TEST
SET AllowExtendExpirationDate=TEST
SET STMTRetryThreshold=5
SET CollFeeException=%dump%\MasterCard\IPMSettlement\Report\Exception
SET Key_Family_For_Keyed_Hash=16
SET _emDoubleDecimalPlaces=12
SET _emExprNvlCurrencyCorrect=0
SET _emConsiderServiceExecErrCritical=0
SET PanhashIsUnique=0
SET emPAN_HMACKeyFamily=5
SET emPAN_HMACAcrossPodKeyFamily=16

