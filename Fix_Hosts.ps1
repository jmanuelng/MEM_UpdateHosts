<#
.SYNOPSIS
    Updates "hosts" file.

.DESCRIPTION
    For use as remediation script in "Proactive Remediation" in Microsoft Intune.
    Script to update hosts file using Proactive Remediation.
    Will verify all IP addresses in the hosts file, if there is a match it will update it with information on the entries list.
    If there is an IP missing it will append it to the hosts file.

.NOTES
    Script considers multiple names for a single IP. Super bad idea, not recommended, might not be that common, but it does happen.
    Example of Hosts file with multiple names for same IP:
        https://www.ibm.com/docs/en/aix/7.2?topic=formats-hosts-file-format-tcpip

#>


#Region Initialize

$Error.Clear()
$t = Get-Date
#New lines, easier to read Agentexecutor Log file.
Write-Host "`n`n"
#Log start time.
Write-Output "Host file update start time: $t"

#Endregion Initialize

#Region Functions
function Set-HostEntries([hashtable] $entries) {
    $hostsFile = "$env:windir\System32\drivers\etc\hosts"   #Path to hosts file
    $ip = ""    #IP that we'll add or change in the host file
    $hostnames = ""  #Host name or host names that we'll associate to the IP
    $newLines = @()

    $c = Get-Content -Path $hostsFile
    foreach ($line in $c) {
        $bits = [regex]::Split($line, "\s+")
        
        #If the line is not a comment and has more 2 or more words check the IP. 
        #   If it's an IP from out entries list replace it / update it. 
        if (($bits[0] -ne "#") -and ($bits.Count -ge 2)) {
            $match = $null
            foreach ($entry in $entries.GetEnumerator()) {          
                if ($bits[0] -eq $entry.Key) {
                    
                    #Found an ip match in current line, updating it to match ip and hostname from entries list.
                    Write-Host "Updating entry for IP $($entry.Key)."
                    $ip = $entry.Key
                    $hostnames = ""
                    foreach ($value in $entry.Value) {
                        $hostnames += "`t" + $value
                    }
                    $newLines += ($ip + $hostnames)
                    $match = $entry.Key
                    break
                    
                }
            }
            if ($null -eq $match) {
                #Line didn't match one of the IPs in our entries list, so line stays as is, no changes
                $newLines += $line
            }
            else {
                #If we found a match and updated the Hosts entry, let's remove that IP from the entries list.
                $entries.Remove($match)
            }

        }
        else {
            #Line stays the same.
            $newLines += $line
        }

    }

    #Add all remaing IPs/hostnames from the entries list to Hosts file.
    foreach($entry in $entries.GetEnumerator()) {
        $ip = $entry.Key
        $hostnames = ""
        Write-Host "Adding HOSTS entry for IP $ip"
        foreach ($value in $entry.Value) {
            $hostnames += "`t" + $value
        } 
    
        $newLines += ($ip + $hostnames)

    }

    #Write Hosts file with changes made.
    Write-Host "Saving $hostsFile"
    Clear-Content $hostsFile
    foreach ($line in $newLines) {
        $line | Out-File -encoding ASCII -append $hostsFile
    }
}

# Endregion Functions

#Region Main

$entries = @{
    '192.168.0.1' = "host01", "host01.example.dom"
    '192.168.0.2' = "host02", "host02.example.dom"
    '192.168.0.3' = "host03.example.dom"
};

Set-HostEntries($entries)

Write-Host "`n`n"

#Log finish time.
Write-Output "INFO $t$([datetime]::Now) : Hosts file update finished"
#New lines, easier to read Agentexecutor Log file.

#Endregion Main