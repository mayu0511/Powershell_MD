class SetUp:
    POTBInputFile = "D:\DBBSetup\Dump\POTB\Input"
    POTBErrorFile = "D:\DBBSetup\Dump\POTB\ERROR"
    POTBOutFile = "D:\DBBSetup\Dump\POTB\OUT"
    POTBLogFile = "D:\DBBSetup\Dump\POTB\LOG"
    InsitutionID = 6981
    MailFrom = "pod2-dev-alerts@infra.marcus.com"
    MailTo = "Pod2ConfigTeam@corecard.com,Raktim.Mitra@ny.email.gs.com,gs-credit-cookie-cm-jobs@ny.email.gs.com,platalertsupport@corecard.com"
    SMTP_SERVER = "10.32.14.1"
    SMTPPORT = 25
    CI_DB = "CCGS_CoreIssue"
    CL_DB = "CCGS_CoreLibrary"
    CAuth_DB = "CCGS_CoreAuth"
    SERVERNAME = "CCAPPLIST1"

	
    #Irving Embossing File Setup..................................
    OutGoing_Emb_In='D:\DBBSetup\Dump\Embossing\Irving'
    OutGoing_Emb_Error_Dir='D:\DBBSetup\Dump\Embossing\Irving\ERROR'
    OutGoing_Emb_Processed='D:\DBBSetup\Dump\Embossing\Irving\OUT'
    OutGoing_Emb_Log_Dir='D:\DBBSetup\Dump\Embossing\Irving\LOG'
    
    SQLLiteDBPath='D:\DBBSetup\Dump\Embossing\Irving\SQLite_DB'   
	
    OTBReleaseFileIN='D:\DBBSetup\Dump\OTBRelaseAPI\Incoming_file'
    OTBReleaseFileError='D:\DBBSetup\Dump\OTBRelaseAPI\Error'
    OTBReleaseFileOUT='D:\DBBSetup\Dump\OTBRelaseAPI\Processed'
    OTBReleaseFileLog='D:\DBBSetup\Dump\OTBRelaseAPI\Log'
    SQLLiteOTBDBPath='D:\DBBSetup\Dump\OTBRelaseAPI\SQLite_DB'
    BulkCardResponseFileIN='D:\DBBSetup\Dump\BulkResponseFile\PythonScript\Incoming_file'
    BulkCardResponseFileError='D:\DBBSetup\Dump\BulkResponseFile\PythonScript\Error'
    BulkCardResponseFileOUT='D:\DBBSetup\Dump\BulkResponseFile'
    BulkCardResponseFileLog='D:\DBBSetup\Dump\BulkResponseFile\PythonScript\Log'
    SQLLiteBulkCreationPath='D:\DBBSetup\Dump\BulkResponseFile\PythonScript\SQLite_DB'
    RetailInputFile = 'D:\DBBSetup\Dump\MilkReplaySchedules\INPUT'
    RetailErrorFile = 'D:\DBBSetup\Dump\MilkReplaySchedules\ERROR'
    RetailOutFile = 'D:\DBBSetup\Dump\MilkReplaySchedules\OUT'
    RetailLogFile = 'D:\DBBSetup\Dump\MilkReplaySchedules\LOG'
    RetailInsitutionID = 6981
    RetailEnvironment = "dev"
    RetailExceptionFile = "D:\DBBSetup\Dump\MilkReplaySchedules\EXCEPTION"
    RetailExceptionFilePrefix = "EXCP_"
    RetailExceptionFileSuffix = "_PODID_"
    RetailFileProcessingPOD = "POD2"
    RetailAWSEnvironment = 1
    RetailAWS_secret_name = "ses-smtp-dev-secret"
    RetailAWS_region_name = "us-east-1"
    RetailAWS_service_name = "secretsmanager"
    RetailSES_smtp_url = "email-smtp.us-east-1.amazonaws.com"
    RetailAWSPort = 587
    POTBEnvironment = "PLATDEV"
    POTBInstitutionID = 6969
    EnvironmentName = "PLATdev"
    IrvingReport_FileIN='D:\DBBSetup\Dump\IrvingReport\In'
    IrvingReport_FileERROR='D:\DBBSetup\Dump\IrvingReport\Error'
    IrvingReport_FileOUT='D:\DBBSetup\Dump\IrvingReport\Out'
    IrvingReport_FileLOG='D:\DBBSetup\Dump\IrvingReport\Log'
    IrvingReport_FileException="D:\DBBSetup\Dump\IrvingReport\Exception"
    IsEmbReportSplitByInsId = "YES"
    POTBPolicy = "G2"
    POTBIdentifier = "ACCOUNTNUMBER"
    IrvingReport_FileEmpty=r"D:\DBBSetup\Dump\IrvingReport\Out\6969"

    #AccountParametersUpdates.py File Setup..................................
    AccountUpdate_FileIN = "D:\DBBSetup\Dump\Embossing\WFAccountParametersUpdates\InputFolder"
    AccountUpdate_FileERROR = "D:\DBBSetup\Dump\Embossing\WFAccountParametersUpdates\ErrorFolder"
    AccountUpdate_FileLOG = "D:\DBBSetup\Dump\Embossing\WFAccountParametersUpdates\LogFolder"
    AccountUpdate_FileOUT = "D:\DBBSetup\Dump\Embossing\WFAccountParametersUpdates\OutFolder"
    AccountUpdate_EmptyFolder = "D:\DBBSetup\Dump\Embossing\WFAccountParametersUpdates\EmptyFolder"
    AccountUpdate_DebugMode = "D:\DBBSetup\Dump\Embossing\WFAccountParametersUpdates\ExceptionFolder"
    SERVERNAME = "CCAPPLIST1"
    CI_DB = "CCGS_CoreIssue"
    POTBAWSEnvironment = 1 # 0 = NotAWS, 1 = AWS environment
    POTBAWS_secret_name = "ses-smtp-dev-secret"
    POTBAWS_region_name = "us-east-1"
    POTBAWS_service_name = "secretsmanager"
    POTBSES_smtp_url = "email-smtp.us-east-1.amazonaws.com"
    POTBAWSPort = 587
# Define POD number
    POD = 2