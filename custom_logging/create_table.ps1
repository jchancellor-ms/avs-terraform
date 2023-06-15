$tableParams = @'
{
    "properties": {
        "schema": {
            "name": "AVSLogFiltered_CL",
            "columns": [
                {
                    "name": "TimeGenerated",
                    "type": "datetime",
                    "description": "The time at which the data was generated"
                },
               {
                    "name": "AppName",
                    "type": "string",
                    "description": "The name of the application that generated this log"
                },
                {
                    "name": "Facility",
                    "type": "string",
                    "description": "Source that generated the syslog"
                },
                {
                    "name": "HostName",
                    "type": "string",
                    "description": "The name of the host that generated this log if available"
                },
                {
                    "name": "LogCreationTime",
                    "type": "datetime",
                    "description": "The time the log was created if available."
                },
                {
                    "name": "Message",
                    "type": "string",
                    "description": "The entire syslog message."
                },
                {
                    "name": "MsgId",
                    "type": "string",
                    "description": "Identifies the type of message."
                },
                {
                    "name": "ProcId",
                    "type": "string",
                    "description": "Identifies a process."
                },
                {
                    "name": "Severity",
                    "type": "string",
                    "description": "The severity of the log."
                },
                {
                    "name": "SourceSystem",
                    "type": "string",
                    "description": "Source system where available."
                }
            ]
        }
    }
}
'@

Invoke-AzRestMethod -Path "/subscriptions/1caa5ab4-523f-4851-952b-1b689c48fae9/resourcegroups/logfiltertesting/providers/microsoft.operationalinsights/workspaces/logFilterTestingWorkspace/tables/AVSLogFiltered_CL?api-version=2021-12-01-preview" -Method PUT -payload $tableParams