#Get list of physical disks
$physDiskInstance_out = [string]((Get-Counter -List PhysicalDisk).PathsWithInstances | Where {$_ -notlike "*_Total*"} | Where {$_ -like "*Avg. disk sec/Read"} | Out-String)
$sqlServerInstances_out = [string](Get-Service | Where-Object {$_.status -eq "Running"} | Where-Object {$_.DisplayName -like "SQL Server (*)"} | Select Name | ft -HideTableHeaders | Out-String)
$diskCount = 0
$sqlInstCount = 0
$i = 0
$j = 1
$physDiskInstance = @() #create empty array
$sqlInstArray = @() #create empty array

$physDiskInstance_out = $physDiskInstance_out.split("`n")
$physDiskArrayCount = $physDiskInstance_out.count - 1

$sqlServerInstances_out = $sqlServerInstances_out.split("`n")
$sqlServerArrayCount = $sqlServerInstances_out.count - 1

#Create array of physical disk instances
While ($i -lt $physDiskArrayCount) {
    $pos = $physDiskInstance_out[$i].IndexOf(")") - 14
	$disk = $physDiskInstance_out[$i].Substring(14, $pos)
    if ($disk -notlike "*)\*") {
        $diskCount = $diskCount + 1
        $physDiskInstance += ,$disk
        $j = $j + 1
    }
    $i = $i + 1
}

#Create array of running SQL Server instances
$i = 0

While ($i -lt $sqlServerArrayCount) {
	$sqlInst = $sqlServerInstances_out[$i]
    $sqlInstCount = $sqlInstCount + 1
    $sqlInstArray += ,$sqlInst
    $i = $i + 1
}

#Get host hame
$hostName = [string](hostname)
$hostNameRegex = [string](hostname) + "*"

<#
#Get list of SQL Server instances
$sqlInstances = [string](sqlcmd -L)

$sqlInstances = $sqlInstances.split("     ")

ForEach ($instance in $sqlInstances) {
	$charCount = $instance | measure-object -character| Select Characters | ft -HideTableHeaders | Out-String 
	$charCount = [int]$charCount
	If ($charCount -ne 0 -And $instance -Like $hostNameRegex) {
		Write-Output $instance.Trim()
		If ($instance -Like ($hostName -contains "\")) {
			Write-Output $instance.Trim()
			Write-Output "Hello"
		}
	}
}
#>

#Create xml file
$textConfig1 = 
"<?xml version=""1.0"" encoding=""UTF-16""?>
<DataCollectorSet>
	<Status>0</Status>
	<Duration>604800</Duration>
	<Description>
	</Description>
	<DescriptionUnresolved>
	</DescriptionUnresolved>
	<DisplayName>
	</DisplayName>
	<DisplayNameUnresolved>
	</DisplayNameUnresolved>
	<SchedulesEnabled>-1</SchedulesEnabled>
	<LatestOutputLocation>C:\PerfLogs\Admin\INetU Data Collector Set\" + $hostName + "_20111212-000003</LatestOutputLocation>
	<Name>INetU Data Collector Set</Name>
	<OutputLocation>C:\PerfLogs\Admin\INetU Data Collector Set\" + $hostName + "_20111212-000004</OutputLocation>
	<RootPath>%systemdrive%\PerfLogs\Admin\INetU Data Collector Set</RootPath>
	<Segment>-1</Segment>
	<SegmentMaxDuration>86400</SegmentMaxDuration>
	<SegmentMaxSize>0</SegmentMaxSize>
	<SerialNumber>4</SerialNumber>
	<Server>
	</Server>
	<Subdirectory>
	</Subdirectory>
	<SubdirectoryFormat>3</SubdirectoryFormat>
	<SubdirectoryFormatPattern>yyyyMMdd\-NNNNNN</SubdirectoryFormatPattern>
	<Task>
	</Task>
	<TaskRunAsSelf>0</TaskRunAsSelf>
	<TaskArguments>
	</TaskArguments>
	<TaskUserTextArguments>
	</TaskUserTextArguments>
	<UserAccount>SYSTEM</UserAccount>
	<Security>O:BAG:S-1-5-21-2309043552-1614609250-4207311913-513D:AI(A;;FA;;;SY)(A;;FA;;;BA)(A;;FR;;;LU)(A;;0x1301ff;;;S-1-5-80-2661322625-712705077-2999183737-3043590567-590698655)(A;ID;FA;;;SY)(A;ID;FA;;;BA)(A;ID;0x1200ab;;;LU)(A;ID;FR;;;AU)(A;ID;FR;;;LS)(A;ID;FR;;;NS)</Security>
	<StopOnCompletion>0</StopOnCompletion>
	<PerformanceCounterDataCollector>
		<DataCollectorType>0</DataCollectorType>
		<Name>DataCollector01</Name>
		<FileName>DataCollector01</FileName>
		<FileNameFormat>0</FileNameFormat>
		<FileNameFormatPattern>
		</FileNameFormatPattern>
		<LogAppend>0</LogAppend>
		<LogCircular>0</LogCircular>
		<LogOverwrite>0</LogOverwrite>
		<LatestOutputLocation>C:\PerfLogs\Admin\INetU Data Collector Set\" + $hostName + "_20111212-000003\DataCollector01.blg</LatestOutputLocation>
		<DataSourceName>
		</DataSourceName>
		<SampleInterval>60</SampleInterval>
		<SegmentMaxRecords>0</SegmentMaxRecords>
		<LogFileFormat>3</LogFileFormat>`r`n"

$textCountersGeneral = 
	   "`t`t<Counter>\Memory\% Committed Bytes In Use</Counter>
		<Counter>\Memory\Available MBytes</Counter>
		<Counter>\Network Interface(*)\Bytes Total/sec</Counter>
		<Counter>\Network Interface(*)\Output Queue Length</Counter>
		<Counter>\Network Interface(*)\Packets Outbound Errors</Counter>
		<Counter>\Network Interface(*)\Packets Received Errors</Counter>
		<Counter>\Network Interface(*)\Packets/sec</Counter>
		<Counter>\Paging File(\??\C:\pagefile.sys)\% Usage</Counter>
		<Counter>\Processor(_Total)\% Privileged Time</Counter>
		<Counter>\Processor(_Total)\% Processor Time</Counter>
		<Counter>\System\Processor Queue Length</Counter>`r`n"

#Create the SQL Server counter templates line(s)
$i = 0 #reset iterator variable
$textCountersSqlInst = @()

While ($i -lt $sqlInstArray.count) {
    #$sqlInstArray[$i] = [string]$sqlInstArray[$i]
    If (([string]$sqlInstArray[$i].trim() -eq "MSSQLSERVER") -and ([string]$sqlInstArray[$i].length -gt 1)) {
        $textCountersSQL =
	   "`t`t<Counter>\SQLServer:Access Methods\Full Scans/sec</Counter>
	<Counter>\SQLServer:Access Methods\Index Searches/sec</Counter>
		<Counter>\SQLServer:Buffer Manager\Buffer cache hit ratio</Counter>
		<Counter>\SQLServer:Buffer Manager\Checkpoint pages/sec</Counter>
		<Counter>\SQLServer:Buffer Manager\Free list stalls/sec</Counter>
		<Counter>\SQLServer:Buffer Manager\Lazy writes/sec</Counter>
		<Counter>\SQLServer:Buffer Manager\Page life expectancy</Counter>
		<Counter>\SQLServer:Databases(_Total)\Log Growths</Counter>
		<Counter>\SQLServer:Databases(_Total)\Log Shrinks</Counter>
		<Counter>\SQLServer:Databases(_Total)\Transactions/sec</Counter>
		<Counter>\SQLServer:Databases(tempdb)\Transactions/sec</Counter>
		<Counter>\SQLServer:General Statistics\Processes blocked</Counter>
		<Counter>\SQLServer:General Statistics\User Connections</Counter>
		<Counter>\SQLServer:Latches\Average Latch Wait Time (ms)</Counter>
		<Counter>\SQLServer:Latches\Latch Waits/sec</Counter>
		<Counter>\SQLServer:Locks(_Total)\Average Wait Time (ms)</Counter>
		<Counter>\SQLServer:Locks(_Total)\Lock Waits/sec</Counter>
		<Counter>\SQLServer:Locks(_Total)\Number of Deadlocks/sec</Counter>
		<Counter>\SQLServer:Memory Manager\Target Server Memory (KB)</Counter>
		<Counter>\SQLServer:Memory Manager\Total Server Memory (KB)</Counter>
		<Counter>\SQLServer:SQL Statistics\Batch Requests/sec</Counter>`r`n"
    }
    ElseIf (([string]$sqlInstArray[$i].trim() -ne "MSSQLSERVER") -and ([string]$sqlInstArray[$i].length -gt 1)) {
        $textCountersSQL += ,
	       "`t`t<Counter>\" + [string]$sqlInstArray[$i].trim() + ":Access Methods\Full Scans/sec</Counter>
		    `t<Counter>\" + [string]$sqlInstArray[$i].trim() + ":Access Methods\Index Searches/sec</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":Buffer Manager\Buffer cache hit ratio</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":Buffer Manager\Checkpoint pages/sec</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":Buffer Manager\Free list stalls/sec</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":Buffer Manager\Lazy writes/sec</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":Buffer Manager\Page life expectancy</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":Databases(_Total)\Log Growths</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":Databases(_Total)\Log Shrinks</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":Databases(_Total)\Transactions/sec</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":Databases(tempdb)\Transactions/sec</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":General Statistics\Processes blocked</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":General Statistics\User Connections</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":Latches\Average Latch Wait Time (ms)</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":Latches\Latch Waits/sec</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":Locks(_Total)\Average Wait Time (ms)</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":Locks(_Total)\Lock Waits/sec</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":Locks(_Total)\Number of Deadlocks/sec</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":Memory Manager\Target Server Memory (KB)</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":Memory Manager\Total Server Memory (KB)</Counter>
		    <Counter>\" + [string]$sqlInstArray[$i].trim() + ":SQL Statistics\Batch Requests/sec</Counter>`r`n"
    }
    $i = $i + 1
}

#Convert SQL Server instance array object to string and remove extra white space
$textCountersSQL = [string]$textCountersSQL
$textCountersSQL = $textCountersSQL.replace("\ ", "\")
$textCountersSQL = $textCountersSQL.replace(" :", ":")

#Create the physical disk counter templates line(s)
$i = 0 #reset iterator variable
$textCountersPhysDisk = @()

While ($i -lt $physDiskInstance.count) {
    $textCountersPhysDisk += ,
	   "`t`t<Counter>\PhysicalDisk(" + $physDiskInstance[$i] + ")\Avg. Disk sec/Read</Counter>
		<Counter>\PhysicalDisk(" + $physDiskInstance[$i] + ")\Avg. Disk sec/Write</Counter>
		<Counter>\PhysicalDisk(" + $physDiskInstance[$i] + ")\Disk Read Bytes/sec</Counter>
		<Counter>\PhysicalDisk(" + $physDiskInstance[$i] + ")\Disk Reads/sec</Counter>
		<Counter>\PhysicalDisk(" + $physDiskInstance[$i] + ")\Disk Write Bytes/sec</Counter>
		<Counter>\PhysicalDisk(" + $physDiskInstance[$i] + ")\Disk Writes/sec</Counter>`r`n"
    $i = $i + 1
}

#Convert disk instance array object to string and remove space between parenthesis and disk instance
$textCountersPhysDisk = [string]$textCountersPhysDisk
$textCountersPhysDisk = $textCountersPhysDisk.replace("( ", "(")
$textCountersPhysDisk = $textCountersPhysDisk.replace(" )", ")")

$textCounterDisplayNameGeneral =
	   "`t`t<CounterDisplayName>\Memory\% Committed Bytes In Use</CounterDisplayName>
		<CounterDisplayName>\Memory\Available MBytes</CounterDisplayName>
		<CounterDisplayName>\Network Interface(*)\Bytes Total/sec</CounterDisplayName>
		<CounterDisplayName>\Network Interface(*)\Output Queue Length</CounterDisplayName>
		<CounterDisplayName>\Network Interface(*)\Packets Outbound Errors</CounterDisplayName>
		<CounterDisplayName>\Network Interface(*)\Packets Received Errors</CounterDisplayName>
		<CounterDisplayName>\Network Interface(*)\Packets/sec</CounterDisplayName>
		<CounterDisplayName>\Paging File(\??\C:\pagefile.sys)\% Usage</CounterDisplayName>
		<CounterDisplayName>\Processor(_Total)\% Privileged Time</CounterDisplayName>
		<CounterDisplayName>\Processor(_Total)\% Processor Time</CounterDisplayName>
		<CounterDisplayName>\System\Processor Queue Length</CounterDisplayName>`r`n"

$textCounterDisplayNameSQL =
	   "`t`t<CounterDisplayName>\SQLServer:Access Methods\Full Scans/sec</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Access Methods\Index Searches/sec</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Buffer Manager\Buffer cache hit ratio</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Buffer Manager\Checkpoint pages/sec</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Buffer Manager\Free list stalls/sec</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Buffer Manager\Lazy writes/sec</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Buffer Manager\Page life expectancy</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Databases(_Total)\Log Growths</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Databases(_Total)\Log Shrinks</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Databases(_Total)\Transactions/sec</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Databases(tempdb)\Transactions/sec</CounterDisplayName>
		<CounterDisplayName>\SQLServer:General Statistics\Processes blocked</CounterDisplayName>
		<CounterDisplayName>\SQLServer:General Statistics\User Connections</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Latches\Average Latch Wait Time (ms)</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Latches\Latch Waits/sec</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Locks(_Total)\Average Wait Time (ms)</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Locks(_Total)\Lock Waits/sec</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Locks(_Total)\Number of Deadlocks/sec</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Memory Manager\Target Server Memory (KB)</CounterDisplayName>
		<CounterDisplayName>\SQLServer:Memory Manager\Total Server Memory (KB)</CounterDisplayName>
		<CounterDisplayName>\SQLServer:SQL Statistics\Batch Requests/sec</CounterDisplayName>`r`n" 

#Create the physical disk counter display name templates line(s)
$i = 0 #reset iterator variable
$textCounterDisplayNamePhysDisk = @()

While ($i -lt $physDiskInstance.count) {
    $textCounterDisplayNamePhysDisk += ,
	   "`t`t<CounterDisplayName>\PhysicalDisk(" + $physDiskInstance[$i] + ")\Avg. Disk sec/Read</CounterDisplayName>
		<CounterDisplayName>\PhysicalDisk(" + $physDiskInstance[$i] + ")\Avg. Disk sec/Write</CounterDisplayName>
		<CounterDisplayName>\PhysicalDisk(" + $physDiskInstance[$i] + ")\Disk Read Bytes/sec</CounterDisplayName>
		<CounterDisplayName>\PhysicalDisk(" + $physDiskInstance[$i] + ")\Disk Reads/sec</CounterDisplayName>
		<CounterDisplayName>\PhysicalDisk(" + $physDiskInstance[$i] + ")\Disk Write Bytes/sec</CounterDisplayName>
		<CounterDisplayName>\PhysicalDisk(" + $physDiskInstance[$i] + ")\Disk Writes/sec</CounterDisplayName>`r`n"
    $i = $i + 1
}

#Convert disk instance array object to string and remove space between parenthesis and disk instance
$textCounterDisplayNamePhysDisk = [string]$textCounterDisplayNamePhysDisk
$textCounterDisplayNamePhysDisk = $textCounterDisplayNamePhysDisk.replace("( ", "(")
$textCounterDisplayNamePhysDisk = $textCounterDisplayNamePhysDisk.replace(" )", ")")

$textConfig2 =
   "`t`t</PerformanceCounterDataCollector>
	<Schedule>
		<StartDate>12/12/2015</StartDate>
		<EndDate>
		</EndDate>
		<StartTime>
		</StartTime>
		<Days>127</Days>
	</Schedule>
	<DataManager>
		<Enabled>0</Enabled>
		<CheckBeforeRunning>0</CheckBeforeRunning>
		<MinFreeDisk>0</MinFreeDisk>
		<MaxSize>0</MaxSize>
		<MaxFolderCount>0</MaxFolderCount>
		<ResourcePolicy>0</ResourcePolicy>
		<ReportFileName>report.html</ReportFileName>
		<RuleTargetFileName>report.xml</RuleTargetFileName>
		<EventsFileName>
		</EventsFileName>
	</DataManager>
</DataCollectorSet>"

$text = $textConfig1 + $textCountersGeneral + $textCountersSQL + $textCountersPhysDisk + $textCounterDisplayNameGeneral + $textCounterDisplayNameSQL + $textCounterDisplayNamePhysDisk + $textConfig2

#Write-Output $text

#Remove special characters from metric name for use in file name
$CleanOutput = $Output1 -replace "/", " "

$FileName = "C:\perfmon_template_" + $CleanOutput + ".xml"
out-file -FilePath $FileName -InputObject $text
