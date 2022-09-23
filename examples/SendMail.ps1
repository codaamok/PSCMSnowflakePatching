Import-Module 'PSWriteHtml','PSCMSnowflakePatching' -ErrorAction 'Stop'

$result = Invoke-CMSnowflakePatching -ComputerName 'Veeam','CA' -AllowReboot -Attempts 3

if ($result) {
    $EmailSplat = @{
        To             = 'john@doe.co.uk'
        From           = 'john@doe.co.uk'
        Priority       = 'High'
        Subject        = 'Patching report'
        Username       = 'john@doe.co.uk'
        Server         = 'smtp.office365.com'
        Password       = 'password'
        SSL            = $true
        Port           = 587
        AttachSelf     = $true
        AttachSelfName = 'Patching report'
    }
    
    Email @EmailSplat {
        EmailBody {
            EmailText -Text 'The following server(s) were patched, and rebooted as deemed necessary.'
            EmailText -Text 'Please review the post-patching status report below:'
            EmailText -LineBreak
    
            $Properties = 'ComputerName','Result','OperatingSystem','PingResponse','TotalTime','NumberOfReboots','NumberOfAttempts','IsPendingReboot','LastBootUpTime'
            EmailTable -DataTable $result -IncludeProperty $Properties {
                EmailTableCondition -ComparisonType 'string' -Name 'PingResponse' -Operator eq -Value 'False' -BackgroundColor 'Red' -Color Black -Row -Inline
                EmailTableCondition -ComparisonType 'string' -Name 'Result' -Operator ne -Value 'Success' -BackgroundColor 'Red' -Color Black -Row -Inline
                EmailTableCondition -ComparisonType 'string' -Name 'Result' -Operator eq -Value 'Success' -BackgroundColor 'Green' -Color Black -Row -Inline
                EmailTableCondition -ComparisonType 'string' -Name 'IsPendingReboot' -Operator eq -Value 'True' -BackgroundColor 'Orange' -Color Black -Row -Inline
            }
        }
    }
}
