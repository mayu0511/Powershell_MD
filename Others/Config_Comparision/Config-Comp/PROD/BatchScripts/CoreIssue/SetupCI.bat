REM ============= Changes required from here ===============

SET base=D:\DBBSetup

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

SET CoreIssueScaleFile=scale_appCoreIssue.ini

SET CoreIssuePort=4421

SET CoreIssueServicesScaleFile=scale_appServices.ini

SET CoreIssueServicesPort=4422

SET CoreIssueLink=https://ccApps.corecard.com/appCoreIssue.aspx

SET EXECUTABLEPATH=D:\CC_Runtime

SET dbb_trace_path=D:\TraceFiles\CoreIssue

SET CIReportsFolder=CoreIssueReports

SET LettersVirDir=CoreIssueReports

SET MailServerName=Dummy

REM ManualAuth Environmental Varialbe
SET CAuth_SCALE_NAME=appCoreAuth
SET CAuth_PORT=4427
SET SCALE_SERVER_HOST=CCWEBe1PRODb1
SET SCALE_SERVER_PORT=9999

REM ============= Changes required till here ===============

SET post_dbms_server=%PrimaryDBServerODBCName%
SET post_dbms_name=%CoreISSUEDBName%
SET post_dbms_login=windowslogin
SET post_dbms_passwd=windowslogin

SET report_dbms_server=%ReplicatedDBServerODBCName%
SET report_dbms_name=%ReportsCoreISSUEDBName%
SET report_dbms_login=windowslogin
SET report_dbms_passwd=windowslogin

SET CauthReport_dbms_server=%ReplicatedDBServerODBCName%
SET CauthReport_dbms_name=%ReportsCoreAuthDBName%
SET CauthReport_dbms_login=windowslogin
SET CauthReport_dbms_passwd=windowslogin

SET CLReport_dbms_server=%ReplicatedDBServerODBCName%
SET CLReport_dbms_name=%ReportsCoreLibraryDBName%
SET CLReport_dbms_login=windowslogin
SET CLReport_dbms_passwd=windowslogin

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

SET capp_dbms_server=%PrimaryDBServerODBCName%
SET capp_dbms_name=%CoreAPPDBName%
SET capp_dbms_login=windowslogin
SET capp_dbms_passwd=windowslogin

SET portal_dbms_server=%PrimaryDBServerODBCName%
SET portal_dbms_name=%CoreMoneyDBName%
SET portal_dbms_login=windowslogin
SET portal_dbms_passwd=windowslogin

SET PortalReport_dbms_server=%ReplicatedDBServerODBCName%
SET PortalReport_dbms_name=%ReportsCoreMoneyDBName%
SET PortalReport_dbms_login=windowslogin
SET PortalReport_dbms_passwd=windowslogin

SET cappReport_dbms_server=%ReplicatedDBServerODBCName%
SET cappReport_dbms_name=%ReportsCoreAPPDBName%
SET cappReport_dbms_login=windowslogin
SET cappReport_dbms_passwd=windowslogin

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
SET CoreAuthQueue=DIRECT=OS:SKulshreshtha\private$\CoreAuth

SET Mayors_SettlementFileIN=%base%\SettlementFileIN
SET Mayors_SettlementFileOUT=%base%\SettlementFileOUT
SET Mayors_SettlementFileERROR=%base%\SettlementFileERROR
SET Mayors_SettlementFileLOG=%base%\SettlementFileLOG

SET OUTGOING_EMBOSSING_PATH=%base%\Dump\Embossing\
REM SET OUTGOING_STMT_PATH=%base%\Dump\Embossing\
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

SET EmailId=Dummy
SET Email_Operation=Dummy
SET LostStolenCSREmailId1=Dummy
SET LostStolenCSREmailId2=Dummy
SET RequestCustomerServiceHelpCSREmailId1=Dummy
SET RequestCustomerServiceHelpCSREmailId2=Dummy
SET RequestCompanionCardCSREmailId1=Dummy
SET RequestCompanionCardCSREmailId2=Dummy 
SET TxnDisputeCSREmailId1=Dummy
SET TxnDisputeCSREmailId2=Dummy
SET RequestReplacementCardCSREmailId1=Dummy
SET RequestReplacementCardCSREmailId2=Dummy
SET NewCardRequestCSREmailId1=Dummy
SET NewCardRequestCSREmailId2=Dummy

REM This variable would be use to perform auth with post function or without post function, so user need to SET one of the variable in his/her SET file.
SET Auth=AuthWithoutPosting
REM SET Auth=AuthWithPosting

SET ACHFileIN=%base%\ACH\IN
REM This is not in used
REM SET ACHFileOUT=%base%\Dump\Final\ACH\Outgoing
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

SET PATCH372=01032009010000
SET PATCH37=04202008230200
SET OLDOVERDRAFTFEE=03202008010000
SET PPRELEASE2A=06162008230200
SET PPRELEASE3=11022008010000
SET NEWFRAUDAUTHCONTROLS=11022008010000
SET NEWCREDITREGULATIONDATE=02212010230001
REM SET ROLLCPMCONTROL=11172004230001
SET NEWINSCLAIMSDISASTERDATE=12312009010000

REM Report Environment  Variable 
SET ReportExtension=.aspx

REM This Variable would be use to Generate HotLink from CoreIssue to SelfService. Use Selfservice's App. Port No. in place of 4568.
SET SelfServiceLink=http://10.150.0.58/appMayorsSS.aspx
SET SelfServiceAppName=appMayorsSS

REM The right parameter is the name of the folder where your image is stored under the dbbimage folder
SET CardImagePath=CardImageManagement

REM SET PathName=%base%\StarCAF
REM SET OutputFolder=%base%\StarCAF\output
REM SET CAFOutputFolder=%base%\StarCAF
SET DriverPath=%base%

REM SET NetworkDrive=%base%\BackcardSetup

SET AuthenticationMode=WA
REM The AuthenticationMode var must have its value in ALL CAPS like (WA or SA)

SET Recipients_ID=Dummy
SET Outlook_ID=Dummy
SET Sender_ID=Dummy

REM SET PortalBulkCardFile=%base%\FILES
REM SET PortalBulkLoadFile=%base%\FILES



REM Credit Bureau Reporting Env var
SET CBRCHANGEDATE=05302005230000
SET CBREPORTING_FILE_PATH=%base%\CBR\
SET CBREmailFrom=Dummy
SET CBRNotifyEmail=Dummy

SET EmailStatementLink=http://10.150.0.58/handlerSelfServicelogin.html 
SET EmailStatementClientName=Dummy
SET EmailStatementSubject=Your monthly statement ready for viewing!!!



REM SET the CBR files location

REM SET CBR_OutputFolder=%base%\CBR\Output
REM SET CBR_ErrorFolder=%base%\CBR\Error
REM SET CBR_LogFileFolderName=%base%\CBR\log
REM SET PathNameCBR=%base%\CBR

SET EmailFooter=Frys Customer Care

SET PassEncryBatchSize=5000 

SET NEWFEECREDIT=10312010230000
SET KBDATEOFTOTALDUE=05202010230000
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
SET WaiveDueAsStatusSetting=03212014042500

SET PaymentEnhancement=04282014021500
SET DNApplyPayEnhancement=04282014021500

SET BacktoBackPayment=05192014014500

SET AccountLevelTotalDueIssue=06102014024500
SET AdjMinDueTime=06302014044500
SET NewApplicationVersion=1031201423000000
SET HoldStatement=Yes


REM TideWater OTB File Variables
REM OTBFileIN  folder name should be ?TideWater_OTBFile_In? and should have read/write permisssion.

REM SET OTBFileIN=%base%\Dump\TideWater_OTBFile\OTBFile_IN

SET OTBFileIN=\\CCSQL02\TideWater\OTBFile_IN


SET OTBFileOUT=%base%\Dump\TideWater_OTBFile\OTBFile_OUT
SET OTBFileERROR=%base%\Dump\TideWater_OTBFile\OTBFile_ERROR
SET OTBFileLOG=%base%\Dump\TideWater_OTBFile\OTBFile_LOG

REM TideWater Clearing File Variables
SET TideWater_SettlementFileIN=%base%\Dump\TideWater_Clearing\ClearingFileIN
SET TideWater_SettlementFileOUT=%base%\Dump\TideWater_Clearing\ClearingFileOUT
SET TideWater_SettlementFileLog=%base%\Dump\TideWater_Clearing\ClearingFileLOG
SET TideWater_SettlementFileError=%base%\Dump\TideWater_Clearing\ClearingFileERROR

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


REM SET environment variable to access coreapp db from coreissue.

REM VantivRecon files locations

SET VantivIN=%base%\Dump\Final\VantivRecon\IN
SET VantivOUT=%base%\Dump\Final\VantivRecon\OUT
SET VantivError=%base%\Dump\Final\VantivRecon\Error
SET VantivLog=%base%\Dump\Final\VantivRecon\Log

REM FINAL ACH

SET FINAL_ACHFileIN=%base%\Dump\Final\ACH\Incoming\IN
SET FINAL_ACHFileOUT=%base%\Dump\Final\ACH\Incoming\OUT
SET FINAL_ACHFileLOG=%base%\Dump\Final\ACH\Incoming\Log
SET FINAL_ACHFileERROR=%base%\Dump\Final\ACH\Incoming\ERROR


REM AuthRecon

SET FinalReconFilePathName=%base%\Dump\Final\AuthReconFile


REM DownloadRoutingFile
SET RoutingRecordFileLocation=%base%\Dump\CreditProcessing\RoutingFile\IN
SET Routing_LOG=%base%\Dump\CreditProcessing\RoutingFile\Log\
SET MailSender=Dummy
SET MailReciever=Dummy
REM SET RoutDownloadFileLocation=https://www.frbservices.org/EPaymentsDirectory/FedACHdir.txt
SET RoutDownloadFileLocation=https://www.frbservices.org/EPaymentsDirectory/FedACHdir.txt?AgreementSessionObject=Agree

REM This is not in used
REM SET ACHFileOUT_AOC=%base%\Dump\AOC\ACH\Outgoing

SET AOC_ACHFileIN=%base%\Dump\AOC\ACH\Incoming\IN
SET AOC_ACHFileOUT=%base%\Dump\AOC\ACH\Incoming\OUT
SET AOC_ACHFileERROR=%base%\Dump\AOC\ACH\Incoming\ERROR
SET AOC_ACHFileLOG=%base%\Dump\AOC\ACH\Incoming\LOG

SET AOC_SettlementFileIN=%base%\Dump\AOC\Settlement\IN
SET AOC_SettlementFileOUT=%base%\Dump\AOC\Settlement\OUT
SET AOC_SettlementFileERROR=%base%\Dump\AOC\Settlement\ERROR
SET AOC_SettlementFileLOG=%base%\Dump\AOC\Settlement\LOG

REM SET OUTGOING_STMT_PATH_AOC=%base%\Dump\AOC\Statement
SET OUTGOING_STMT_PATH_AOC=\\DB02\Mayors\Dump\AOC\Statement


REM Cardopen Service 
SET VantivWSDL=%base%\WSDL\Final\CardOpen.wsdl
SET APIPWD=D7AFD30230D3F6C38C572145595C3B96

REM For Coreapp Setup (Testing|Production)
SET ExperianSetup=Production


SET VantivAPICall=PROD

REM UpdateCall 
SET UPDATECALLWSDLPATH=%base%\WSDL\Final\FinalUpdateServices.wsdl
SET UPDATECALLMETHOD=AccountUpdates

SET ARMAST_FILE_PATH=%base%\Dump\R2S\ARMAST_File
SET ARMAST_FILE_NAME=%base%\Dump\R2S\ARMAST_File\ARMAST.dat
SET OUTGOING_STMT_PATH=%base%\Dump\R2S\OutGoingStatement


REM Final ACH Outgoing File New Env variable
SET FinalACHOutgoingFileIN=%base%\Dump\Final\ACH\Outgoing\IN
SET FinalACHOutgoingFileOUT=%base%\Dump\Final\ACH\Outgoing\OUT
SET FinalACHOutgoingFileLOG=%base%\Dump\Final\ACH\Outgoing\LOG
SET FinalACHOutgoingFileERROR=%base%\Dump\Final\ACH\Outgoing\ERROR

REM AOC ACH Outgoing File New Env variable
REM SET AOCACHOutgoingFileIN=%base%\Dump\AOC\ACH\Outgoing\IN
REM SET AOCACHOutgoingFileOUT=%base%\Dump\AOC\ACH\Outgoing\OUT
REM SET AOCACHOutgoingFileLOG=%base%\Dump\AOC\ACH\Outgoing\LOG
REM SET AOCACHOutgoingFileERROR=%base%\Dump\AOC\ACH\Outgoing\ERROR


REM AOC AvidiaBankCAD ACH Outgoing File New Env variable 
SET AvidiaBankCADACHOutgoingFileIN=%base%\Dump\AOC\ACH\Outgoing\AvidiaBankCAD\IN
SET AvidiaBankCADACHOutgoingFileOUT=%base%\Dump\AOC\ACH\Outgoing\AvidiaBankCAD\OUT
SET AvidiaBankCADACHOutgoingFileLOG=%base%\Dump\AOC\ACH\Outgoing\AvidiaBankCAD\LOG
SET AvidiaBankCADACHOutgoingFileERROR=%base%\Dump\AOC\ACH\Outgoing\AvidiaBankCAD\ERROR

REM AOC AvidiaBankUSA ACH Outgoing File New Env variable 
SET AvidiaBankUSAACHOutgoingFileIN=%base%\Dump\AOC\ACH\Outgoing\AvidiaBankUSA\IN
SET AvidiaBankUSAACHOutgoingFileOUT=%base%\Dump\AOC\ACH\Outgoing\AvidiaBankUSA\OUT
SET AvidiaBankUSAACHOutgoingFileLOG=%base%\Dump\AOC\ACH\Outgoing\AvidiaBankUSA\LOG
SET AvidiaBankUSAACHOutgoingFileERROR=%base%\Dump\AOC\ACH\Outgoing\AvidiaBankUSA\ERROR

REM AOC AOCBankandTrust ACH Outgoing File New Env variable 
SET AOCBankandTrustACHOutgoingFileIN=%base%\Dump\AOC\ACH\Outgoing\AOCBankandTrust\IN
SET AOCBankandTrustACHOutgoingFileOUT=%base%\Dump\AOC\ACH\Outgoing\AOCBankandTrust\OUT
SET AOCBankandTrustACHOutgoingFileLOG=%base%\Dump\AOC\ACH\Outgoing\AOCBankandTrust\LOG
SET AOCBankandTrustACHOutgoingFileERROR=%base%\Dump\AOC\ACH\Outgoing\AOCBankandTrust\ERROR

REM IPM Outgoing Settlement
SET OUTGOING_FILES_PATH=%base%\Dump\MasterCard\IPMSettlement\Outgoing\IN
SET OUTGOING_IPMOUT=%base%\Dump\MasterCard\IPMSettlement\Outgoing\OUT
SET OUTGOING_IPMERROR=%base%\Dump\MasterCard\IPMSettlement\Outgoing\ERROR
SET OUTGOING_IPMLOG=%base%\Dump\MasterCard\IPMSettlement\Outgoing\LOG

REM IPM Incoming Settlement
SET IPMFileIN=%base%\Dump\MasterCard\IPMSettlement\Incoming\T112
SET IPMFileOUT=%base%\Dump\MasterCard\IPMSettlement\Incoming\OUT
SET IPM_LOG=%base%\Dump\MasterCard\IPMSettlement\Incoming\LOG
SET IPM_ERROR=%base%\Dump\MasterCard\IPMSettlement\Incoming\ERROR


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
REM ---ADD and Setup below env variable in SetupCI file
SET CreditStackReconFilePathName=%base%\Dump\CreditStack\AuthReconFile


REM --------------------TideWater/AOC
REM ----env variable for Generating Clearing Out File For TideWater/AOC

REM SET OutFileGeneration_TW=%base%\Dump\TideWater_Clearing\ClearingFileOUT
REM SET Logfolder=%base%\Dump\TideWater_Clearing\ClearingFileLOG

REM --------------------FOR Alert, plz update folder and Email as per req. 

SET BTSAgentRegion=%base%\Dump
SET BTSAgentBranch=%base%\Dump
SET BTSAgentStateCode=%base%\Dump
SET BTSAgentCountryCode=%base%\Dump
SET BTSAgentCode=%base%\Dump
SET BTSTransactionServiceWsdl=%base%\Dump
SET ALERTS_NO_OF_RETRY=2
SET ALERTS_DURATION_BTW_RETRY=2
SET ExpCardSupportFromEmailId=Dummy
SET EmailSMSFromId=Dummy
SET SMSgateway=WRONGemail.smsglobal.com
SET MailServerName=%MailServerName%
SET SMSGlobalhttpMaxSplit=2



REM ----env variable for Generating Clearing Out File For PayOpt

REM PayOpt clearing File
SET PayOpt_SettlementFileIN=%base%\Dump\PayOpt\Settlement\IN
SET PayOpt_SettlementFileOUT=%base%\Dump\PayOpt\Settlement\Out
SET PayOpt_SettlementFileERROR=%base%\Dump\PayOpt\Settlement\Error
SET PayOpt_SettlementFileLOG=%base%\Dump\PayOpt\Settlement\Log



REM CreditStack ACH Outgoing File New Env variable 
SET CreditStackACHOutgoingFileIN=%base%\Dump\CreditStack\ACH\Outgoing\IN
SET CreditStackACHOutgoingFileOUT=%base%\Dump\CreditStack\ACH\Outgoing\OUT
SET CreditStackACHOutgoingFileLOG=%base%\Dump\CreditStack\ACH\Outgoing\LOG
SET CreditStackACHOutgoingFileERROR=%base%\Dump\CreditStack\ACH\Outgoing\ERROR


REM CreditStack ACH Incoming/Return File
SET CREDITSTACK_ACHFileIN=%base%\Dump\CreditStack\ACH\Incoming\IN
SET CREDITSTACK_ACHFileOUT=%base%\Dump\CreditStack\ACH\Incoming\OUT
SET CREDITSTACK_ACHFileERROR=%base%\Dump\CreditStack\ACH\Incoming\ERROR
SET CREDITSTACK_ACHFileLOG=%base%\Dump\CreditStack\ACH\Incoming\LOG


SET QRCodeUsername=Core
SET QRCodePassword=BALb6Ph2Ch4Bz8c73mRq6snBKjbA
SET QRCodeWEBTimeout=3000
SET QRCodeConnectTimeout=3000
SET QRCodeSendTimeout=3000
SET QRCodeReciveTimeout=3000
SET QRCodeAPIHost=bsystems.creditstack.com
SET QRCodeAPIURL=/services/getqrcode

REM Deserve ACH Outgoing File New Env variable 
SET DeserveACHOutgoingFileIN=%base%\Dump\Deserve\ACH\Outgoing\IN
SET DeserveACHOutgoingFileOUT=%base%\Dump\Deserve\ACH\Outgoing\OUT
SET DeserveACHOutgoingFileLOG=%base%\Dump\Deserve\ACH\Outgoing\LOG
SET DeserveACHOutgoingFileERROR=%base%\Dump\Deserve\ACH\Outgoing\ERROR


REM Deserve ACH Incoming/Return File
SET DESERVE_ACHFileIN=%base%\Dump\Deserve\ACH\Incoming\IN
SET DESERVE_ACHFileOUT=%base%\Dump\Deserve\ACH\Incoming\OUT
SET DESERVE_ACHFileERROR=%base%\Dump\Deserve\ACH\Incoming\ERROR
SET DESERVE_ACHFileLOG=%base%\Dump\Deserve\ACH\Incoming\LOG


REM Deserve Lock Box Payment Environment variables 
SET DeserveLockBoxIN=%base%\Dump\Deserve\LockBox\IN
SET DeserveLockBoxOUT=%base%\Dump\Deserve\LockBox\OUT
SET DeserveLockBoxLOG=%base%\Dump\Deserve\LockBox\LOG
SET DeserveLockBoxERROR=%base%\Dump\Deserve\LockBox\ERROR


REM --------- Create these folder on approprite folder and SET below env variable in CISetup.bat file.

SET IPMReportFile=%base%\Dump\MasterCard\IPMSettlement\Report\T140
SET IPMReportArchive=%base%\Dump\MasterCard\IPMSettlement\Report\Archive
SET IPMReportLOG=%base%\Dump\MasterCard\IPMSettlement\Report\LOG
SET IPMReportERROR=%base%\Dump\MasterCard\IPMSettlement\Report\ERROR

SET IPMErrorReportFile=%base%\Dump\MasterCard\IPMSettlement\Chargeback\T140
SET IPMErrorReportArchive=%base%\Dump\MasterCard\IPMSettlement\Chargeback\Archive
SET IPMErrorReportLOG=%base%\Dump\MasterCard\IPMSettlement\Chargeback\LOG
SET IPMErrorReportERROR=%base%\Dump\MasterCard\IPMSettlement\Chargeback\ERROR


REM Plat ACH Outgoing ACH Environment variables 
SET PLATACHOutgoingFileIN=%base%\Dump\ACH\Outgoing\IN
SET PLATACHOutgoingFileOUT=%base%\Dump\ACH\Outgoing\OUT
SET PLATACHOutgoingFileERROR=%base%\Dump\ACH\Outgoing\ERROR
SET PLATACHOutgoingFileLOG=%base%\Dump\ACH\Outgoing\LOG
SET PLATACHOutgoingFileIntermediate=%base%\Dump\ACH\Outgoing\Intermediate

REM Plat ACH Incoming ACH Environment variables 
SET PLAT_ACHFileIN=%base%\Dump\ACH\Incoming\IN
SET PLAT_ACHFileOUT=%base%\Dump\ACH\Incoming\OUT
SET PLAT_ACHFileERROR=%base%\Dump\ACH\Incoming\ERROR
SET PLAT_ACHFileLOG=%base%\Dump\ACH\Incoming\LOG
SET PLAT_ACHIncomingFileServerPath=%base%\Dump\ACH\Incoming\OUT
SET PLAT_ACHFileBLANKFILE=%base%\Dump\ACH\Incoming\BLANKFILE

SET WEXACHOutgoingFileERROR=%base%\Dump\AOC\ACH\Outgoing\WEX\ERROR
SET WEXACHOutgoingFileIN=%base%\Dump\AOC\ACH\Outgoing\WEX\IN
SET WEXACHOutgoingFileLOG=%base%\Dump\AOC\ACH\Outgoing\WEX\LOG
SET WEXACHOutgoingFileOUT=%base%\Dump\AOC\ACH\Outgoing\WEX\OUT


REM Environment Variables which were missing but available In test
SET FinalLendingClubACHOutgoingFileIN=%base%\Dump
SET TestBankCADACHOutgoingFileIN=%base%\Dump
SET TestBankUSAACHOutgoingFileIN=%base%\Dump
SET GreenSkyACHOutgoingFileIN=%base%\Dump
SET DemoACHOutgoingFileIN=%base%\Dump


SET interface_ca=CI_DB
SET EFBatchQueue=%base%\Final\Outgoing File\Auth Recon\Final
SET AuthScalePath=%base%\Final\Outgoing File\Auth Recon\Final
SET ClearingQueue=%base%\Final\Outgoing File\Auth Recon\Final
SET mcoutput_path=%base%\Final\Outgoing File\Auth Recon\Final
SET SCALE_RESTART_INI=%base%\Final\Outgoing File\Auth Recon\Final


SET ACHFileOut=%base%\Dump\Final\ACH\Outgoing

SET ACHFileOUT_AOC=%base%\Dump\AOC\ACH\Outgoing

SET CBR_ErrorFolder=%base%\CBR\Error

SET CBR_LogFileFolderName=%base%\CBR\log

SET CBR_OutputFolder=%base%\CBR\Output

SET DemoACHOutgoingFileERROR=%base%\Dump\Demo\ACH\Outgoing\Demo\ERROR

SET DemoACHOutgoingFileLOG=%base%\Dump\Demo\ACH\Outgoing\Demo\LOG

SET DemoACHOutgoingFileOUT=%base%\Dump\Demo\ACH\Outgoing\Demo\OUT

SET FinalLendingClubACHOutgoingFileERROR=%base%\Dump\Final\ACH\Outgoing\FinalLendingClub\ERROR

SET FinalLendingClubACHOutgoingFileLOG=%base%\Dump\Final\ACH\Outgoing\FinalLendingClub\LOG

SET FinalLendingClubACHOutgoingFileOUT=%base%\Dump\Final\ACH\Outgoing\FinalLendingClub\OUT

SET FinalReconFilePathName_LendingClub=%base%\Dump\Final\AuthReconFile

SET GreenSkyACHOutgoingFileERROR=%base%\Dump\GreenSky\ACH\Outgoing\GreenSky\ERROR

SET GreenSkyACHOutgoingFileLOG=%base%\Dump\GreenSky\ACH\Outgoing\GreenSky\LOG

SET GreenSkyACHOutgoingFileOUT=%base%\Dump\GreenSky\ACH\Outgoing\GreenSky\OUT

SET Logfolder=%base%\Dump\TideWater\TideWater_Clearing\ClearingOutFIles_Tidewater\Log\

SET NEW_OFAC_ERROR=%base%\OFAC\NEW_OFAC_ERROR

SET NEW_OFAC_IN=%base%\OFAC\NEW_OFAC_IN

SET NEW_OFAC_LOG=%base%\OFAC\NEW_OFAC_LOG

SET NEW_OFAC_OUT=%base%\OFAC\NEW_OFAC_OUT

SET OutFileGeneration_TW=%base%\Dump\TideWater\TideWater_Clearing\ClearingOutFIles_Tidewater

SET PathNameCBR=%base%\CBR

SET TestBankCADACHOutgoingFileERROR=%base%\Dump\AOC\ACH\Outgoing\TestBankCAD\ERROR

SET TestBankCADACHOutgoingFileLOG=%base%\Dump\AOC\ACH\Outgoing\TestBankCAD\LOG

SET TestBankCADACHOutgoingFileOUT=%base%\Dump\AOC\ACH\Outgoing\TestBankCAD\OUT

SET TestBankUSAACHOutgoingFileERROR=%base%\Dump\AOC\ACH\Outgoing\TestBankUSA\ERROR

SET TestBankUSAACHOutgoingFileLOG=%base%\Dump\AOC\ACH\Outgoing\TestBankUSA\LOG

SET TestBankUSAACHOutgoingFileOUT=%base%\Dump\AOC\ACH\Outgoing\TestBankUSA\OUT


REM ENvironment variables for Base Lock Box 
SET LockBoxIN=%base%\Dump\LockBox\IN
SET LockBoxOUT=%base%\Dump\LockBox\OUT
SET LockBoxError=%base%\Dump\LockBox\ERROR
SET LockBoxLog=%base%\Dump\LockBox\LOG
SET BulkCompromisedCardFiles=%base%\CoreBankCard\Dump
SET PortalBulkCardFile=%base%\CoreBankCard\Dump
SET BulkCardFileResponse=%base%\Dump\BulkResponseFile\PythonScript\Incoming_file
SET PlatReconFilePathName=%base%\Dump\AuthReconFile

SET Enviroment=Production

SET VISAFileIN=%base%\Dump\VISARecon\VisaFileIn
SET VISAFileOut=%base%\Dump\VISARecon\VisaFileOut
SET VISAFileError=%base%\Dump\VISARecon\VisaFileError
SET VISAOutBound=%base%\Dump\VISARecon\OutBound
SET VISA_LOG=%base%\Dump\VISARecon\Log


SET DBMSReconCountCommit=1000

SET conversion_intermidiate_db_name=CCGS_CoreIssue

SET WEEKDAYBUSSINESSHOURSFROM=070000
SET WEEKDAYBUSSINESSHOURSTO=160000
SET WEEKENDBUSSINESSHOURSFROM=070000
SET WEEKENDBUSSINESSHOURSTO=120000



SET CoreCreditLink=https://ccCoreCredit.corecard.com


REM PlatLockBox
SET PLATLockBoxIN=%BASE%\Dump\Plat\LockBox\IN
SET PLATLockBoxOUT=%BASE%\Dump\Plat\LockBox\OUT
SET PLATLockBoxError=%BASE%\Dump\Plat\LockBox\ERROR
SET PLATLockBoxLog=%BASE%\Dump\Plat\LockBox\LOG
SET PLATLockBoxBlankFile=%BASE%\Dump\Plat\LockBox\BLANK
SET PLATLockBoxFileServerPath=%BASE%\Dump\Plat\LockBox\OUT
REM SET PLATLockBoxFileServerPath=%BASE%\Dump\Plat\LockBox\OUT

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
SET PLATISOACHIncomingFileIN=%BASE%\Dump\ACH\ACHISOReturn\IN
SET PLATISOACHIncomingFileOUT=%BASE%\Dump\ACH\ACHISOReturn\OUT
SET PLATISOACHIncomingFileLOG=%BASE%\Dump\ACH\ACHISOReturn\LOG
SET PLATISOACHIncomingFileERROR=%BASE%\Dump\ACH\ACHISOReturn\ERROR
SET GreenSkySSPortalProd=https://www.MyGreenSky.com


SET GS_CBREPORTING_LOGFILE_PATH=%base%\CBR\GreenSky\LogFile
SET GS_CBREPORTING_FILE_PATH=%base%\CBR\GreenSky\File

SET GLDataFeed_IN=%Base%\Dump\GL\GLPostingDataFeed_IN
SET GLDataFeed_OUT=%Base%\Dump\GL\GLPostingDataFeed_OUT
SET GLDataFeed_Error= %base%\Dump\GL\GLPostingDataFeed_Error
SET GLDataFeed_Log=%Base%\Dump\GL\GLPostingDataFeed_Log

REM PIIHub API Call from Which Environment DEV,PROD,QA,UAT,PATUAT,PATQA,PERFPROD
REM Earlier variable already introduced, For Local Testing, Use DEV
SET PlatPIIHubEnv=PROD
SET PlatPIIHubTokenEnv=PROD
SET PlatAutoRewardRedeem=PROD
SET RelaxIssueStatusCheckForActivation=PROD


SET Loyalty_FileIN=%Base%\Dump\LoyaltyTP\InputFile
SET Loyalty_FileOUT=%Base%\Dump\LoyaltyTP\OutputFile
SET Loyalty_FileERROR=%Base%\Dump\LoyaltyTP\ErrorFile
SET Loyalty_FileLOG=%Base%\Dump\LoyaltyTP\LogFile
SET MailTo=Dummy
SET MailFrom=Dummy
SET SMTP_SERVER=Dummy
SET SMTPPORT=Dummy

REM GreenSkyMerchantACHSettlement outgoing File New Env variable 
SET GreenSkyMerchantACHSettlementIN=%Base%\Dump\GreenSky\ACH\MerchantSettlementOutgoing\IN
SET GreenSkyMerchantACHSettlementOUT=%Base%\Dump\GreenSky\ACH\MerchantSettlementOutgoing\OUT
SET GreenSkyMerchantACHSettlementLOG=%Base%\Dump\GreenSky\ACH\MerchantSettlementOutgoing\LOG
SET GreenSkyMerchantACHSettlementERROR=%Base%\Dump\GreenSky\ACH\MerchantSettlementOutgoing\ERROR
SET GreenSkyMerchantACHSettlementIntermediate=%Base%\Dump\GreenSky\ACH\MerchantSettlementOutgoing\Intermediate



SET ManualCheckOutFile=%Base%\Dump\ManualCheck\OUT
SET ManualCheckLogFile=%Base%\Dump\ManualCheck\LOG

REM DownloadRoutingFile
SET RoutingRecordFileLocation=%BASE%\Dump\RoutingFile\IN
SET RoutingRecordFileOUT=%BASE%\Dump\RoutingFile\OUT
SET RoutingRecordFileLOG=%BASE%\Dump\RoutingFile\LOG

REM SET RoutDownloadFileLocation=https://www.frbservices.org/EPaymentsDirectory/FedACHdir.txt
SET RoutDownloadFileLocation=https://www.frbservices.org/EPaymentsDirectory/FedACHdir.txt?AgreementSessionObject=Agree

SET IrvingReport_FileIN=%base%\Dump\IrvingReport\IN
SET IrvingReport_FileOUT=%base%\Dump\IrvingReport\OUT
SET IrvingReport_FileERROR=%base%\Dump\IrvingReport\ERROR
SET IrvingReport_FileLOG=%base%\Dump\IrvingReport\LOG


REM Added Env Variable for Delenquent Account File, plz update file location
SET DelinquentAccountFileInputDir=%base%\Dump\DelinquentAccountFile\Input
SET DelinquentAccountFileArchiveDir=%base%\Dump\DelinquentAccountFile\Archive
SET DelinquentAccountFileErrorDir=%base%\Dump\DelinquentAccountFile\ERROR
SET DelinquentAccountFileLOGDir=%base%\Dump\DelinquentAccountFile\LOG


REM SET this NO in Credit and YES for Plat env
SET OverrideLogoCardTermForReissue=YES

REM CollateralID Update via file
SET CIBUpdateInputFile=%base%\Dump\CIBUpdate\INPUT
SET CIBUpdateErrorFile=%base%\Dump\CIBUpdate\ERROR
SET CIBUpdateOutFile=%base%\Dump\CIBUpdate\OUT
SET CIBUpdateLogFile=%base%\Dump\CIBUpdate\LOG
SET CIBUpdateProcessedFile=%base%\Dump\CIBUpdate\PROCESSED
REM SET InsitutionID=6969

REM Added Env Variable for Past Due Authorization strategy File, plz update file location
SET PastDueAuthStrategyInputDir=%base%\Dump\Plat\PastDueAuthStrategy\Input
SET PastDueAuthStrategyArchiveDir=%base%\Dump\Plat\PastDueAuthStrategy\Archive
SET PastDueAuthStrategyErrorDir=%base%\Dump\Plat\PastDueAuthStrategy\ERROR
SET PastDueAuthStrategyLOGDir=%base%\Dump\Plat\PastDueAuthStrategy\LOG

REM Added new Env Variables for IPM error reporting (please update file locations)
REM SET IPMErrorReportFile=%base%\Dump\MasterCard\IPMSettlement\Report\Archive
REM SET IPMErrorReportArchive=%base%\Dump\MasterCard\IPMSettlement\Report\ErrorReport\Archive
REM SET IPMErrorReportLOG=%base%\Dump\MasterCard\IPMSettlement\Report\ErrorReport\LOG
REM SET IPMErrorReportERROR=%base%\Dump\MasterCard\IPMSettlement\Report\ErrorReport\ERROR

SET DummyMmsApiResult=Dummy
SET GreenSkyEmailFrom=Dummy
SET GreenSkyMailServerName=Dummy

REM Flag To Activate StatementValidation
SET StatementValidationActivation=TRUE
SET IPMBatchRecordCount=25000
SET UsePIIFromBearerForEmbossing=YES
SET GSPendingAppEmail=Dummy

REM Added for svcGetWelcomePackageURL, Value of this variable has to be Equal to respective environment's CoreAppSetup's ApplicationLetterHost Env. Variable.
REM Value Of this variable for CP Test region has to be - https://testcoreconsumer.corecard.com/
REM Value of this variable for CP Prod region has to be - https://coreconsumer.corecard.com/
SET ApplicationLetterHost=http://LocalHost/

REM Plat BillPayPayment Environment variables 
SET BillPayPaymentIN=%base%\Dump\Plat\BillPayPayment\IN
SET BillPayPaymentOUT=%base%\Dump\Plat\BillPayPayment\OUT
SET BillPayPaymentERROR=%base%\Dump\Plat\BillPayPayment\ERROR
SET BillPayPaymentLOG=%base%\Dump\Plat\BillPayPayment\LOG

REM GreenSky Merchant ACH Incoming File Env variable 
SET GreenSky_Settle_ACHFileBLANKFILE=Dummy

REM GreenSky ACH Incoming File Env variable 
SET GreenSky_ACHFileBLANKFILE=Dummy

REM DeserveCheckCBRFile
SET DeserveCheckCBRFileIN=Dummy
SET DeserveCheckCBRFileLOG=Dummy
SET DeserveCheckCBRFileERROR=Dummy

REM LOCKBOX SUMMARY MAIL
SET LockBoxMailFrom=Dummy
SET LockBoxMailTo=Dummy


REM API Log variables only for green sky .
SET APILOg_FILE_PATH=Dummy
SET APILOg_LOGFILE_PATH=Dummy

SET ChargeBackTQR4File=%base%\Dump\MasterCard\IPMSettlement\ChargebackTQR4\TQR4
SET ChargeBackTQR4Archive=%base%\Dump\MasterCard\IPMSettlement\ChargebackTQR4\Archive
SET ChargeBackTQR4LOG=%base%\Dump\MasterCard\IPMSettlement\ChargebackTQR4\LOG
SET ChargeBackTQR4ERROR=%base%\Dump\MasterCard\IPMSettlement\ChargebackTQR4\ERROR



REM Added to write Statement Data in  Kafka Queue  (It requires StatementValidationActivation= TRUE)
SET KafkaDataProcessing=False

REM Put Kafka host server name instead of "localhost"
SET StatementDataHostName=localhost
SET BulkCardFileResponseLog=%base%\Dump\BulkResponseFile\LOG
SET BulkCardDetailFilePath=%base%\Dump\BulkResponseFile\IntermediateFiles

SET WlcmPackURL=Dummy
SET WlcmPackHost=Dummy
SET PORTNUM=Dummy

SET emPassword=rd@PRODr03CC
SET InterestAlertByTNP=0


SET emKMSdefaultMachines=CCKMSe1PRODb1 CCKMSe1PRODb2 CCKMSe1PRODb3 CCKMSe1PRODb4 CCKMSe1PRODb5 CCKMSe1PRODb6 CCKMSe1PRODb7


SET emThalesConnectionAddrBase=prod.hsm.infra.marcus.com prod-apps.hsm.infra.marcus.com


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
SET IPMCSVFilePath=%base%\Dump\MasterCard\Dummy
REM SET own mailID
SET MrgActFailedAlertFrom=Dummy
SET MrgActFailedAlertTo=Dummy
REM When UseCCardOrCCard2_IPM=0 then IPM Transaction will be inserted in CCard_Primary, When 1 then IPM Transaction will be inserted in CCard_Primary2
SET UseCCardOrCCard2_IPM=1
SET ExecuteParsingWorkStep=2
SET EmbEncryptedChunkSize=50
REM JSON File will be created here
SET JSONCreatedFileLocation=D:\DBBSetup\Dump\MasterCard\IPMSettlement\Incoming\IPMJSON\
REM Application will read JSON File from this location
SET JSONReadFileLocation=D:\DBBSetup\Dump\MasterCard\IPMSettlement\Incoming\OUT\
SET IPMJSONCreatedFileLocation=D:\DBBSetup\Dump\MasterCard\IPMSettlement\Incoming\IPMJSON

SET PodActiveTQR4=0
SET ChargeBackTQR4ArchivePOD=%base%\Dump\MasterCard\IPMSettlement\ChargebackTQR4\ChargeBackTQR4ArchivePOD
REM SET GLDataFeed_IN=%base%\Dump\GL\GLDataFeeds_IN
REM SET GLDataFeed_Log=%base%\Dump\GL\GLDataFeeds_Log
REM SET GLDataFeed_OUT=%base%\Dump\GL\GLDataFeeds_OUT
REM SET GLDataFeed_Error=%base%\Dump\GL\GLDataFeeds_Error

SET IPMCallInterval=1
SET CBRecordUpdateChunk=1000
SET CBR_PIIFileIntermediate = %base%\CBRReporting\Intermediate
SET CBR_LogFileFolderName = %base%\CBRReporting\log

REM Update PlatModelScore value 
SET PlatModelScore=PROD
SET DummyModelScore=Dummy
REM changed Value of MultiPODEnabled_IPM from 0 to 1 to support MultiPOD in PLAT Prod Env
SET MultiPODEnabled_IPM=1
REM IPMValidationEnable 1 = Enable (SP :PR_MCIPMValidation) ,0 = Disable 
SET IPMValidationEnable=1

REM Modify variable to add servicegroup
SET LockBoxMailTo=servicegroup@corecard.com
REM 1 for 2 calls | 0 for 1 call
SET TokenRefreshCall=0

SET EnableExceptionTest=0
SET IPMJobIdForRetry=0
REM MrgActAutoRetryEnable=1 for Testing Team to test and verify, for Prodcution Env. it should be 0
SET MrgActAutoRetryEnable=1

REM TestPIIAPI variable will be used for developer testing
SET TestPIIAPI=NO

REM Below added Environment variable will be used exclusively for Reconciliation/Settlement related Notification/Alerts.
SET MailServerName_StlRcn=corecard-com.mail.protection.outlook.com
SET MailSender_StlRcn=pod2-PROD-alerts@infra.marcus.com
SET MailReceiver_StlRcn=controlteam@corecard.com, platjazz_reconsettlementappdev@corecard.com

REM Value - 0, for regular CBR file generation (Used in WF_CBRGetPIIInfo)
REM Value - 1, Only record will be inserted into CBRPIIData table for CBR file generation (Used in WF_CBRGetPIIInfo)
SET TestCBRFileWithoutPII=0

SET emThalesMonitorInterval=120
SET emThalesCBTestInterval=300

REM It should get assigned with Link Server String from Main to Reporting Server
SET RptSrvrName_StlRcn=LISTRPT

REM It should get assigned with CI db name at Reporting Server
SET RptSrvrCIDbName_StlRcn=CCGS_RPT_CoreIssue

REM Time (HHMM 24 hours format), On or after that JAZZ files will be Holded
SET FileHoldTime=1600

REM It will inform that what extension files will be considered for Hold (if it is not assigned, then no file will be Holded)
SET FileToBeHold=A001,A002,A004,A006,IPM

REM It should call "BHUBAPI" for Thirdparty API
SET UseBhubFromBearerForEmbossing=NO

REM This variable should contain all file Extensions in the sequence they arrive in Production Environment
REM In Lower/POD_2 Environments, file sequence should be as per file sequence of that env, e.g. A004,A005,A006,A001,A002
SET IPMFileSequence=A004,A005,A006,A001

SET MessageQueueService=SQS

REM Use to enable/disable PII API call inside Extract CBR WF. 0-No, 1-Yes [ADD IF NOT EXISTS, ELSE MODIFY]
SET CBRPIICallInAPI=0
REM During PII Fetch SET use of CBRStatementDetails table. 0-No, 1-Yes

SET UseCBRStatementDetails=0
REM Use to enable/disable PII API call during schedule creation. 0-No, 1-Yes
SET ACHPIICallInAPI=1

REM Use to sqs Message Data For SQS Statement PDF Generation 
REM This will work on your Setup / now value is defuslt please SET as per your Setup 
REM it will work with platform SQS feature - 4.2.42.21

REM AWS Access key from application
SET AWS_ACCESS_KEY_ID=NONE
SET KMSENC:AWS_SECRET_ACCESS_KEY=NONE
SET StatementDataQueueName=CCPOD2-SQSQueue-PROD-us-east-1
REM SQS Message store Variables
SET SQSRole=NONE
SET SQSURL=https://sqs.us-east-1.amazonaws.com/113922610496
SET SQSS3Bucket=corecard-pod2-prod-us-east-1-statement-gen/extended-SQS-pod2
SET SQSRegion=us-east-1
SET SQSSTSlink=https://sts.us-east-1.amazonaws.com
SET SQSSTSRegion=us-east-1
SET SQSS3Url=https://s3.us-east-1.amazonaws.com
SET SQSS3Region=us-east-1
SET TQR4Report=3
REM to store API response in local
REM APIStore=Local for local qa Testing and S3 bi
SET APIStore=S3
SET StatementmetaDataPath=D:\DBBSetup\Dump\statementmetadata\
REM to store API response in s3
SET S3URL=https://s3.us-east-1.amazonaws.com
SET S3Role=NONE
SET S3BucketName=corecard-pod2-prod-us-east-1-statement-gen/notifications
SET S3Region=us-east-1
SET S3STSUrl=https://sts.us-east-1.amazonaws.com
SET S3STSRegion=us-east-1

REM S3 Statement MetaData Alert
SET S3URLAlert=https://s3.us-east-1.amazonaws.com
SET S3BucketNameAlert=NONE
SET S3RegionAlert=us-east-1
SET STMTDataQueueNameAlert=NONE

REM SQS Statement MetaData Alert
SET AWSRoleAlert=NONE
SET SQSURLAlert=NONE
SET SQSRegionAlert=us-east-1

REM Use to enable/disable PII API call inside Extract CBR WF. 0-No, 1-Yes (Do not add variable if exists/only update the value)
SET SeperateFileForOvernightDelivery=0
REM KafkaDataProcessing Removed from Setup file.

REM Exclude current day in count of Payment hold Days if SET to TRUE
SET ExcludeCurrenDayinHPOTB=TRUE
SET _emRatioMinMaxLimit=1
SET ShardTimeout=4000
REM time out time for cassandra
SET CurrentShard=SHARD1
SET PoddingSupported=0
REM Restrict insertion of transaction in DoDetailTxn Table if SET to False
SET DoDetailTxn=FALSE

REM External ID required AWS AssumeRole
SET SQSExternalID=NONE
SET S3ExternalID=NONE
SET AlertSQSExternalID=NONE
SET AlertS3ExternalID=NONE
REM Environment variable for stop purge transaction posting , possible value are NO/YES. NO means transaction will post , YES means transaction will not post.
SET StopPurgePosting=YES

REM Flags TO GENERATE OLD DATED XMLPDF
SET TestStatementDataQueueName=CCPOD2-SQSQueue-PROD-us-east-1
SET TestSQSS3Bucket=corecard-pod2-prod-us-east-1-statement-gen/extended-SQS-pod2
SET TestSQSURL=https://sqs.us-east-1.amazonaws.com/113922610496
SET TestSQSS3Url=https://s3.us-east-1.amazonaws.com
SET TestS3BucketName=corecard-pod2-prod-us-east-1-statement-gen/notifications
SET TestS3URL=https://s3.us-east-1.amazonaws.com
SET TestMessageQueueService=SQS
SET CreditStrategyCSVfileArchive=D:\DBBSetup\Dump\Delinquent\CSVFile
SET CreditStrategyCallInterval=10
SET SQSCustomURL=NONE
SET _emSQSMinLengthForCompression=0
SET KMSENC_S3ExternalID=
SET KMSENC_SQSExternalID=
SET _emDBPDdisable=1
SET AllowExtendExpirationDate=PROD
REM SET KMSENC_AWS_SECRET_ACCESS_KEY=
SET STMTRetryThreshold=5
SET CollFeeException=%base%\Dump\MasterCard\IPMSettlement\Report\Exception
SET Key_Family_For_KeyedHash=7
SET _emDoubleDecimalPlaces=12
SET _emExprNvlCurrencyCorrect=0
SET _emConsiderServiceExecErrCritical=0
SET Key_Family_For_Keyed_Hash=16
SET PanhashIsUnique=0
SET emPAN_HMACKeyFamily=5
SET emPAN_HMACAcrossPodKeyFamily=16