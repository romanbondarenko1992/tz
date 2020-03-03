while($true) {

Start-Transcript -path "C:\logging.log" -Force -IncludeInvocationHeader

function Write-Log($string)
{
    $dateTimeNow = Get-Date -Format "dd.MM.yyyy - HH:mm:ss"
    $outStr = "" + $dateTimeNow +" "+$string
 
	Write-Output $outStr 
    
}


$IISFeatures = "Web-WebServer","Web-Common-Http","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Redirect","Web-Health","Web-Http-Logging","Web-Custom-Logging","Web-Log-Libraries","Web-ODBC-Logging","Web-Request-Monitor","Web-Http-Tracing","Web-Performance","Web-Stat-Compression","Web-Security","Web-Filtering","Web-Basic-Auth","Web-Client-Auth","Web-Digest-Auth","Web-Cert-Auth","Web-IP-Security","Web-Windows-Auth","Web-App-Dev","Web-Net-Ext","Web-Net-Ext45","Web-Asp-Net","Web-Asp-Net45","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Mgmt-Tools","Web-Mgmt-Console"
$IISSite = "website.local"
$WebDir = "$env:systemdrive\inetpub\wwwroot"
$WebAppDir = "$env:systemdrive\inetpub\wwwroot\webapp"
$GitRepo = "https://github.com/TargetProcess/DevOpsTaskJunior.git"
$URL = "http://localhost/TestApp"
#Webhook Slack
$SlackChannelUri = "https://hooks.slack.com/services/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"
$BodyTemplate = @"
    {
        "username": "Web Bot",
        "text": "WebApp ok \nTime: DATETIME.",
        "icon_emoji":":ghost:"
    }
"@
$body = $BodyTemplate.Replace("DATETIME",$(Get-Date))
[string]$slack = if (((Invoke-WebRequest -Uri $URL).StatusCode) -eq 200) { Invoke-RestMethod -uri $SlackChannelUri -Method Post -body $body -ContentType 'application/json' }
#Get HTTP code and description
$httpcode = (Invoke-WebRequest -Uri $URL).StatusCode
$statuscodedesc = (Invoke-WebRequest -Uri $URL).StatusDescription



"===== Check IIS role ====="
if (-not (Get-WindowsFeature -Name Web-Server).Installed) {
  Install-WindowsFeature -name $IISFeatures -IncludeManagementTools 
  }
else { "OK" }

if (Get-website -Name "Default Web Site") {
  Remove-WebSite -Name "Default Web Site"
  }

"===== Check IIS service ====="
iisreset /start

"===== Check & Update WebApp ====="
if (-not (Test-Path -Path $WebAppDir)){
  New-Item -ItemType directory -Path $WebAppDir
  git clone $GitRepo $WebAppDir 2>&1 | write-host -foregroundColor "green"
  }
else { 
  cd $WebAppDir
  git pull
  "OK" 
  }

"===== Check IIS site ====="
if (-not (Get-website -Name $IISSite)) {
  New-WebSite -Name $IISSite -Port 80 -PhysicalPath $WebDir
  }
else { "OK" }

if ((Get-website -Name $IISSite).Start) {
  Start-WebSite -Name $IISSite
  }
else { "OK" }

"===== Check IIS AppPool ====="
if (-not (Get-WebApplication -Site $IISSite)) {
  New-WebAppPool $IISSite
  New-WebApplication -Name "TestApp" -Site $IISSite -PhysicalPath $WebAppDir -ApplicationPool $IISSite
  }
else { "OK" }

"===== HTTP Request ====="
if ("$slack" -eq "ok") {
  Write-Host "$statuscodedesc" "$httpcode" -foregroundColor "green" }

Stop-Transcript

Start-Sleep –Seconds 60 #infinity loop
}