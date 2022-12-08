<#
.SYNOPSIS
    Updates "hosts" file.

.DESCRIPTION
    For use as detection script in "Proactive Remediation" in Microsoft Intune.
    Script to detect if all IPs in entry lists already exist in Hosts file.

.NOTES

#>

#region Initialize

$Error.Clear()
$missingIp =""
#New lines, easier to read Agentexecutor Log file.
Write-Host "`n`n"


#endregion

#region Functions
function Search-HostEntries([hashtable] $entries) {
    $hostsFile = "$env:windir\System32\drivers\etc\hosts"   #Path to hosts file

    $c = Get-Content -Path $hostsFile
    foreach ($line in $c) {
        $bits = [regex]::Split($line, "\s+")
        
        #   If it's an IP from out entries list then you can erease that entry. 
        #   Empty entries list at end of lines in hosts file = Exit 0, no issues
        
        #If the line is not a comment and has more 2 or more words check the IP. 
        if (($bits[0] -ne "#") -and ($bits.Count -ge 2)) {
            $match = $null
            foreach ($entry in $entries.GetEnumerator()) {          
                if ($bits[0] -eq $entry.Key) {
                    
                    #Found an ip match in current line, then mark match. We'll remove it from entries list later.
                    Write-Host "Found match for IP $($entry.Key)."
                    $match = $entry.Key
                    break
                    
                }
            }
            if ($null -eq $match) {
                #Line didn't match one of the IPs in our entries list, do nothing, this is the detection script.
            }
            else {
                #If we found a match, then this IP can be removed from the entries list.
                $entries.Remove($match)
            }
        }
    }


    #Is there any IP from the entries list missing in the hosts file? 
    #   If there is then fail, Exite 1.
    #   If not, then success, no issues found here, move on.
    if ($entries.Count -ge 1) {

        #List of missing IPs
        foreach ($entry in $entries.GetEnumerator()) {
            if ( -not ($missingIp -eq "")) { $missingIp += ", "}
            $missingIp += "$($entry.Key)"
        }

        Write-Warning "ERROR $([datetime]::Now) : IPs missing $missingIp."
        Exit 1

    }

}

#endregion

#region Main

$entries = @{
    '192.168.0.1' = "host01", "host01.example.dom"
    '192.168.0.2' = "host02", "host02.example.dom"
    '192.168.0.3' = "host03.example.dom"
};

Search-HostEntries($entries)

Write-Host "`n`n"

#If we've made it till here, then we're clear, no errors.
Write-Host "INFO $([datetime]::Now) : All IPs in entries list found."

Exit 0

#endregion