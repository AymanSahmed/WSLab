Configuration Config {
    param 
    ( 
        [Parameter(Mandatory)] 
        [string]$NodeName
    )

    Node $NodeName
    {
        Script CreateFolder
        {
            SetScript = {New-Item -Type Directory -Name WSLab -Path d:}
            TestScript = {Test-Path -Path d:\WSLab}
            GetScript = {   @{Ensure = if (Test-Path -Path d:\WSLab) {'Present'} else {'Absent'}}   }
        }
        Script DownloadScripts
        {
            SetScript = {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -UseBasicParsing -Uri https://aka.ms/wslab/download -OutFile d:\scripts.zip
            }
            TestScript = {Test-Path -Path d:\scripts.zip}
            GetScript = { @{Ensure = if (Test-Path -Path d:\scripts.zip) {'Present'} else {'Absent'}} }
            DependsOn = "[Script]CreateFolder"
        }
        Script UnzipScripts
        {
            SetScript = {Expand-Archive d:\scripts.zip -DestinationPath d:\WSLab -Force}
            TestScript = {!("1_Prereq.ps1","2_CreateParentDisks.ps1","3_Deploy.ps1","Cleanup.ps1","LabConfig.ps1" | ForEach-Object {Test-Path -Path d:\WSLab\$_}).contains($false)}
            GetScript = {   @{Ensure = if (!("1_Prereq.ps1","2_CreateParentDisks.ps1","3_Deploy.ps1","Cleanup.ps1","LabConfig.ps1" | ForEach-Object {Test-Path -Path d:\WSLab\$_}).contains($false)) {'Present'} else {'Absent'}} }
            DependsOn = "[Script]DownloadScripts"
        }
        WindowsOptionalFeature HyperV
        {
            Name = "Microsoft-Hyper-V-All"
            Ensure = "Enable"
            DependsOn = "[Script]UnzipScripts"
        }

        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }
    }
}




